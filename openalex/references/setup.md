# Setup

## MCP server (mcp.openalex.org)

Configured in global `~/.posit/assistant/settings.json` under `mcpServers`.
It authenticates separately from the R workflow below — the first time a
tool from it is used, the Session/MCP panel will show "Sign in required";
the user needs to click **Sign in** there to complete OAuth with their
OpenAlex account. Don't try to work around this with the R/httr2 path just
because the MCP server hasn't been signed into yet — ask the user to sign in.

No further setup is needed once signed in; the server manages its own key.

## R workflow (openalexR + httr2) — API key

1. Get a free OpenAlex API key: create an account at https://openalex.org,
   go to Settings -> API key, and copy it (or let Posit Assistant request one
   for you via `POST https://api.openalex.org/api-keys` with your email,
   then verify the email).
2. Add the key to the personal `~/.Renviron` file (create it if it doesn't
   exist) as a single line:
   ```
   OPENALEX_API_KEY=your-key-here
   ```
   On Windows, R's `~` usually resolves to `Documents` (e.g.
   `C:/Users/<you>/Documents`), which is **not** the same as the shell's
   `$HOME` (`C:/Users/<you>`). Run `path.expand("~")` in R to confirm where
   it actually looks before creating the file.
3. Restart the R session (or run `readRenviron("~/.Renviron")`) so the
   variable is loaded.
4. Do **not** put the key in any file inside a project folder (e.g. a
   project-level `.Renviron`, a script, or a memory/skill file committed to
   a repo), since those can be committed and pushed to a shared repository.
   If a project needs its own `.Renviron`, make sure it is listed in that
   project's `.gitignore`.

### Key aliasing for openalexR

`OPENALEX_API_KEY` (in `~/.Renviron`) is the single source of truth for the
key. `~/.Rprofile` aliases it to `openalexR.apikey` automatically at every R
startup:

```r
if (nzchar(Sys.getenv("OPENALEX_API_KEY"))) {
  Sys.setenv(openalexR.apikey = Sys.getenv("OPENALEX_API_KEY"))
}
```

This means `openalexR`'s `oa_apikey()` (which reads
`Sys.getenv("openalexR.apikey")` / `getOption("openalexR.apikey")`) picks the
key up natively with no per-session bridging call, while `httr2`-based code
keeps reading `OPENALEX_API_KEY` directly. Don't duplicate the literal key
value in `~/.Renviron` under both names — alias via `~/.Rprofile` instead, so
the secret exists in exactly one place on disk.

Send the key either as `api_key=<key>` in the query string or as an
`Authorization: Bearer <key>` header when calling the REST API directly.
