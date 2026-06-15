# Data sources & availability

This repository contains **no survey microdata**. All inputs come from the World
Bank **Living Standards Measurement Study – Integrated Surveys on Agriculture
(LSMS-ISA)**, which are free but require registration and acceptance of the
data provider's terms before download.

- LSMS-ISA program: <https://www.worldbank.org/en/programs/lsms/initiatives/lsms-ISA>
- World Bank Microdata Library (LSMS catalog): <https://microdata.worldbank.org/index.php/catalog/lsms>

After downloading, place each survey's files in the folder the workflow expects.
`MASTER.do` reads raw inputs from `$Input`, organized as:

```
<Input>/<Country>/<round>/<survey file>.dta
```

where `$Input` is set near the top of `Code/MASTER.do`. The `<round>` folder
names used by the code are given per country below.

> **Note on file names.** LSMS-ISA distributes files with survey-specific names
> (e.g. `sect2_pp_w5.dta`, `AG_MOD_D_10.dta`). Names and letter-case can vary by
> release; on case-sensitive filesystems (Linux) match the case exactly. The
> file lists below are the specific files this workflow consumes — not the
> entire survey.

---

## Ethiopia — Socioeconomic Survey (ESS)  ✅ complete

Microdata Library (search "Ethiopia Socioeconomic Survey"):
<https://microdata.worldbank.org/index.php/catalog/lsms>

| Wave | Round folder | Survey year | WB survey |
|---|---|---|---|
| 1 | `Ethiopia/ESS 11` | 2011/12 | ERSS 2011/12 |
| 2 | `Ethiopia/ESS 13` | 2013/14 | ESS Wave 2 |
| 3 | `Ethiopia/ESS 15` | 2015/16 | ESS Wave 3 |
| 4 | `Ethiopia/ESS 18` | 2018/19 | ESS Wave 4 |
| 5 | `Ethiopia/ESS 21` | 2021/22 | ESS Wave 5 |

Files consumed per wave (`w` = 1…5):

| Role | File | Used for |
|---|---|---|
| Parcel roster | `sect2_pp_w<w>.dta` | tenure: rented-in/out, certificate, purchased |
| Field roster | `sect3_pp_w<w>.dta` | plot area (GPS + self-reported) |
| Household cover | `sect_cover_hh_w<w>.dta` | survey weight, strata source (`rural`/`saq14`, `saq01`) |
| Land-unit conversion | `ET_local_area_unit_conversion.dta` | self-reported area → ha (in ESS 11/13/15/18; wave 5 reuses the ESS 18 copy) |

---

## Malawi — Integrated Household Panel Survey (IHPS)  🚧 in progress

**Source:** the four-wave IHPS **panel** release
`MWI_2010-2019_IHPS_v06_M_Stata.zip` (World Bank Microdata Library; search
"Malawi Integrated Household Panel Survey"). The standalone IHS-IV (2016) and
IHS-V (2019) cross-sections are *different surveys* with incompatible household
IDs and are **not** used here.

Extracted flat (all four waves in one folder; filenames carry the year suffix
`_10` / `_13` / `_16` / `_19`) to:

```
Malawi/IHPS_panel_v6/MWI_2010-2019_IHPS_v06_M_Stata/
```

The extractor points all four waves at this single folder (no per-wave subfolders).

| Wave | Survey year | HH id |
|---|---|---|
| 1 | 2010 | `case_id` |
| 2 | 2013 | `y2_hhid` |
| 3 | 2016 | `y3_hhid` |
| 4 | 2019/20 | `y4_hhid` |

Files consumed (year suffix `yy` ∈ {10,13,16,19}; names lowercase in v06):

| Role | Wave 1-2 | Wave 3-4 | Used for |
|---|---|---|---|
| Tenure / acquisition | `ag_mod_d_yy.dta` (`ag_d03`) | `ag_mod_b2_yy.dta` (`ag_b203…`) | rented-in/out, certificate, purchased |
| Field roster | `ag_mod_c_yy.dta` | `ag_mod_c_yy.dta` | plot area |
| Perennial roster | `ag_mod_o2_13.dta` (w2) | `ag_mod_o2_yy.dta` | plot area (perennial gardens) |
| Household cover | `hh_mod_a_filt_yy.dta` | `hh_mod_a_filt_yy.dta` | weight (`hh_wgt`/`panelweight_*`), `ea_id`, `stratum` |

**Acquisition codes (verified against the raw value labels)** —
`ag_d03` (w1-2) / `ag_b203` (w3) "How did your household acquire this plot/garden?":
1 granted by local leaders · 2 inherited · 3 bride price · **4 purchased (with title)** ·
**5 purchased (no title; w1-2 only)** · 6 leasehold · 7 rent short-term ·
8 farming as a tenant · 9 borrowed for free · 10 moved in w/o permission ·
11 other · (w3+:) 12 allocated by family member · 13 gift from non-HH member.

Derivation (to be finalized in `extract_MWI.do`):
- `parcel_purchased` = acquisition ∈ {4,5}  (measurable all waves)
- `parcel_rentedin`  = acquisition ∈ {6,7,8} (leasehold / rent / tenant)
- `parcel_rentedout` = rent **received** (`ag_d19*`/`ag_b219*`; wave 4 has explicit
  `ag_brentedout`). Malawi's garden roster includes rented-out gardens, so — unlike
  Ethiopia — rented-out is observable without base-frame loss.
- `parcel_certificate` = w2 `ag_d03_1` (title y/n); w3 `ag_b204_1` (codes 1-3 = yes);
  w1 not asked (missing); w4 TBD.

> Note: wave 4's acquisition method is not in `ag_b203` (that slot is "year
> acquired" in 2019); the w4 acquisition variable and certificate handling are
> being confirmed against the raw data during extractor construction.

---

## Mali — Enquête Agricole de Conjoncture Intégrée (EACI)  ✅ built

Two separate cross-sectional rounds, extracted to:

| Wave | Round folder | Year | Source zip |
|---|---|---|---|
| 1 | `Mali/EACI 14` | 2014 | `MLI_2014_EACI_v03_M_STATA11.zip` |
| 2 | `Mali/EACI 17` | 2017 | `MLI_2017_EAC-I_v03_M_STATA.zip` |

The 2017 round uses a different file-naming scheme (`eaci17_sNNpY.dta`) and variable
prefix (`s11b…`) than 2014 (`EACI…_p1.dta`, `s1b…`), and its `.dta` files are Latin-1
encoded. Files consumed:

| Role | 2014 | 2017 | Used for |
|---|---|---|---|
| Parcel roster | `EACIEXPLOI_p1.dta` (`s1bq*`) | `eaci17_s11bp1.dta` (`s11bq*`) | tenure (`*q17`), acquisition (`*q22`), disposition (`*q32`), area |
| Weights | `EACIPOIDS.dta` (`poids_menage`) | `EACI17_ECHANTILLON.dta` (`poids_leger`, `strate`) | survey weight, PSU (`grappe`), 2017 strata |
| Cover | `EACICONTROLE_p1.dta` | `eaci17_s00p1.dta` | 2014 strata (`s00q01` region × `s00q04` milieu) |

> Note: EACI surveys only the parcels a household **operates**, so land rented/lent
> **out** is out of frame - `parcel_rentedout` is set missing for Mali (see the
> provenance doc, Mali §6). Purchase **is** measurable (acquisition code 7 = Achat).

---

## Planned countries

To be documented (survey files + WB catalog links) as each extractor is built:

| Country | Survey | Rounds |
|---|---|---|
| Niger | Enquête Nationale sur les Conditions de Vie (ECVMA) | 2011, 2014 |
| Nigeria | General Household Survey – Panel (GHS) | 2010/11, 2012/13, 2015/16, 2018/19, 2023 |
| Tanzania | National Panel Survey (NPS) | 2008/09, 2010/11, 2012/13, 2014/15, 2019/20 |
| Uganda | National Panel Survey (UNPS) | 2009/10 → 2019/20 |

---

*Exact per-survey Microdata Library catalog URLs can be added here once
confirmed. Open an issue or PR if a file name differs in a newer release.*
