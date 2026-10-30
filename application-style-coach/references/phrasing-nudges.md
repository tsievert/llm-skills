# Phrasing and framing nudges

Each nudge is a question or observation raised in chat. The user decides and rewrites. Illustrative rewrites are
allowed only in chat, one sentence at a time, labelled as examples, built from facts the user already gave, with
placeholders such as [number] or [your role] where a fact is missing. Never insert them into a file.

## Contents

- How to give a nudge
- Guard: no LLM-style wording in suggestions
- Claims and evidence
- Register: inflation and understatement
- Structure and reader
- Research statement and portfolios
- Mechanical polish
- Basis and limits of the advice

## How to give a nudge

1. Quote the short fragment (under about 15 words) and say where it is.
2. Name the pattern in plain words and why a reviewer may react to it.
3. Ask a question the user can answer from their own facts.
4. Optionally add one example sentence, labelled "Example (your facts may differ)".
5. Say when a choice is theirs (metrics, breaks, what to cut).

Keep a pass to about five to seven nudges, ordered: (a) things the call requires (limits, missing items),
(b) verifiability and integrity, (c) clarity and framing, (d) polish. Offer more on request.

Template:

> Paragraph 2, "I have extensive experience in X": this is an adjective without a fact next to it. How many
> projects, years or outputs would you point to? Example (your facts may differ): "Since [year] I have [role] in
> [number] projects on X, [one concrete output]."

## Guard: no LLM-style wording in suggestions

The assistant's own suggestions and examples must not sound like language-model output. Generic, polished boilerplate
reads as filler to a panel, and some calls say AI-generated applications do not meet expectations or ask applicants to
state how AI was used (see [local-language-sources.md](local-language-sources.md)). The application must be in the
user's own voice.

Do not offer, in examples or as advice to add:

- Stock words and phrases: delve, leverage, tapestry, testament to, realm, landscape, spearhead, foster, underscore,
  pivotal, vibrant, showcase, multifaceted, "in today's ...", "passionate", "dynamic", "cutting-edge".
- "Not only X but also Y" constructions; a triplet in every sentence; neat symmetrical sentence pairs.
- Stacked transition adverbs at sentence starts (Moreover, Furthermore, Additionally, In conclusion) and phrases such
  as "it is important to note".
- Em dashes used for rhythm (use a comma, a full stop or brackets, as the user already does).
- Bold lead-in bullets, headings the user did not use, or a summary sentence that restates the paragraph.
- Formulaic openers and closers ("I am excited to...", "I look forward to the opportunity to...").
- Flattering or intensifying adjectives that carry no fact.

Do instead:

1. **Build from the user's words.** Reuse their nouns, verbs and level of formality; match their sentence length. Sound
   like them on a good day, not like a template.
2. **Plain and concrete.** Short common verbs ("led", "ran", "wrote", "tested"), one fact per sentence, numbers or names
   where the user supplied them, placeholders where they did not.
3. **Prefer a question to an example** when a sentence cannot be made from the user's own material.
4. **Vary naturally.** Do not offer two alternatives of identical shape; at most two examples and keep them short.
5. **Check your own example** against the lists above before sending it. If you notice a pattern in your wording, rewrite
   the example.

When the user's own text contains such patterns, describe them as generic or boilerplate ("this phrase could sit in any
application") and ask what they actually mean. Never say or imply that the text "sounds like AI" or that it was written
by a model: that cannot be known, and the flags only show common phrases. Do not suggest ways to avoid detection;
the aim is clear, specific and honest writing.

## Claims and evidence

| Nudge | Ask | Example direction |
|---|---|---|
| Adjective without fact ("strong", "extensive", "significant") | Which observable fact (number, role, output, date) sits behind it? | "I led [number] [things] between [year] and [year]." |
| Own role versus team ("we", "the project", passive) | What did you personally do or decide? | "I designed the [analysis] and wrote [part]." |
| Status words | Are published, accepted, submitted, in preparation used consistently and only where true? | "Submitted to [journal type] in [month year]." (No unaccepted manuscripts in Ministry-classified lists.) |
| Verifiability (TENK) | Could a reviewer check this from a public record or a referee? | Remove or soften what you cannot document; the user decides. |
| Comparison without basis ("one of the leading", "best") | Compared with what, according to whom? | State the observable instead of the ranking. |
| Metrics | Does the call allow them? | Call wins; if silent it is the user's choice. |

Never make a claim stronger than the user stated it. If a sentence overreaches the facts the user gave, say so.

## Register: inflation and understatement

Inflated: "groundbreaking", "unique", "passionate", "world-leading", stacked intensifiers.
Understated: "helped with", "was involved in", "just", "only", "a small contribution", "tried to".
Both hide the facts. Some research on how people describe their own work found women describing their ability less
favourably than equally performing men, and evidence on positive framing in research writing is mixed and
observational; so do not tell the user which direction to move. Show both patterns where they occur and ask what
the facts support.

| Pattern | Ask | Example direction |
|---|---|---|
| Hedge on an achievement ("I helped with the analysis") | What exactly did you do? | "I performed the [analysis] and interpreted [result]." |
| Hedge on a plan ("I hope to explore") | Is the plan uncertain or decided? | "I will test [question] using [approach]." Keep hedges where uncertainty is real. |
| Superlative | What fact would a sceptical specialist accept? | Replace with the fact, or remove. |
| False modesty ("my modest contribution") vs grandiosity ("fundamentally transforms the field") | Does the sentence say what was demonstrated? | "We showed that [finding]." |

## Structure and reader

| Nudge | Ask |
|---|---|
| Generic opener ("I am writing to apply...") | What is the one thing you want the reader to remember? Start there. |
| Paragraph without a point | What is this paragraph's one job? Put that first. |
| Letter repeats the CV | What does the reader learn here that the CV cannot tell them? |
| Pasteable sentence | Which sentence would survive in another application unchanged? What is specific to this group, call or criteria? (The user supplies the specifics.) |
| Reader from another subfield | Would a panel member from a neighbouring field follow this? Define acronyms once; gloss one jargon term. |
| Repeated sentence openers ("I ... I ... I ...") | Vary the structure, or lead with the object of the sentence. |
| Passive hiding agency | Who did it? |
| Length | Does the text fit the call's limit with room, and does each sentence earn its place? |

## Research statement and portfolios

| Nudge | Ask |
|---|---|
| Future is vague | What is the question or aim in one sentence, and the first step? |
| Past dominates | Is the balance a deliberate choice for this call (statement versus plan)? |
| Independence | Which parts are yours alone? Would the text read the same in your supervisor's grant? |
| Activity versus contribution | After "we studied X": what did this establish? |
| Method before finding | Lead with the question or finding, then the method. |
| Too many projects | Which two or three lines are the programme, and in what order? |
| Teaching portfolio philosophy only | What happened in a class or course, what did you change afterwards? |

## Mechanical polish

Consistent tense and dates, one reference style, names and titles identical across documents, acronyms defined,
no unusual characters. For spelling and grammar checking of a manuscript-style file point to
`manuscript-writing-quarto`; here only note obvious slips in chat.

## Basis and limits of the advice

- The main sources are university career-office and funder guidance (Finnish and international), TENK's template
  and Finnish calls. Several agree on specificity, own role, fit, and writing for non-specialists.
- There is little direct research showing that particular phrasings change hiring outcomes, so say "reviewers often
  react to..." and "guidance suggests...", not that a phrasing "works".
- Evidence on gendered self-description is observational and describes groups, not the individual; use it only to
  explain why both understatement and inflation are worth a look.
- Finnish academic convention (dislike of showiness) comes from secondary career sources.
- The user knows the field, the committee and the facts better than the assistant. Offer the question; accept a
  decision to keep the original wording.
