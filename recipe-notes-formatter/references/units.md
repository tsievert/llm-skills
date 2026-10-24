# Units

What `scripts/rn_units.R` does and why. The code is tested (`scripts/test_rn.R`); the tables come from web sources
checked on 2026-10-24 and are listed with their weaknesses.

## Contents

- Policy
- Local metric units (never touched)
- Converted units
- Ambiguous or undefined
- Rounding
- Volume to weight (not done by the script)
- Sources and limits

## Policy

1. Only non-metric units are converted. A recipe already in `dl`, `msk`, `EL`, `rkl` is metric by definition and is
   left exactly as written (the user already treats these as acceptable).
2. English `tbsp`/`tsp` stay as written (user default); `spoons = "ml"` converts them to 15 and 5 ml.
3. The original value is not kept in the note. The report lists every change (from, to) so it can be reversed.
4. Never invent: no factor, no conversion. Ambiguity is flagged.
5. Directions are converted too (quantities, oven temperatures, pan sizes), because a note that mixes units is
   harder to cook from.

## Local metric units (never touched)

| Language | Units and values |
|---|---|
| Swedish | `krm` 1 ml, `tsk` 5 ml, `msk` 15 ml, `dl` 100 ml, `cl` 10 ml, `dsk` 10 ml, `kkp` 150 ml, `glas` 200 ml |
| Finnish | `mm` (maustemitta) 1 ml, `tl` 5 ml, `rkl` 15 ml, `dl` 100 ml, `kkp` 150 ml; `tlk` = a can, no fixed volume |
| German | `TL` 5 ml, `EL` 15 ml (some cookbooks use 10 to 12 ml), `Prise`, `Messerspitze` (no defined volume) |
| All | `g`, `kg`, `ml`, `l`, `dl`, `cl` |

## Converted units

| Unit | Factor | Notes |
|---|---|---|
| cup | 236.588 ml | US cup. The script does not look at the country; a British or Australian cup is different |
| fl oz / fluid ounce | 29.5735 ml | |
| oz / ounce | 28.3495 g | Flagged: read as weight. A liquid "oz" would be fl oz, check the item |
| lb / pound | 453.592 g | |
| pint / pt | 473.176 ml | US pint |
| quart / qt | 946.353 ml | US quart |
| gallon / gal | 3785.41 ml | US gallon |
| stick | 113 g | Only when the line names butter or margarine (smör, voi); otherwise flagged |
| tablespoon / tbsp, teaspoon / tsp | 15 ml, 5 ml | Only with `spoons = "ml"`. A US tbsp is 14.8 ml, a British 15 ml, an **Australian 20 ml** |
| °F | (F - 32) x 5/9 | Rounded to the nearest 5 °C ("350 °F" gives 175 °C by calculation) |
| inch | 2.54 cm | Nearest 1 cm, nearest 0.5 cm below 5 cm ("9-inch" gives 23 cm) |

A bracketed metric value after the unit wins over a calculation: `1 cup (240 ml) milk` becomes `240 ml milk`.
Ranges convert both ends (`1-2 cups` gives `235-470 ml`). Results from 1000 ml or g are shown as `l` or `kg`.
`decimal = ","` writes `1,89 l` for de, sv and fi notes.

## Ambiguous or undefined

- **`Tasse`:** about 250 ml in German convention but a US cup is 240 ml; left as written and flagged.
- **`Becher`, `Pck.`, `Päckchen`, `tlk`, `can`, `stk`:** no fixed size, left alone.
- **Plain "350 degrees":** no scale given, left alone.
- Any unit the script does not know is left alone without a flag.

## Rounding

Below 20: halves. Below 250: steps of 5. From 250: steps of 10. So 1 cup gives 235 ml and 2 cups 470 ml, where the
user's own earlier note wrote 240 and 475 mL: both are within 1 to 2 percent, the rule is deliberately simple and the
user can change `rn_nice_round()` if they prefer kitchen-style values.

## Volume to weight (not done by the script)

Converting a volume to grams needs the ingredient's density, which differs by ingredient and source (flour 60 to
65 g per dl). The script never does it. If a user asks for weights, use these as **ranges** and say they are
approximate; stop at an ingredient you cannot name.

| Ingredient | per dl | per msk / EL / rkl | Source spread |
|---|---|---|---|
| Wheat flour | 60 g | 8-9 g | Swedish tables 60; German 8 g per EL |
| Sugar | 85-90 g | 12-13 g | |
| Powdered sugar | 60 g | 8-9 g | |
| Butter | 90-95 g | 14 g | |
| Milk, water, cream | 100 g | 15 g | |
| Oil | 90-92 g | 13-14 g | |
| Honey | 130-140 g | 20-21 g | |
| Rolled oats | 35 g | 5-6 g | |
| Rice, uncooked | 80-85 g | 12-13 g | |
| Salt, fine | 118-125 g | 18 g | |

## Sources and limits

Read as search excerpts on 2026-10-24: Swedish conversion pages (konvertera.nu, raknar.se, hittadinmatkasse.se,
koket.se, recepten.se), the Finnish Kinuskikissa table, German pages (schlanke-rezepte.de, swissmilk.ch,
marktimhof.de, cornblogs.de). `pint` was used locally to check the US constants (1 cup 236.588 ml, 1 oz 28.35 g,
1 lb 453.592 g, 350 °F 176.7 °C); it does not define `stick`. The `ingredient-parser-nlp` package lists only
English, so it was not used. Not tested on real recipes beyond the examples in the test file and the user's samples.
