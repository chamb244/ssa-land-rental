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
| `parcel_area_ha` | Cultivated parcel area (Σ field GPS, pmm-imputed) | hectares |
| `n_fields` | Number of cultivated fields on the parcel | count |
| `weight` | Household survey weight | analytic/probability |
| `ea_id` | Enumeration area (survey PSU) | id |
| `strataid` | Survey design stratum | id |
| `country` `wave` `year` `hh_id` `holder_id` `parcel_id` | Identifiers | — |

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
parcel (`collapse (sum) … by(holder_id parcel_id)`). `n_fields` = count of fields with
a (possibly imputed) area. Parcels with no cultivated field (e.g. fully rented out)
have missing area and `n_fields==0`.

| Component | Wave | Source file | Source var(s) | Notes |
|------------------|------|----------------|----------------|----------------------------|
| GPS area | 1 | `sect3_pp_w1.dta` | `pp_s3q05_a` | × 0.0001 → ha; keep if > 0 |
| GPS area | 2 | `sect3_pp_w2.dta` | `pp_s3q05_a` | × 0.0001 → ha |
| GPS area | 3 | `sect3_pp_w3.dta` | `pp_s3q05_a` | × 0.0001 → ha |
| GPS area | 4 | `sect3_pp_w4.dta` | `s3q08` (flag `s3q07`) | × 0.0001 if `s3q07==1` |
| GPS area | 5 | `sect3_pp_w5.dta` | `s3q08` (flag `s3q07`) | × 0.0001 if `s3q07∈{1,2}` |
| Self-reported area (imputation input) | 1–3 | `sect3_pp_w*.dta` | `pp_s3q02_a`, unit `pp_s3q02_c` | converted to ha via `ET_local_area_unit_conversion.dta` |
| Self-reported area (imputation input) | 4–5 | `sect3_pp_w*.dta` | `s3q02a`, unit `s3q02b` | converted to ha (w5 uses ESS 18 conversion file) |
| Imputation stratifier | 1–5 | `sect3_pp_w*.dta` | `saq01` `saq02` `saq03` (region/zone/woreda) | `admin_3` built inline; `mi impute pmm plot_area_GPS area_self_reported i.admin_3_num` |

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
- **Rented-in / rented-out definitions widen over time.** Rented-in = "rent" in w1–2
  vs "rent + sharecrop-in" in w3–5; rented-out = a yes/no "any fields" item in w1–3 vs
  whole-parcel disposal ("all rented / all sharecropped out") in w4–5. Mind cross-wave
  level comparisons.
- **Area** is cultivated GPS area summed from fields, with missing GPS imputed by
  predictive-mean matching from self-reported area within `admin_3` (region×zone×woreda).
  The `admin_3` stratifier is built inline rather than from the pipeline's `admin3.dta`.
- **ESS21 area** omits the `sect12c` ag-extension self-reported supplement used in the
  full pipeline, because its source merge key is inconsistent (`household_id+field_id`
  vs `holder_id+parcel_id+field_id`). w5 area uses the field-roster GPS+SR imputation.
- **Weights** are taken from the household cover file; design-based estimates use
  `svyset ea_id [pw=weight], strata(strataid)` (PSU/strata interacted with wave when pooling).

---

*Built from `Reproduction_v2/Code/Cleaning_code/ETH_ESS1–5.do`, with all source
variables, codes, and value labels verified against the raw rosters.
Extend with one new country section (1–6) per country as the workflow grows.*
