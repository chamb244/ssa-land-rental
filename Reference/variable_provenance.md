# Variable Provenance & Construction Reference
### LSMS-ISA land-tenure / rental-market descriptives (parcel level)

**Project:** `Reproduction_rental_260615` — slim parcel-level extractor for the
land-tenure descriptives in the invited *Annual Review of Resource Economics*
(ARRE) paper.
**Purpose of this document:** for every final variable, record the exact source
data file and source variable(s), by country and wave, plus the construction
rule, so any number can be traced back to the questionnaire / raw data and the
workflow is fully reproducible.

**How to read it.** Each country has (1) a survey/wave key, (2) a provenance
table for the four tenure indicators, (3) a sub-table for parcel area, (4) tables
for the design variables (weight, PSU, strata) and identifiers, (5) the value
labels of the key categorical source variables, and (6) the harmonization
decisions that the descriptive statistics depend on. Source files are named as
they appear in `Reproduction_v2/Folder_structures/Input data/<Country>/<round>/`.

**Final variables (unit = parcel):**

| Output variable | Definition | Type |
|---|---|---|
| `parcel_rentedin` | Parcel rented or sharecropped IN | 0/1 |
| `parcel_rentedout` | Parcel rented or sharecropped OUT | 0/1 |
| `parcel_certificate` | Parcel has a land certificate / document | 0/1 |
| `parcel_purchased` | Parcel acquired through purchase | 0/1 (`.` if not asked) |
| `parcel_area_ha` | Cultivated parcel area (Σ field GPS, else self-reported) | hectares |
| `n_fields` | Number of cultivated fields on the parcel | count |
| `weight` | Household survey weight | analytic/probability |
| `ea_id` | Enumeration area (survey PSU) | id |
| `strataid` | Survey design stratum | id |
| `country` `wave` `year` `hh_id` `holder_id` `parcel_id` | Identifiers | — |

---

## Missing by design (read this before interpreting the tables)

Some variables are **missing (`.`) for entire country-years**. These are
**structural** missings: the survey simply did not ask the relevant question that
round, so the concept is *unmeasured*, not zero and not item non-response. A `.`
here means "not collected this wave," and these country-years must be **excluded**
(not treated as 0) when computing rates or trends. This is why the QC estimates one
variable at a time - a joint `mean`/`svy: mean` would casewise-drop these whole
country-years from the *other* variables too.

| Country | Variable | Missing year(s) | Why |
|---------|--------------------|-----------------|--------------------------------------------------|
| Ethiopia | `parcel_purchased` | 2012, 2014 | ESS11/ESS13 acquisition question had **no "purchased" category**; "Purchased" (code 7) is first offered in wave 3 (2016). |
| Malawi | `parcel_certificate` | 2010 | IHPS 2010 has **no title/ownership-document question** for the plot. |
| Malawi | `parcel_certificate` | 2019 | The 2019 round **dropped** the title/document question. |
| Malawi | `parcel_purchased` | 2019 | The 2019 round **dropped the categorical "how acquired" question** entirely (only "from whom" and "year acquired" remain), so acquisition mode - including purchase - is not identifiable. |

All other variables are populated in every country-year shown. (Within a populated
country-year, ordinary item non-response is handled the usual way - e.g. a parcel
with no usable area is missing on `parcel_area_ha` only.)

---

## ETHIOPIA — Ethiopia Socioeconomic Survey (ESS)

### 1. Survey & wave key

| Wave | Round | Year (assigned) | Parcel roster | Field roster | HH cover | HH id |
|------|--------|--------|----------------|----------------|----------------|------------|
| 1 | ESS 11 | 2012 | `sect2_pp_w1.dta` | `sect3_pp_w1.dta` | `sect_cover_hh_w1.dta` | `household_id` |
| 2 | ESS 13 | 2014 | `sect2_pp_w2.dta` | `sect3_pp_w2.dta` | `sect_cover_hh_w2.dta` | `household_id2` |
| 3 | ESS 15 | 2016 | `sect2_pp_w3.dta` | `sect3_pp_w3.dta` | `sect_cover_hh_w3.dta` | `household_id2` |
| 4 | ESS 18 | 2019 | `sect2_pp_w4.dta` | `sect3_pp_w4.dta` | `sect_cover_hh_w4.dta` | `household_id` |
| 5 | ESS 21 | 2022 | `sect2_pp_w5.dta` | `sect3_pp_w5.dta` | `sect_cover_hh_w5.dta` | `household_id` |

Land-unit conversion file (for self-reported area): `ET_local_area_unit_conversion.dta`,
present in ESS 11/13/15/18; **wave 5 reuses the ESS 18 copy** (none ships with ESS 21).

### 2. Tenure indicators

All four are built on the **parcel roster** (`sect2_pp_w*.dta`); key = `holder_id parcel_id`.
"Acquisition" = the parcel-acquisition question; its value labels are in §5.

| Variable | Wave | Source file | Source var | Construction |
|------------------|------|----------------|--------------|--------------------------------|
| `parcel_rentedin` | 1 | `sect2_pp_w1.dta` | `pp_s2q03` | `inlist(pp_s2q03,3)` — Rent |
| `parcel_rentedin` | 2 | `sect2_pp_w2.dta` | `pp_s2q03` | `inlist(pp_s2q03,3)` — Rent |
| `parcel_rentedin` | 3 | `sect2_pp_w3.dta` | `pp_s2q03` | `inlist(pp_s2q03,3,6)` — Rent + Sharecrop-in |
| `parcel_rentedin` | 4 | `sect2_pp_w4.dta` | `s2q05` | `inlist(s2q05,3,6)` — Rent + Sharecrop-in |
| `parcel_rentedin` | 5 | `sect2_pp_w5.dta` | `s2q05` | `inlist(s2q05,3,6)` — Rent + Sharecrop-in |
| `parcel_rentedout` | 1 | `sect2_pp_w1.dta` | `pp_s2q10` | `pp_s2q10==1` — any fields rented out (Yes/No) |
| `parcel_rentedout` | 2 | `sect2_pp_w2.dta` | `pp_s2q10` | `pp_s2q10==1` |
| `parcel_rentedout` | 3 | `sect2_pp_w3.dta` | `pp_s2q10` | `pp_s2q10==1` |
| `parcel_rentedout` | 4 | `sect2_pp_w4.dta` | `s2q13` | `inlist(s2q13,1,2)` — all rented out / all sharecropped out |
| `parcel_rentedout` | 5 | `sect2_pp_w5.dta` | `s2q13` | `inlist(s2q13,1,2)` — all rented out / all sharecropped out |
| `parcel_certificate` | 1 | `sect2_pp_w1.dta` | `pp_s2q04` (+`pp_s2q03`) | `pp_s2q04`: 1→1, 2→0; then 0 if `pp_s2q03∈{3,4,6}` |
| `parcel_certificate` | 2 | `sect2_pp_w2.dta` | `pp_s2q04` (+`pp_s2q03`) | `pp_s2q04`: 1→1, 2→0; then 0 if `pp_s2q03∈{3,4,6}` |
| `parcel_certificate` | 3 | `sect2_pp_w3.dta` | `pp_s2q04` (+`pp_s2q03`) | `pp_s2q04`: 1→1, 2→0; then 0 if `pp_s2q03∈{3,4,6}` |
| `parcel_certificate` | 4 | `sect2_pp_w4.dta` | `s2q03` | `s2q03`: 1→1, 2→0 (document) |
| `parcel_certificate` | 5 | `sect2_pp_w5.dta` | `s2q03` | `s2q03`: 1→1, 2→0 (document) |
| `parcel_purchased` | 1 | `sect2_pp_w1.dta` | `pp_s2q03` | **missing** — no purchase category asked |
| `parcel_purchased` | 2 | `sect2_pp_w2.dta` | `pp_s2q03` | **missing** — no purchase category asked |
| `parcel_purchased` | 3 | `sect2_pp_w3.dta` | `pp_s2q03` | `pp_s2q03==7` — Purchased |
| `parcel_purchased` | 4 | `sect2_pp_w4.dta` | `s2q05` | `s2q05==7` — Purchased |
| `parcel_purchased` | 5 | `sect2_pp_w5.dta` | `s2q05` | `s2q05==7` — Purchased |

### 3. Parcel area (`parcel_area_ha`)

Built on the **field roster** (`sect3_pp_w*.dta`) at field level, then summed to the
parcel (`collapse (sum) … by(holder_id parcel_id)`). Field area = **GPS where
measured, else self-reported** (both in ha); no model-based imputation, so the measure
is deterministic and reproducible across languages. `n_fields` = count of fields with a
non-missing area. Parcels with no cultivated field (e.g. fully rented out) have missing
area and `n_fields==0`.

| Component | Wave | Source file | Source var(s) | Notes |
|------------------|------|----------------|----------------|----------------------------|
| GPS area (primary) | 1 | `sect3_pp_w1.dta` | `pp_s3q05_a` | × 0.0001 → ha; keep if > 0 |
| GPS area (primary) | 2 | `sect3_pp_w2.dta` | `pp_s3q05_a` | × 0.0001 → ha |
| GPS area (primary) | 3 | `sect3_pp_w3.dta` | `pp_s3q05_a` | × 0.0001 → ha |
| GPS area (primary) | 4 | `sect3_pp_w4.dta` | `s3q08` (flag `s3q07`) | × 0.0001 if `s3q07==1` |
| GPS area (primary) | 5 | `sect3_pp_w5.dta` | `s3q08` (flag `s3q07`) | × 0.0001 if `s3q07∈{1,2}` |
| Self-reported area (fallback when GPS missing) | 1–3 | `sect3_pp_w*.dta` | `pp_s3q02_a`, unit `pp_s3q02_c` | converted to ha via `ET_local_area_unit_conversion.dta` |
| Self-reported area (fallback when GPS missing) | 4–5 | `sect3_pp_w*.dta` | `s3q02a`, unit `s3q02b` | converted to ha (w5 uses ESS 18 conversion file) |

### 4. Design variables & identifiers

| Variable | Wave | Source file | Source var(s) | Construction |
|----------------|------|----------------|----------------|------------------------------|
| `weight` | 1 | `sect_cover_hh_w1.dta` | `pw` | key `household_id` |
| `weight` | 2 | `sect_cover_hh_w2.dta` | `pw2` | key `household_id2` |
| `weight` | 3 | `sect_cover_hh_w3.dta` | `pw_w3` | key `household_id2` |
| `weight` | 4 | `sect_cover_hh_w4.dta` | `pw_w4` | key `household_id` |
| `weight` | 5 | `sect_cover_hh_w5.dta` | `pw_w5` | key `household_id` |
| `ea_id` (PSU) | 1–5 | `sect2_pp_w*.dta` | `ea_id` | carried raw from parcel roster |
| `strataid` | 1 | `sect_cover_hh_w1.dta` | `rural`, `saq01` | `group(rural region2)`; `region2`: `saq01∈{2,6,12,13,15}`→99 |
| `strataid` | 2 | `sect_cover_hh_w2.dta` (+ w1 strata) | `rural`, `saq01` | chained from w1; new urban (`rural==3`) strata added (+10) |
| `strataid` | 3 | `sect_cover_hh_w3.dta` (+ w2 strata) | `rural`, `saq01` | chained from w2; new HHs = max strata within `saq01×rural` |
| `strataid` | 4 | `sect_cover_hh_w4.dta` | `saq14`, `saq01` | explicit region×rural/urban recode (codes 1–32, 99) |
| `strataid` | 5 | `sect_cover_hh_w5.dta` | `saq14`, `saq01` | explicit region×rural/urban recode (codes 1–32, 99) |
| `holder_id`, `parcel_id` | 1–5 | `sect2_pp_w*.dta` | `holder_id`, `parcel_id` | parcel key (also present on field roster) |
| `hh_id` | 1–5 | parcel roster / cover | `household_id` (w1,4,5) / `household_id2` (w2,3) | renamed `hh_id` |
| `year` | 1–5 | — | — | assigned: 2012/2014/2016/2019/2022 |
| `country` | 1–5 | — | — | assigned `"Ethiopia"` |

### 5. Value labels of key source variables (verified against the raw rosters)

**Parcel acquisition** — `pp_s2q03` (w1–3) / `s2q05` (w4–5), *"How did your household acquire [PARCEL]?"*

| Code | w1 (ESS11) | w2 (ESS13) | w3 (ESS15) | w4 (ESS18) | w5 (ESS21) |
|--------|-----------|-----------|-----------|-----------|-----------|
| 1 | Granted by local leaders | Granted by local leaders | Granted by local leaders | Granted by local leaders | Granted by local leaders |
| 2 | Inherited | Inherited | Inherited | Gift / Inherited | Inherited |
| 3 | **Rent** | **Rent** | **Rent** | **Rent** | **Rent** |
| 4 | Borrowed for free | Borrowed for free | Borrowed for free | Borrowed for free | Borrowed for free |
| 5 | Moved in w/o permission | Moved in w/o permission | Moved in w/o permission | Moved in w/o permission | Moved in w/o permission |
| 6 | Other (specify) | Other (specify) | **Shared crop in** | **Shared crop in** | **Shared crop in** |
| 7 | — | — | **Purchased** | **Purchased** | **Purchased** |
| 8 | — | — | Other (specify) | Other (specify) | Other (specify) |
| 10/11/12 | Moved-in / Other variants | — | — | — | — |

**Rented out** — `pp_s2q10` (w1–3): `1 = Yes` (any fields rented out), `2 = No`.
`s2q13` (w4–5): `1 = all rented out`, `2 = all sharecropped out`, `3 = all given out free`, `4 = No`.

**Certificate / document** — `pp_s2q04` (w1–3, "certificate") / `s2q03` (w4–5, "document"): `1 = Yes`, `2 = No`.

**Rural/urban for strata** — `rural` (w1–3) and `saq14` (w4–5, `1 = rural`, `2 = urban`, small-town categories per round).

### 6. Harmonization decisions & caveats (Ethiopia)

- **Unit = parcel.** The universe is every parcel in the parcel roster, so parcels
  entirely rented/sharecropped out are retained even though they have no cultivated
  fields. (Basing on the field roster zeroed out rented-out in w4–5 — see project notes.)
- **`parcel_purchased` is missing in w1–w2.** ESS11/ESS13 offered no "Purchased"
  acquisition category, so purchase is unmeasured (`.`), not a structural zero.
  *Estimate this variable separately:* a joint `mean`/`svy: mean` with the other
  variables uses casewise deletion and silently drops all of 2012–2014.
- **Rental scope: both cash/fixed rental AND sharecropping are counted - read with
  care across waves.** Rented-in is built from the parcel-acquisition question, where
  "Rent" (code 3) and "Shared crop in" (code 6) are separate categories; we include
  both. But the "shared crop in" category only existed from wave 3 (2016) onward - in
  waves 1-2 (2012, 2014) the questionnaire had no separate sharecropping-in option, so
  those years capture rent only (any sharecropping-in fell under "Other"). This is part
  of why rented-in ticks up from 2014 to 2016.
  Rented-out also includes both, but the explicit split appears only from wave 4 (2019):
  `s2q13` distinguishes "all rented out" (1) vs "all sharecropped out" (2), and we count
  both. In waves 1-3 (2012-2016) rented-out comes from a single yes/no item ("were any
  fields rented out?") that does not separately label sharecropping, so it is captured
  broadly rather than itemized.
  Excluded on both sides: "borrowed for free" (acquisition code 4) and "given out for
  free" (disposal code 3 in 2019/2022) - i.e., free / non-market transfers are not
  counted as renting. And because "Rent" (code 3) is not itself split into cash vs fixed
  in-kind rent, "rented in/out" here means cash-or-fixed rental plus sharecropping, not
  cash-only.
- **Area** is cultivated field area summed to the parcel, using GPS where measured and
  self-reported area as a fallback where GPS is missing. The published pipeline instead
  model-imputes missing GPS (pmm); we use the deterministic GPS-else-self-reported
  measure so area reproduces exactly across Stata/R/Python. Tenure variables are unaffected.
- **ESS21 area** omits the `sect12c` ag-extension self-reported supplement used in the
  full pipeline, because its source merge key is inconsistent (`household_id+field_id`
  vs `holder_id+parcel_id+field_id`). w5 area uses the field-roster GPS-else-self-reported measure.
- **Weights** are taken from the household cover file; design-based estimates use
  `svyset ea_id [pw=weight], strata(strataid)` (PSU/strata interacted with wave when pooling).

---

## MALAWI — Integrated Household Panel Survey (IHPS)

Source: the four-wave IHPS **panel** release `MWI_2010-2019_IHPS_v06`, extracted
flat to `Malawi/IHPS_panel_v6/MWI_2010-2019_IHPS_v06_M_Stata/` (all waves point at
this one folder; filenames carry the year suffix).

> **Unit note.** The survey's land unit changed: in 2010/2013 tenure is asked at the
> **plot** level (no garden grouping), so `parcel` := plot; in 2016/2019 tenure is
> asked at the **garden** level and `parcel` := garden (area summed from its plots).

### 1. Survey & wave key

| Wave | Round | Year | HH id | Tenure module (unit) | Area module |
|------|--------|--------|----------------|--------------------------|----------------------------|
| 1 | IHS3/IHPS | 2010 | `case_id` | `ag_mod_d_10` (plot) | `ag_mod_c_10` |
| 2 | IHPS | 2013 | `y2_hhid` | `ag_mod_d_13` (plot) | `ag_mod_c_13` + `ag_mod_o2_13` |
| 3 | IHPS | 2016 | `y3_hhid` | `ag_mod_b2_16` (garden) | `ag_mod_c_16` + `ag_mod_o2_16` |
| 4 | IHPS | 2019/20 | `y4_hhid` | `ag_mod_b2_19` (garden) | `ag_mod_c_19` + `ag_mod_o2_19` |

Household cover (weight, `ea_id`, strata): `hh_mod_a_filt_<yy>.dta`.

### 2. Tenure indicators

| Variable | Wave | Source file | Source var | Construction |
|------------------|------|----------------|--------------|--------------------------------|
| `parcel_rentedin` | 1 | `ag_mod_d_10` | `ag_d03` | `inlist(ag_d03,6,7,8)` — leasehold/rent/tenant |
| `parcel_rentedin` | 2 | `ag_mod_d_13` | `ag_d03` | `inlist(ag_d03,6,7,8)` |
| `parcel_rentedin` | 3 | `ag_mod_b2_16` | `ag_b203` | `inlist(ag_b203,6,7,8)` |
| `parcel_rentedin` | 4 | `ag_mod_b2_19` | `ag_brentedin`, `ag_b211a/b` | `ag_brentedin==1` OR paid owner `ag_b211a/b>0` (no acq. question in 2019) |
| `parcel_rentedout` | 1-2 | `ag_mod_d_<yy>` | `ag_d19a-d` | rent received >0 (cash/in-kind, already/still) |
| `parcel_rentedout` | 3 | `ag_mod_b2_16` | `ag_b219a-d` | rent received >0 |
| `parcel_rentedout` | 4 | `ag_mod_b2_19` | `ag_brentedout`, `ag_b219a-d` | `ag_brentedout==1` OR `ag_b219a-d>0` |
| `parcel_certificate` | 1 | — | — | **missing** — not asked |
| `parcel_certificate` | 2 | `ag_mod_d_13` | `ag_d03_1` | `ag_d03_1==1` (has title) |
| `parcel_certificate` | 3 | `ag_mod_b2_16` | `ag_b204_1` | `inlist(ag_b204_1,1,2,3)` (lease offer / title deed / lease cert) |
| `parcel_certificate` | 4 | — | — | **missing** — not asked |
| `parcel_purchased` | 1-2 | `ag_mod_d_<yy>` | `ag_d03` | `inlist(ag_d03,4,5)` — purchased w/ or w/o title |
| `parcel_purchased` | 3 | `ag_mod_b2_16` | `ag_b203` | `ag_b203==4` — purchased |
| `parcel_purchased` | 4 | — | — | **missing** — acquisition question dropped in 2019 |

### 3. Parcel area (`parcel_area_ha`)

Field roster `ag_mod_c_<yy>` (+ perennial `ag_mod_o2_<yy>` for w2-4). Field area =
GPS (`ag_c04c`) where measured, else self-reported (`ag_c04a`, unit `ag_c04b`:
1=acre, 2=ha, 3=m²); acres→ha via ×0.404686. No model-based imputation (the published
pipeline pmm-imputes missing GPS; we use the deterministic GPS-else-self-reported
measure for cross-language reproducibility). Summed to the parcel: garden in w3-4;
in w1-2 each plot is its own parcel. `n_fields` = cultivated fields per parcel.

### 4. Design variables & identifiers

| Variable | Wave | Source file | Source var(s) | Construction |
|----------------|------|----------------|----------------|------------------------------|
| `weight` | 1 | `hh_mod_a_filt_10` | `hh_wgt` | baseline sampling weight |
| `weight` | 2 | `hh_mod_a_filt_13` | `panelweight` | panel weight 2013 |
| `weight` | 3 | `hh_mod_a_filt_16` | `panelweight_2016` | panel weight 2016 |
| `weight` | 4 | `hh_mod_a_filt_19` | `panelweight_2019` | panel weight 2019 |
| `ea_id` | 1-4 | `hh_mod_a_filt_<yy>` | `ea_id` | enumeration area (PSU) |
| `strataid` | 1-2 | `hh_mod_a_filt_<yy>` | `stratum` | baseline stratum (region × urban/rural) |
| `strataid` | 3-4 | `hh_mod_a_filt_<yy>` | `region`, `reside` | `group(region reside)` (no `stratum` in cover) |
| `parcel_id` | 1-2 | tenure module | `hh_id` + plot no. (`ag_d00`) | concatenated |
| `parcel_id` | 3-4 | tenure module | `hh_id` + `gardenid` | concatenated |
| `year` | 1-4 | — | — | 2010 / 2013 / 2016 / 2019 |

### 5. Value labels of key source variables (verified)

**Acquisition** — `ag_d03` (w1-2) / `ag_b203` (w3): *"How did your household acquire this [plot/garden]?"*

| Code | w1-2 (ag_d03) | w3 (ag_b203) |
|------|---------------|--------------|
| 1 | Granted by local leaders | Granted by local leaders |
| 2 | Inherited | Inherited |
| 3 | Bride price | Bride price |
| 4 | **Purchased (with title)** | **Purchased** |
| 5 | **Purchased (no title)** | — |
| 6 | Leasehold | Leasehold |
| 7 | Rent short-term | Rent short-term |
| 8 | Farming as a tenant | Farming as a tenant |
| 9 | Borrowed for free | Borrowed for free |
| 10 | Moved in w/o permission | Moved in w/o permission |
| 11 | Other | Other |
| 12 / 13 | — | Allocated by family / Gift from non-HH |

*(Wave 4 has no acquisition-method question — only "from whom" and "year acquired".)*

**Rented out / in (w4 flags)** — `ag_brentedin` ("gave output as rent" → rented in),
`ag_brentedout` ("received output as rent" → rented out): `1 = Yes`, `2 = No`.
Rent amounts `ag_d19a-d` / `ag_b219a-d` = cash/in-kind received (already / still due).

**Certificate** — `ag_d03_1` (w2, has title): `1 = Yes`, `2 = No`.
`ag_b204_1` (w3): `1` offer of lease · `2` title deed · `3` certificate of lease · `4` no · `96` other.

### 6. Harmonization decisions & caveats (Malawi)

- **Rental variables were derived here, not inherited** — the upstream pipeline never
  built `plot_rentedin/out` for Malawi. They are constructed from the acquisition
  question (rented-in) and the rent-received variables (rented-out).
- **Land unit changes across waves** — plot (2010/2013) vs garden (2016/2019). Counts
  and mean areas are not strictly unit-comparable across that break.
- **Wave 4 (2019)**: the categorical acquisition question was dropped, so
  `parcel_purchased` and `parcel_certificate` are **missing** in 2019, and rented-in
  uses a payment-based proxy (`ag_brentedin` / paid-owner) rather than an acquisition code.
- **Rented-in** = leasehold/rent/tenant (codes 6,7,8); "borrowed for free" (9) is
  excluded as non-market access.
- **Rented-out is NOT comparable across waves - do not read the trend.** It is captured
  differently by wave: 2010 and 2013 identify rented-out only via positive rent
  *received* (`ag_d19a-d`), with heavy skip/missing on those amount items, whereas 2019
  has an explicit yes/no flag (`ag_brentedout`). As a result the weighted rate is ~0.2%
  in 2010 versus ~1.3-1.5% in 2016/2019. The early levels almost certainly understate
  rented-out, so the apparent increase over time is largely a measurement artifact
  rather than a real change in behavior.
- **Purchase** is genuinely measurable here (codes 4-5), unlike Ethiopia w1-2.
- **Strata**: baseline `stratum` (w1-2) vs `group(region reside)` (w3-4).
- **Year map** follows the IHPS rounds (2010/2013/2016/2019); the shocks do-file used
  2017/2020 for w3/w4 — change `year` in `extract_MWI.do` if you prefer that labeling.

---

*Built from `Reproduction_v2/Code/Cleaning_code/ETH_ESS1–5.do` and the IHPS v06 raw
modules (Malawi), with all source variables, codes, and value labels verified against
the raw data. Extend with one new country section (1–6) per country as the workflow grows.*
