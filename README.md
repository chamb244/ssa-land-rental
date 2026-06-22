# ssa-land-rental

**Land rental market descriptive statistics for Sub-Saharan Africa.**


Reproducible Stata workflow that builds parcel-level land-tenure and rental-market descriptive statistics from farm-household surveys, as reported in a manuscript currently being prepared for the *Annual Review of Resource Economics* (ARRE). The workflow is designed to enable full replication of the summary statistics used in our paper.

Coverage is currently based on the World Bank **LSMS-ISA** surveys (Ethiopia, Malawi, Mali, Niger, Nigeria, Tanzania, Uganda); plus nationally representative agricultural sample census data from Tanzania and nationally representative household panel data from Zambia.


## Output variables (unit = parcel)

| Variable | Definition |
|---|---|
| `parcel_rentedin` | Parcel rented or sharecropped IN (0/1) |
| `parcel_rentedout` | Parcel rented or sharecropped OUT (0/1) |
| `parcel_certificate` | Parcel has a land certificate / document (0/1) |
| `parcel_purchased` | Parcel acquired through purchase (0/1; `.` where not asked) |
| `parcel_area_ha` | Cultivated parcel area, ha (Σ field GPS, else self-reported) |
| `n_fields` | Number of cultivated fields on the parcel |
| `weight`, `ea_id`, `strataid` | Survey weight, PSU, design stratum |
| `country`, `wave`, `year`, `hh_id`, `holder_id`, `parcel_id` | Identifiers |

## Repository layout

```
Code/
  MASTER.do          # sets paths, installs packages, calls per-country extractors, appends
  extract_ETH.do     # Ethiopia (ESS waves 1-5)  — validated template
  extract_*.do       # one extractor per country: MWI MLI NER NGA TZA UGA
  tabular_check.do   # QC / descriptive tables (season-aware; reports season 1)
Reference/
  variable_provenance.md     # source file + variable + coding, by country and wave
  variable_provenance.docx   # same content, formatted (regenerated from the .md)
Output/
  Temp/              # per-wave intermediates (gitignored)
  Final/             # appended country files + pooled dataset (gitignored)
DATA_SOURCES.md      # where to obtain the raw microdata (not stored here)
```

## Reproducing the statistics

1. **Obtain the raw microdata.** The survey files are *not* stored in this
   repository. Download them from the World Bank LSMS-ISA program and place
   them in the folder structure described in [`DATA_SOURCES.md`](DATA_SOURCES.md).
2. **Set the path.** Edit the `global root` line at the top of `Code/MASTER.do`
   to point at your local copy. Paths use forward slashes and work on macOS,
   Windows, and Linux Stata.
3. **Run.** Execute `Code/MASTER.do`. It installs the few required packages,
   runs each enabled country extractor, and appends the results into
   `Output/Final/`.
4. **Check.** Each extractor ends with a design-weighted QC block
   (`svyset … ; svy: mean`). See `Code/tabular_check.do` for the descriptive tables.

Requires Stata 16+ (`table … , stat()` and `svy` syntax) plus the SSC packages
auto-installed by `MASTER.do`.

## Status

| Country | Survey | Waves | Status |
|---|---|---|---|
| Ethiopia | ESS (LSMS-ISA) | 1-5 (2012-2022) | ✅ built & validated |
| Malawi | IHS cross-sections (LSMS-ISA) | 2010, 2016, 2019 | ✅ built & validated |
| Mali | EACI (LSMS-ISA) | 2014, 2017 | ✅ built & validated |
| Niger | ECVMA (LSMS-ISA) | 2011, 2014 | ✅ built & validated |
| Nigeria | GHS-Panel (LSMS-ISA) | 1-5 (2011-2023) | ✅ built & validated |
| Tanzania | NPS (LSMS-ISA) | 1-5 (2009-2019) | ✅ built & validated |
| Uganda | UNPS (LSMS-ISA) | 1-5, 7, 8 (2009-2019) | ✅ built (parcel × season; reports season 1) |
| Zambia | RALS (IAPRI-MSU) | 2012, 2015, 2019 | ✅ built (field-level) |

Construction choices, exact source variables, and value-label codes for every
variable are documented per country and wave in
[`Reference/variable_provenance.md`](Reference/variable_provenance.md).

## Citation & license

If you use this code, please cite the forthcoming ARRE paper (citation TBA).

- **Code** (everything under `Code/`) is released under the **MIT License** (see `LICENSE`).
- **Documentation** (everything under `Reference/`, including the provenance tables)
  is released under **CC-BY-4.0** (see `Reference/LICENSE`).

The underlying survey data are © the World Bank / national statistical offices
and subject to their own terms; this repository redistributes none of it.
