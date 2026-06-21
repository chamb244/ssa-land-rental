# assemble_report.py - assemble the consolidated report (Markdown) from the live
# project outputs: coverage, the three share tables (from Output/Tables CSVs), the
# trend figure, the definitions + "read before interpreting" notes and the full
# per-country provenance appendix (from Reference/variable_provenance.md).
#
# Sections marked  <!-- DRAFT --> ... > **[DRAFT - Jordan]** _..._  are prose
# placeholders for the author to write. Re-running this script REGENERATES the
# scaffold (it will overwrite prose), so once you start drafting, edit
# consolidated_report.md directly and rebuild with build_report.sh instead.
import os, datetime, csv, shutil, re

HERE=os.path.dirname(os.path.abspath(__file__))
ROOT=os.path.dirname(HERE)
TAB=f"{ROOT}/Output/Tables"; FIG=f"{ROOT}/Output/Figures"
PROV=f"{ROOT}/Reference/variable_provenance.md"
OUT=f"{HERE}/consolidated_report.md"

# ---- pull blocks out of the provenance markdown by heading text ----------------
prov=open(PROV,encoding="utf-8").read()
def between(text,start,end):
    i=text.index(start); j=text.index(end,i+len(start)) if end else len(text)
    return text[i:j].rstrip()
defs   = between(prov,"**Final variables (unit = parcel):**","## Missing by design")
missing= between(prov,"## Missing by design","## Rented-in: sharecropping")
share  = between(prov,"## Rented-in: sharecropping","## ETHIOPIA")
missing = missing.replace("| Country | Variable | Missing year(s) | Why |",
    "**Table 3. Structurally missing variables** - items not collected in particular country-years.\n\n| Country | Variable | Missing year(s) | Why |")
share = share.replace("| Country | Sharecropping in `rented_in`? | Basis |",
    "**Table 4. Sharecropping coverage in `rented_in`**, by survey.\n\n| Country | Sharecropping in `rented_in`? | Basis |")
# appendix = all per-country sections, minus the closing italic note
appx   = prov[prov.index("## ETHIOPIA"):]
appx   = appx[:appx.index("*Built from")].rstrip()

# ---- csv -> grouped markdown table ---------------------------------------------
def csv_to_md(path):
    with open(path,encoding="utf-8") as f:
        rows=list(csv.reader(f))
    head,body=rows[0],rows[1:]
    out=["| "+" | ".join(head)+" |","|"+"|".join(["---"]*len(head))+"|"]
    for r in body:
        out.append("| "+" | ".join(c if c!="" else " " for c in r)+" |")
    return "\n".join(out)

tbl_hh  =csv_to_md(f"{TAB}/table_hh_share.csv")
tbl_plot=csv_to_md(f"{TAB}/table_plot_share.csv")
tbl_area=csv_to_md(f"{TAB}/table_area_share.csv")

# ---- copy the figure next to the report so paths are portable ------------------
shutil.copyfile(f"{FIG}/trends_by_country_plot.png", f"{HERE}/figure_trends.png")
shutil.copyfile(f"{FIG}/trends_by_country_hh.png", f"{HERE}/figure_trends_hh.png")

today=datetime.date.today().isoformat()
COVERAGE="""| Country | Survey (source) | Survey years | Spatial unit (reporting unit) |
|---|---|---|---|
| Ethiopia | ESS (LSMS-ISA) | 2012, 2014, 2016, 2019, 2022 | parcel (subdivided into fields) |
| Malawi | IHPS (LSMS-ISA) | 2010, 2013, 2016, 2019 | garden (subdivided into plots) |
| Mali | EACI (LSMS-ISA) | 2014, 2017 | parcelle (single land unit) |
| Niger | ECVMA (LSMS-ISA) | 2011, 2014 | parcelle (single land unit) |
| Nigeria | GHS-Panel (LSMS-ISA) | 2011, 2013, 2016, 2019, 2023 | plot (single land unit) |
| Tanzania | NPS (LSMS-ISA) | 2009, 2011, 2013, 2015, 2019 | plot (single land unit) |
| Uganda | UNPS (LSMS-ISA) | 2009, 2010, 2011, 2013, 2015, 2018, 2019 | parcel (subdivided into plots); season 1 reported |
| Zambia | RALS (IAPRI-MSU) | 2012, 2015, 2019 | field (single land unit) |
| Tanzania (ASC) | Agric. Sample Census (NBS) | 2009, 2019 | household (land by tenure category) |"""

DRAFT=lambda s: f"> **[DRAFT - Jordan]** _{s}_\n"

md=f"""---
title: "Land Rental Market Participation for Sub-Saharan Africa"
subtitle: "Reproducible workflow for survey-derived statistics on land rental market participation"
date: "{today}"
toc: true
toc-depth: 2
geometry: margin=1in
fontsize: 10pt
header-includes:
  - \\usepackage{{float}}
  - \\floatplacement{{figure}}{{H}}
---

<!-- This document is assembled by Report/assemble_report.py from the live project
     outputs. Tables, the figure, and the provenance appendix are auto-generated;
     sections flagged [DRAFT - Jordan] are prose placeholders to be written. Once
     you begin drafting, edit THIS markdown directly and re-render with
     build_report.sh (do NOT re-run assemble_report.py, which overwrites prose). -->

# 1. Overview

{DRAFT("Purpose of this document; relationship to the ARRE manuscript; what the reader gets; one-line reproducibility statement (all numbers regenerate from raw survey files via the public repo).")}

# 2. Coverage

Eight farm-household surveys across Sub-Saharan Africa, seven from the World Bank
LSMS-ISA program and one (Zambia RALS) from IAPRI-MSU.

**Table 1. Survey coverage** - countries, source surveys, survey years, and the spatial unit. The reporting unit is the *parcel*: in some surveys it is subdivided into fields/plots, in others a single land unit.

{COVERAGE}

# 3. Definitions and methods

The unit of analysis is the **parcel** (the tenure-bearing land unit in each
survey; this is the *field* in single-level surveys and the *parcel* above
fields/plots in Ethiopia, Uganda and Malawi). For every parcel we record:

**Table 2. Output variables** - the variables constructed for each unit.

{defs}

**Weighting and inference.** All shares are survey-weighted using each round's
household weight, with the survey design set as `svyset psu [pw=weight],
strata(strata)` where the PSU and stratum are made unique by country x wave;
single-PSU strata are centered. Confidence intervals are design-based (Taylor
linearization). Tables report season 1 (the only season for all countries except
Uganda, which is computed for both and reported for season 1).

{DRAFT("Any additional framing you want on the unit choice, the parcel-vs-field decision, or the weighting approach.")}

# 4. Read before interpreting

{missing}

{share}

**Two further round-specific caveats.** Uganda's 2018 (UNPS7) round used a reduced
panel re-interview: the owned-parcel acquisition item was not administered (so
purchase is missing that round) and area/tenure were re-collected for only ~25% of
parcels. Zambia's 2019 (RALS) release carries only a panel weight (no
cross-sectional weight), so the 2019 endpoint represents the followed panel, not a
fresh cross-section.

# 5. Results

Survey-weighted shares by country and survey year (season 1). A dash (`-`) marks
structurally missing items (question not asked that round; see Section 4).

## 5.1 Share of households with one or more plot

**Table 5.** Share of households with at least one plot that is rented-in, rented-out, purchased, or holds a land certificate, by country and survey year (season 1; survey-weighted). A dash (`-`) denotes an item not collected that round.

{tbl_hh}

## 5.2 Share of plots

**Table 6.** Share of plots that are rented-in, rented-out, purchased, or hold a land certificate, by country and survey year (season 1; survey-weighted). A dash (`-`) denotes an item not collected that round.

{tbl_plot}

## 5.3 Share of farm area (hectares)

**Table 7.** Share of farm area (hectares) that is rented-in, rented-out, purchased, or holds a land certificate, by country and survey year (season 1; survey-weighted). A dash (`-`) denotes an item not collected that round; for rented-out it can also denote that the rented-out parcels carry no measured area (they are uncultivated, so no field area is recorded - e.g. Ethiopia 2019, 2022), making the area share undefined rather than zero.

{tbl_area}

{DRAFT("Interpretation of the three tables - levels and notable cross-country contrasts; how the household / plot / area views differ.")}

# 6. Trends over time

![Figure 1. Plot-level tenure and rental-market shares over time, by country, with 95% confidence bands. Y-axis is scaled per country so within-country trends are legible; levels differ across panels.](figure_trends.png)

![Figure 2. Household-level shares (share of households with at least one plot of each type) over time, by country, with 95% confidence bands. Y-axis is scaled per country, as in Figure 1.](figure_trends_hh.png)

{DRAFT("Do any countries show a pronounced trend once the CIs are taken into account? Emphasize the caveat that waves are not strictly comparable (instrument changes, panel attrition, the redesign breaks flagged in Section 4 and the appendix).")}

# 7. Data sources and reproduction

The repository contains **no microdata**. LSMS-ISA surveys are obtained (free,
with registration) from the World Bank Microdata Library; Zambia RALS is obtained
from IAPRI. After placing the raw files in the expected folder tree, running
`Code/MASTER.do` rebuilds the pooled dataset and `Code/tables_graphs.do` (or
`Code/tables_graphs.py`) regenerates every table and figure here. Full per-survey
file lists are in `DATA_SOURCES.md`.

All code, reference documentation, and the outputs reproduced here are available in
the project's public GitHub repository, <https://github.com/chamb244/ssa-land-rental>.
The repository contains the country-by-country extractors, the pooled-dataset build
(`MASTER.do`), the table and figure generators, this report and its build script, and
the full variable-provenance reference. Code is released under the MIT License and the
accompanying documentation under CC-BY-4.0; the survey microdata themselves are not
redistributed and must be obtained from the providers below.

## Main source file and catalog link, by survey wave

The table gives, for each survey wave, the primary land/tenure roster file the workflow
reads (the complete per-wave file list is in Appendix A). Catalog links are shown where a
stable URL is available; entries marked _(pending)_ can be located in the World Bank
Microdata Library (LSMS-ISA) or, for Zambia, obtained from IAPRI.

**Table 8. Primary source file and data catalog, by survey wave.**

| Country | Year | Main source file | Data catalog |
|---|---|---|---|
| Ethiopia | 2012 | `sect2_pp_w1.dta` | [ESS 2011/12](https://microdata.worldbank.org/index.php/catalog/2053) |
|  | 2014 | `sect2_pp_w2.dta` | [ESS 2013/14](https://microdata.worldbank.org/index.php/catalog/2247) |
|  | 2016 | `sect2_pp_w3.dta` | [ESS 2015/16](https://microdata.worldbank.org/index.php/catalog/2783) |
|  | 2019 | `sect2_pp_w4.dta` | [ESS 2018/19](https://microdata.worldbank.org/index.php/catalog/3823) |
|  | 2022 | `sect2_pp_w5.dta` | [ESS 2021/22](https://microdata.worldbank.org/index.php/catalog/6161) |
| Malawi | 2010 | `ag_mod_d_10.dta` | [IHPS long-term panel](https://microdata.worldbank.org/index.php/catalog/3819) |
|  | 2013 | `ag_mod_d_13.dta` | [IHPS long-term panel](https://microdata.worldbank.org/index.php/catalog/3819) |
|  | 2016 | `ag_mod_b2_16.dta` | [IHPS long-term panel](https://microdata.worldbank.org/index.php/catalog/3819) |
|  | 2019 | `ag_mod_b2_19.dta` | [IHPS long-term panel](https://microdata.worldbank.org/index.php/catalog/3819) |
| Mali | 2014 | `EACIEXPLOI_p1.dta` | [EACI 2014](https://microdata.worldbank.org/index.php/catalog/2583) |
|  | 2017 | `eaci17_s11bp1.dta` | [EACI 2017](https://microdata.worldbank.org/index.php/catalog/3409) |
| Niger | 2011 | `ecvmaas1_p1.dta` | [ECVMA 2011](https://microdata.worldbank.org/index.php/catalog/2050) |
|  | 2014 | `ECVMA2_AS1P1.dta` | [ECVMA 2014](https://microdata.worldbank.org/index.php/catalog/2676) |
| Nigeria | 2011 | `sect11b_plantingw1.dta` | [GHS 2010/11](https://microdata.worldbank.org/index.php/catalog/1002) |
|  | 2013 | `sect11b1_plantingw2.dta` | [GHS 2012/13](https://microdata.worldbank.org/index.php/catalog/1952) |
|  | 2016 | `sect11b1_plantingw3.dta` | [GHS 2015/16](https://microdata.worldbank.org/index.php/catalog/2734) |
|  | 2019 | `sect11b1_plantingw4.dta` | [GHS 2018/19](https://microdata.worldbank.org/index.php/catalog/3557) |
|  | 2023 | `sect11b1_plantingw5.dta` | [GHS-Panel 2023 (W5)](https://microdata.worldbank.org/index.php/catalog/6410) |
| Tanzania | 2009 | `SEC_3A.dta` | [NPS 2008/09](https://microdata.worldbank.org/index.php/catalog/76) |
|  | 2011 | `AG_SEC3A.dta` | [NPS 2010/11](https://microdata.worldbank.org/index.php/catalog/1050) |
|  | 2013 | `AG_SEC_3A.dta` | [NPS 2012/13](https://microdata.worldbank.org/index.php/catalog/2252) |
|  | 2015 | `AG_SEC_3A.dta` (extended + refresh) | [NPS 2014/15](https://microdata.worldbank.org/index.php/catalog/2862) |
|  | 2019 | `AG_SEC_3A.dta` (extended + refresh) | [NPS 2019/20 SDD](https://microdata.worldbank.org/index.php/catalog/3885) |
| Uganda | 2009 | `2009_AGSEC2A.dta` | [UNPS 2009/10](https://microdata.worldbank.org/index.php/catalog/1001) |
|  | 2010 | `AGSEC2A.dta` | [UNPS 2010/11](https://microdata.worldbank.org/index.php/catalog/2166) |
|  | 2011 | `AGSEC2A.dta` | [UNPS 2011/12](https://microdata.worldbank.org/index.php/catalog/2059) |
|  | 2013 | `AGSEC2A.dta` | [UNPS 2013/14](https://microdata.worldbank.org/index.php/catalog/2663) |
|  | 2015 | `AGSEC2A.dta` | [UNPS 2015/16](https://microdata.worldbank.org/index.php/catalog/3460) |
|  | 2018 | `AGSEC2A.dta` | [UNPS 2018/19](https://microdata.worldbank.org/index.php/catalog/3795) |
|  | 2019 | `agsec2a.dta` | [UNPS 2019/20](https://microdata.worldbank.org/index.php/catalog/3902) |
| Zambia | 2012 | `field.dta` | [RALS 2012 (IHSN)](https://catalog.ihsn.org/catalog/7201) |
|  | 2015 | `field.dta` | [RALS 2015 (IHSN)](https://catalog.ihsn.org/catalog/7200) |
|  | 2019 | `field.dta` | request from IAPRI (info@iapri.org.zm) |
| Tanzania (ASC) | 2009 | `R041.DTA` (smallholder) | [ASC 2008/09 (NBS)](https://microdata.nbs.go.tz/index.php/catalog/5) |
|  | 2019 | `R041_LAND_OWNERSHIP.dta` | [ASC 2019/20 (NBS)](https://microdata.nbs.go.tz/index.php/catalog/31) |

# Appendix A. Per-country variable provenance

For every final variable, the exact source file, source variable(s), value-label
codes and construction rule, by country and wave (verified against the raw data).

{appx}
"""

open(OUT,"w",encoding="utf-8").write(md)
print("wrote",OUT,f"({len(md.splitlines())} lines)")
