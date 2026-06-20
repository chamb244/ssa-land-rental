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
COVERAGE="""| Country | Survey (source) | Waves (years) | Spatial unit |
|---|---|---|---|
| Ethiopia | ESS (LSMS-ISA) | 1-5 (2012-2022) | parcel -> field |
| Malawi | IHPS (LSMS-ISA) | 1-4 (2010-2019) | garden / plot |
| Mali | EACI (LSMS-ISA) | 2014, 2017 | parcelle |
| Niger | ECVMA (LSMS-ISA) | 2011, 2014 | parcelle |
| Nigeria | GHS-Panel (LSMS-ISA) | 1-5 (2011-2023) | plot |
| Tanzania | NPS (LSMS-ISA) | 1-5 (2009-2019) | plot |
| Uganda | UNPS (LSMS-ISA) | 1-5, 7, 8 (2009-2019) | parcel -> plot (season 1 reported) |
| Zambia | RALS (IAPRI-MSU) | 2012, 2015, 2019 | field |"""

DRAFT=lambda s: f"> **[DRAFT - Jordan]** _{s}_\n"

md=f"""---
title: "Land-Tenure and Rental-Market Descriptives for Sub-Saharan Africa"
subtitle: "Reference and results for the *Annual Review of Resource Economics* manuscript"
date: "{today}"
toc: true
toc-depth: 2
geometry: margin=1in
fontsize: 10pt
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

{COVERAGE}

# 3. Definitions and methods

The unit of analysis is the **parcel** (the tenure-bearing land unit in each
survey; this is the *field* in single-level surveys and the *parcel* above
fields/plots in Ethiopia, Uganda and Malawi). For every parcel we record:

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

**Table 1.** Share of households with at least one plot that is rented-in, rented-out, purchased, or holds a land certificate, by country and survey year (season 1; survey-weighted). A dash (`-`) denotes an item not collected that round.

{tbl_hh}

## 5.2 Share of plots

**Table 2.** Share of plots that are rented-in, rented-out, purchased, or hold a land certificate, by country and survey year (season 1; survey-weighted). A dash (`-`) denotes an item not collected that round.

{tbl_plot}

## 5.3 Share of farm area (hectares)

**Table 3.** Share of farm area (hectares) that is rented-in, rented-out, purchased, or holds a land certificate, by country and survey year (season 1; survey-weighted). A dash (`-`) denotes an item not collected that round.

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

{DRAFT("Optional: a sentence pointing readers to the GitHub repo URL and the license.")}

# Appendix A. Per-country variable provenance

For every final variable, the exact source file, source variable(s), value-label
codes and construction rule, by country and wave (verified against the raw data).

{appx}
"""

open(OUT,"w",encoding="utf-8").write(md)
print("wrote",OUT,f"({len(md.splitlines())} lines)")
