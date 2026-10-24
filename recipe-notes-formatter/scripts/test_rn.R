# test_rn.R -- tests for the recipe-notes-formatter scripts. Offline by default.
# Run from the repo root:  testthat::test_file("recipe-notes-formatter/scripts/test_rn.R")
# Live page tests (one request per page) only run with Sys.setenv(RN_LIVE = "1").
# Test files go to tmp-examples/ (git-ignored) and are removed afterwards.

library(testthat)
# test_file() changes the working directory to this file's folder, so find the scripts either way.
scripts_dir <- if (file.exists("rn_units.R")) "." else "recipe-notes-formatter/scripts"
for (f in c("rn_units", "rn_core", "rn_profile", "rn_web")) {
  source(file.path(scripts_dir, paste0(f, ".R")), encoding = "UTF-8")
}
tmp <- file.path("tmp-examples", paste0("rn-test-", Sys.getpid()))
dir.create(tmp, recursive = TRUE)
withr::defer({
  unlink(tmp, recursive = TRUE)
  # Remove the parent only if this test created it; never touch other content in tmp-examples/.
  if (dir.exists("tmp-examples") && length(list.files("tmp-examples", all.files = TRUE, no.. = TRUE)) == 0) {
    unlink("tmp-examples", recursive = TRUE)
  }
}, teardown_env())

conv <- function(x, ...) rn_convert_all(x, ...)$text

test_that("non-metric units convert, metric and local units stay", {
  expect_equal(conv("1/2 cup sugar"), "120 ml sugar")
  expect_equal(conv("1\u00bd cups water"), "350 ml water")
  expect_equal(conv("1 1/2 cups milk"), "350 ml milk")
  expect_equal(conv("1 cup (240 ml) milk"), "240 ml milk")
  expect_equal(conv("10 oz (280 g) pasta"), "280 g pasta")
  expect_equal(conv("1 lb ground beef"), "450 g ground beef")
  expect_equal(conv("2 sticks butter"), "225 g butter")
  expect_equal(conv("1 stick of something"), "1 stick of something")
  expect_equal(conv("8 cups water"), "1.89 l water")
  expect_equal(conv("8 cups water", decimal = ","), "1,89 l water")
  expect_equal(conv("1-2 cups stock"), "235-470 ml stock")
  for (keep in c("500 g Mehl", "1,5 dl punaisia linssej\u00e4", "2 msk sm\u00f6r", "5 tsk malen kanel",
                 "1\u00bd tl suolaa", "150g sm\u00f6r", "1 EL \u00d6l", "2 rkl voita", "1 krm salt", "Prise Salz")) {
    expect_equal(conv(keep), keep)
  }
})

test_that("spoons stay unless asked, ambiguous units are flagged not converted", {
  expect_equal(conv("4 tablespoons olive oil"), "4 tablespoons olive oil")
  expect_equal(conv("1 tsp salt"), "1 tsp salt")
  expect_equal(conv("3 tbsp honey", spoons = "ml"), "45 ml honey")
  expect_equal(conv("1/2 tablespoon honey", spoons = "ml", decimal = ","), "7,5 ml honey")
  r <- rn_convert_all("2 Tassen Wasser")
  expect_equal(r$text, "2 Tassen Wasser")
  expect_match(r$flags, "Tasse")
  expect_match(rn_convert_all("8 oz cream cheese")$flags, "oz read as weight")
})

test_that("temperatures and lengths convert, bare degrees do not", {
  expect_equal(conv("Bake at 350\u00b0F for 20 minutes"), "Bake at 175 \u00b0C for 20 minutes")
  expect_equal(conv("Heat the oven to 375 degrees F."), "Heat the oven to 190 \u00b0C.")
  expect_equal(conv("bake at 350-375 \u00b0F"), "bake at 175\u2013190 \u00b0C")
  expect_equal(conv("Preheat to 200 degrees"), "Preheat to 200 degrees")
  expect_equal(conv("Use a 9-inch pan and a 9x13 inches dish"), "Use a 23 cm pan and a 23x33 cm dish")
})

test_that("quantity parser handles the written forms", {
  expect_equal(rn_parse_num("1 1/2"), 1.5)
  expect_equal(rn_parse_num("1\u00bd"), 1.5)
  expect_equal(rn_parse_num("\u00be"), 0.75)
  expect_equal(rn_parse_num("1,5"), 1.5)
  expect_equal(rn_parse_num("2"), 2)
})

test_that("safe file names and no-overwrite writing with backup", {
  expect_equal(rn_safe_filename("Soup / Eintopf: the best?"), "Soup or Eintopf - the best")
  expect_equal(rn_safe_filename("Mousse au Chocolat (\u00e0 la Papa)"), "Mousse au Chocolat (\u00e0 la Papa)")
  expect_equal(rn_safe_filename("Allg\u00e4uer K\u00e4sesp\u00e4tzle"), "Allg\u00e4uer K\u00e4sesp\u00e4tzle")
  out <- file.path(tmp, "out"); bk <- file.path(tmp, "backup")
  p1 <- rn_write_text("one\n", out, "A.md", bk)
  p2 <- rn_write_text("two\n", out, "A.md", bk)                 # default: numbered name, no overwrite
  expect_equal(basename(p2), "A (2).md")
  expect_equal(readLines(p1), "one")
  p3 <- rn_write_text("three\n", out, "A.md", bk, overwrite = TRUE)
  expect_equal(readLines(p3), "three")
  saved <- list.files(bk, recursive = TRUE, full.names = TRUE)
  expect_length(saved, 1)
  expect_equal(readLines(saved), "one")                         # the replaced version can be restored
  expect_error(rn_backup(file.path(tmp, "missing.md"), bk), "Nothing to back up")
})

test_that("project folder check asks first and creates only with permission", {
  root <- file.path(tmp, "proj"); dir.create(root)
  chk <- rn_project_check(root)
  expect_false(any(chk$exists))
  expect_error(rn_project_create(root), "permission")
  made <- rn_project_create(root, confirmed = TRUE)
  expect_true(dir.exists(file.path(root, "output", "images")))
  expect_false(file.exists(file.path(root, "recipe-profile.yml")))
  expect_length(rn_project_create(root, confirmed = TRUE), 0)
})

rec <- list(
  title = "Saftigaste Kanelbullarna", source = "https://example.org/kanelbullar", lang = "sv",
  tags = c("recipe/baking", "recipe/dessert"), aliases = c("Zimtschnecken", "kanelbullar"),
  servings = 25, time = 180, image_file = "kanelbullar.jpg",
  image_credit = "https://example.org/kanelbullar (image https://example.org/i.jpg)",
  ingredients = list(list(name = "Kanelfyllning", items = c("150 g sm\u00f6r", "1 dl farinsocker")),
                     list(name = "Vetedeg", items = c("50 g j\u00e4st", "1 kg vetemj\u00f6l"))),
  directions = list(list(name = "Kanelfyllning", steps = c("1. Blanda allt.", "Sm\u00f6r p\u00e5 degen.")),
                    list(name = "Vetedeg", steps = c("Kn\u00e5da i 10 minuter."))))
profile <- list(author = "Thorbj\u00f6rn Sievert", index_link = "[[000 Cookbook index|Cookbook index]]",
                checkbox_default = "ticked", tag_vocabulary = c("recipe", "recipe/baking", "recipe/dessert"))

test_that("rendered note passes its own check; broken notes are caught", {
  txt <- rn_render_note(rec, profile)
  expect_match(txt, "^---\naliases:\n", perl = TRUE)
  expect_match(txt, "- \\[x\\] 150 g sm\u00f6r")                 # ticked = not on the shopping list
  expect_match(txt, "#ingredients\n- \\[x\\]")
  expect_match(txt, "1\\. Blanda allt\\.")                       # leading numbering stripped, not doubled
  expect_false(grepl("1\\. 1\\.", txt))
  expect_false(grepl("Created_at|Modified_at|FINISH|## Intro", txt))
  dir.create(file.path(tmp, "check", "images"), recursive = TRUE)
  file.create(file.path(tmp, "check", "images", "kanelbullar.jpg"))
  p <- rn_write_text(txt, file.path(tmp, "check"), "Kanelbullar.md", file.path(tmp, "bk"))
  res <- rn_check_note(p, profile)
  expect_false(any(res$level == "error"), info = paste(res$message, collapse = "; "))
  unlink(file.path(tmp, "check", "images", "kanelbullar.jpg"))
  expect_true(any(rn_check_note(p, profile)$check == "image"))   # missing picture file is an error
  bad <- sub("- \\[x\\] 150 g sm\u00f6r", "- 2 cups flour", txt)
  bad <- sub("tags:\n  - recipe\n", "tags:\n  - \"{ tag2 }\":\n", bad)
  p2 <- rn_write_text(bad, file.path(tmp, "check"), "Bad.md", file.path(tmp, "bk"))
  r2 <- rn_check_note(p2, profile)
  expect_true(any(r2$check == "ingredients" & r2$level == "error"))
  expect_true(any(r2$check == "placeholders"))
})

test_that("tags: placeholders are separated, vocabulary is enforced", {
  p <- rn_write_text("---\ntags:\n  - recipe\n  - \"{ tag2 }\":\n  - recipe/soup\naliases:\n  - \"{ alias1 }\":\n---\n# X\n",
                     file.path(tmp, "tg"), "X.md", file.path(tmp, "bk"))
  n <- rn_read_note(p)
  expect_equal(n$tags, c("recipe", "recipe/soup"))
  expect_equal(n$tag_placeholders, "{ tag2 }")
  expect_true(rn_tag_ok("recipe/soup")); expect_false(rn_tag_ok("2024")); expect_false(rn_tag_ok("two words"))
  ck <- rn_check_tags(c("recipe/soup", "recipe/lunch", "2024"), list(tag_vocabulary = "recipe/soup",
        decisions = list(tag_map = list(`recipe/vegepossible` = "recipe/vegetarianpossible"), approved_new_tags = character())))
  expect_equal(ck$status, c("known", "new", "invalid"))
})

test_that("profile learning: counts roll up, drift against a base file is reported", {
  d <- file.path(tmp, "notes"); dir.create(d)
  mk <- function(name, tags, box = "x") writeLines(c("---", "tags:", paste0("  - ", tags), "author: Me", "---",
        paste0("# ", name), "[[000 Cookbook index|Cookbook index]]", "## Ingredients", "#ingredients",
        paste0("- [", box, "] 1 egg"), "---", "## Directions", "Mix the eggs and bake them in the oven until done."),
        file.path(d, paste0(name, ".md")))
  mk("A", c("recipe", "recipe/vegetarian/vegan")); mk("B", c("recipe", "recipe/vegetarianpossible")); mk("C", c("recipe", "recipe/soup"))
  writeLines(c("# not a recipe", "text"), file.path(d, "Index.md"))
  writeLines(c("filters:", "  and:", "    - file.tags.contains(\"recipe\")", "views:", "  - type: cards", "    name: Vegan",
               "    filters:", "      and:", "        - file.tags.contains(\"recipe/vegan\")", "  - type: cards", "    name: Easy",
               "    filters:", "      and:", "        - file.tags.contains(\"recipe/vegepossible\")"), file.path(d, "x.base"))
  pf <- rn_learn_profile(d, base = file.path(d, "x.base"))
  expect_equal(pf$learned_from$n_notes, 3)
  expect_equal(pf$learned_from$skipped_non_recipe_files[[1]], "Index.md")
  expect_equal(pf$tag_counts_rollup[["recipe/vegetarian"]], 1L)
  expect_equal(pf$author, "Me"); expect_equal(pf$checkbox_default, "ticked")
  un <- vapply(pf$review$base_tags_unused_in_notes, `[[`, "", "base_tag")
  expect_setequal(un, c("recipe/vegan", "recipe/vegepossible"))
  nearest <- setNames(vapply(pf$review$base_tags_unused_in_notes, `[[`, "", "nearest_used_tag"), un)
  expect_equal(nearest[["recipe/vegan"]], "recipe/vegetarian/vegan")
  expect_equal(nearest[["recipe/vegepossible"]], "recipe/vegetarianpossible")
  expect_error(rn_profile_write(pf, file.path(tmp, "p.yml")), "ask first")
  path <- rn_profile_write(pf, file.path(tmp, "p.yml"), file.path(tmp, "bk"), confirmed = TRUE)
  back <- rn_profile_read(path)
  expect_equal(back$author, "Me")
  pf2 <- rn_learn_profile(d, previous = modifyList(back, list(decisions = list(tag_map = list(a = "b"), approved_new_tags = "recipe/x"))))
  expect_equal(pf2$decisions$tag_map$a, "b")                      # decisions survive a relearn
})

html_graph <- '<html lang="de"><head>
<meta property="og:image" content="/img/og.jpg">
<script type="application/ld+json">{"@context":"https://schema.org","@graph":[
 {"@type":"WebSite","name":"Site"},
 {"@type":["Recipe"],"name":"Spaetzle &amp; K\u00e4se","image":[{"@type":"ImageObject","url":"https://x.test/a.jpg"},"https://x.test/b.jpg"],
  "recipeYield":["4","4 Portionen"],"totalTime":"PT1H15M","author":{"@type":"Person","name":"Anna"},
  "recipeIngredient":["Teig","500 g Mehl","4 Eier","Belag","250 g K\u00e4se"],
  "recipeInstructions":[{"@type":"HowToSection","name":"Teig","itemListElement":[{"@type":"HowToStep","text":"Mehl und Eier\nverr\u00fchren."}]},
                        {"@type":"HowToSection","name":"Belag","itemListElement":[{"@type":"HowToStep","text":"K\u00e4se reiben."}]}]}]}</script>
</head><body><p>x</p></body></html>'

test_that("JSON-LD: @graph, nested objects, raw newline repair, groups, durations, images", {
  r <- rn_extract_recipe(html_graph, "https://x.test/rezept")
  expect_equal(r$tier, "jsonld")
  expect_equal(r$title, "Spaetzle & K\u00e4se")
  expect_equal(r$servings, 4); expect_equal(r$time, 75); expect_equal(r$author, "Anna"); expect_equal(r$lang, "de")
  expect_equal(r$heading_candidates, c(1L, 4L))                  # "Teig" and "Belag" precede quantities
  expect_length(r$directions, 2); expect_equal(r$directions[[1]]$name, "Teig")
  expect_equal(r$image_candidates$url, c("https://x.test/a.jpg", "https://x.test/b.jpg", "https://x.test/img/og.jpg"))
  expect_equal(r$image_candidates$source, c("jsonld", "jsonld", "og:image"))
  expect_equal(rn_iso_minutes("PT90M"), 90); expect_equal(rn_iso_minutes("P0DT45M"), 45); expect_true(is.na(rn_iso_minutes("soon")))
  raw_nl <- paste0('<script type="application/ld+json">{"@type":"Recipe","name":"N","recipeIngredient":["1 egg"],',
                   '"recipeInstructions":[{"@type":"HowToStep","text":"line one\nline two"}]}</script>')
  expect_equal(rn_extract_recipe(paste0("<html><body>", raw_nl, "</body></html>"))$tier, "jsonld")
})

test_that("no markup: tier none with page text and og:image; microdata fallback works", {
  page <- '<html lang="fi"><head><meta property="og:image" content="/kuva.jpg"><meta property="og:title" content="Helppo linssikeitto">
           <script type="application/ld+json">{"@type":"WebSite"}</script></head><body><nav>menu</nav><article><h1>Keitto</h1>
           <p>1 sipuli</p><p>Silppua sipuli.</p></article><footer>f</footer></body></html>'
  r <- rn_extract_recipe(page, "https://b.test/keitto")
  expect_equal(r$tier, "none"); expect_match(r$page_text, "Silppua sipuli"); expect_false(grepl("menu", r$page_text))
  expect_equal(r$image_candidates$url, "https://b.test/kuva.jpg")
  micro <- '<html><body><div itemscope itemtype="https://schema.org/Recipe"><span itemprop="name">Soup</span>
            <li itemprop="recipeIngredient">2 carrots</li><li itemprop="recipeIngredient">1 onion</li>
            <ol itemprop="recipeInstructions"><li>Chop.</li><li>Cook.</li></ol></div></body></html>'
  m <- rn_extract_recipe(micro)
  expect_equal(m$tier, "microdata"); expect_equal(m$ingredients, c("2 carrots", "1 onion")); expect_equal(m$directions[[1]]$steps, c("Chop.", "Cook."))
})

test_that("confirmed headings become ingredient groups and split flat directions", {
  x <- list(ingredients = c("Teig", "500 g Mehl", "4 Eier", "Belag", "250 g K\u00e4se"), heading_candidates = c(1L, 4L),
            directions = list(list(name = NULL, steps = c("Teig", "Mehl und Eier verr\u00fchren.", "Belag", "K\u00e4se reiben."))))
  g <- rn_apply_headings(x)
  expect_equal(vapply(g$ingredient_groups, function(z) z$name, ""), c("Teig", "Belag"))
  expect_equal(g$ingredient_groups[[1]]$items, c("500 g Mehl", "4 Eier"))
  expect_equal(vapply(g$direction_groups, function(z) z$name, ""), c("Teig", "Belag"))
  expect_equal(g$direction_groups[[2]]$steps, "K\u00e4se reiben.")
  only_belag <- rn_apply_headings(x, idx = 4L)                   # user rejected "Teig" as a heading
  expect_null(only_belag$ingredient_groups[[1]]$name)
  expect_equal(only_belag$ingredient_groups[[1]]$items, c("Teig", "500 g Mehl", "4 Eier"))
  none <- rn_apply_headings(x, idx = integer())
  expect_length(none$ingredient_groups, 1)
})

test_that("ingredient overlap accepts the same recipe and rejects a different one", {
  note <- c("1 sipuli", "2 valkosipulinkynttä", "1/4 tl jauhettua korianteria", "1,5 dl punaisia linssejä", "2 dl kookosmaitoa")
  same <- c("1 iso sipuli", "2 kynttä valkosipulinkynttä", "1 rkl currytahnaa", "1,5 dl punaisia linssejä", "2 dl kookosmaitoa", "jauhettua korianteria")
  other <- c("500 g jauhoja", "4 munaa", "250 g juustoa")
  expect_gte(rn_ingredient_overlap(note, same), 0.6)
  expect_lt(rn_ingredient_overlap(note, other), 0.2)
  expect_equal(rn_ingredient_overlap(character(), same), 0)
})

test_that("live: a real page with Recipe JSON-LD (opt-in)", {
  skip_if_not(identical(Sys.getenv("RN_LIVE"), "1"), "set RN_LIVE=1 to run live tests")
  pg <- rn_fetch_html("https://www.koket.se/saftigaste-kanelbullarna")
  expect_equal(pg$status, 200)
  r <- rn_extract_recipe(pg$html, pg$url)
  expect_equal(r$tier, "jsonld"); expect_equal(r$lang, "sv"); expect_true(length(r$ingredients) > 10)
  expect_gt(nrow(r$image_candidates), 0)
})
