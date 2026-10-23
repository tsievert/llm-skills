# Deposit checklist (copy into the project and tick off)

Paper: [title] | Journals in order: [1st, 2nd] | Deposit due: [submission / acceptance] | Repository: [name] | Date: [YYYY-MM-DD]

## Decide
- [ ] Journal policy read live (page and date noted): [ ]
- [ ] Repository chosen, limits and fees read live: [ ]
- [ ] Data, code or both; who pays (user decides)
- [ ] Personal data and sensitive locations checked; decision recorded
- [ ] Third-party data: permission or access route
- [ ] Licences chosen: data [ ], code [ ]

## Assemble
- [ ] Originals located (server path noted in README), read-only
- [ ] `stage_deposit(from, to)` run, manifest written
- [ ] `check_deposit(to, repo = "...")`: no errors, warnings read and decided
- [ ] Environment files present (lockfile, session info)
- [ ] Clean-clone test run, headline results match the paper (date, OS, versions noted)
- [ ] README written (`data-repository-readme`) and `check_readme()` clean
- [ ] `CITATION.cff` and tag if code is archived from GitHub (`git-for-research-projects`)

## Publish (the user does this)
- [ ] Draft or sandbox upload checked
- [ ] Data availability statement drafted and approved
- [ ] User presses publish; DOI recorded
- [ ] DOI added to the paper, README, CITATION.cff, related-publication field
- [ ] Manifest hash of the uploaded files matches the server copy (`verify_manifest()` from `git-for-research-projects`)
