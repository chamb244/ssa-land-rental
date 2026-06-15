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

Microdata Library (search "Malawi Integrated Household Panel Survey"):
<https://microdata.worldbank.org/index.php/catalog/lsms>

| Wave | Round folder | Survey year | Status on this machine |
|---|---|---|---|
| 1 | `Malawi/IHPS 10` | 2010 | present (cloud-synced) |
| 2 | `Malawi/IHPS 13` | 2013 | present, but files currently sit **inside the `IHPS 10` folder** |
| 3 | `Malawi/IHPS 16` | 2016 | **MISSING — folder empty** |
| 4 | `Malawi/IHPS 19` | 2019/20 | **MISSING — folder empty** |

Files this workflow needs per wave:

| Role | Wave 1-2 file | Wave 3-4 file | Used for |
|---|---|---|---|
| Tenure / acquisition | `AG_MOD_D_<yy>.dta` (`ag_d03`) | `AG_MOD_B2_<yy>.dta` (`ag_b203…`) | rented-in/out, certificate, purchased |
| Field roster | `AG_MOD_C_<yy>.dta` | `AG_MOD_C_<yy>.dta` | plot area |
| Perennial roster | — | `AG_MOD_O2_<yy>.dta` | plot area (perennial gardens) |
| Household cover | `HH_MOD_A_FILT_<yy>.dta` | `HH_MOD_A_FILT_<yy>.dta` | weight (`hh_wgt`/`panelweight*`), `ea_id`, `stratum` |

> ⚠️ **Open blockers for Malawi** (see project notes):
> 1. The rental variables were never built in the upstream pipeline, so
>    `parcel_rentedin`/`parcel_rentedout` (and `parcel_purchased`) must be
>    derived from the acquisition question (`ag_d03` / `ag_b203`); the exact
>    rent/sharecrop/purchase codes still need verification against the raw value labels.
> 2. The 2016 (`IHPS 16`) and 2019 (`IHPS 19`) raw files are not present locally,
>    and the 2013 files are nested in the `IHPS 10` folder. These must be obtained /
>    reorganized before Malawi can be built and validated.

---

## Planned countries

To be documented (survey files + WB catalog links) as each extractor is built:

| Country | Survey | Rounds |
|---|---|---|
| Mali | Enquête Agricole de Conjoncture (EACI) | 2014, 2017 |
| Niger | Enquête Nationale sur les Conditions de Vie (ECVMA) | 2011, 2014 |
| Nigeria | General Household Survey – Panel (GHS) | 2010/11, 2012/13, 2015/16, 2018/19, 2023 |
| Tanzania | National Panel Survey (NPS) | 2008/09, 2010/11, 2012/13, 2014/15, 2019/20 |
| Uganda | National Panel Survey (UNPS) | 2009/10 → 2019/20 |

---

*Exact per-survey Microdata Library catalog URLs can be added here once
confirmed. Open an issue or PR if a file name differs in a newer release.*
