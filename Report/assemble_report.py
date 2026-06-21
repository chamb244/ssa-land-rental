#!/usr/bin/env python3
"""
Refresh the GENERATED parts of consolidated_report.md *IN PLACE*, preserving all
authored prose. This script is SAFE TO RE-RUN: it never overwrites narrative text.

consolidated_report.md is now the authored source of truth for the report. This
script only swaps out the machine-generated blocks inside it:

  REFRESHED FROM Output/Tables/*.csv (regenerate with tables_graphs.py / .do):
    - Table 5  household share        (table_hh_share.csv)
    - Table 6  plot share             (table_plot_share.csv)
    - Table 7  area share             (table_area_share.csv)

  REFRESHED FROM Reference/variable_provenance.md:
    - Table 3  structurally-missing variables
    - Table 4  sharecropping coverage
    - Appendix A  per-country provenance (everything from "## ETHIOPIA" to EOF)

  COPIED next to the report:
    - figure_trends.png, figure_trends_hh.png  (from Output/Figures/)

PRESERVED (authored directly in consolidated_report.md - edit them there):
    - all prose and section structure
    - Table 1 (coverage), Table 2 (output variables), Table 8 (source catalog)

Typical workflow:
    1. edit prose in consolidated_report.md  (and provenance in variable_provenance.md)
    2. re-run MASTER.do, then tables_graphs.py/.do  (refreshes the CSVs + figures)
    3. python assemble_report.py               (syncs the generated blocks, in place)
    4. bash build_report.sh                     (renders PDF + Word)

NOTE: because the report is now authored in the .md, this script edits the existing
file rather than regenerating it from scratch - it will not recreate the document if
it is deleted (recover it from version control instead).
"""
import os, csv, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
TAB  = f"{ROOT}/Output/Tables"
FIG  = f"{ROOT}/Output/Figures"
PROV = f"{ROOT}/Reference/variable_provenance.md"
OUT  = f"{HERE}/consolidated_report.md"

# ---- helpers ---------------------------------------------------------------
def csv_to_md(path):
    rows = list(csv.reader(open(path, encoding="utf-8")))
    head, body = rows[0], rows[1:]
    out = ["| " + " | ".join(head) + " |", "|" + "|".join(["---"] * len(head)) + "|"]
    for r in body:
        out.append("| " + " | ".join(c if c != "" else "  " for c in r) + " |")
    return "\n".join(out)

def first_table(text):
    """First contiguous markdown table (run of lines starting with '|') in text."""
    buf = []; started = False
    for l in text.split("\n"):
        if l.lstrip().startswith("|"):
            buf.append(l.rstrip()); started = True
        elif started:
            break
    return "\n".join(buf)

def between(t, a, b):
    i = t.index(a)
    return t[i:t.index(b, i + len(a))]

# ---- pull fresh generated content ------------------------------------------
share_tables = [csv_to_md(f"{TAB}/table_hh_share.csv"),     # Table 5 (5.1)
                csv_to_md(f"{TAB}/table_plot_share.csv"),    # Table 6 (5.2)
                csv_to_md(f"{TAB}/table_area_share.csv")]    # Table 7 (5.3)

prov = open(PROV, encoding="utf-8").read()
missing_tbl = first_table(between(prov, "## Missing by design", "## Rented-in: sharecropping"))
share_tbl   = first_table(between(prov, "## Rented-in: sharecropping", "## ETHIOPIA"))
appx = prov[prov.index("## ETHIOPIA"):]
appx = appx[:appx.index("*Built from")].rstrip()

# ---- rewrite consolidated_report.md in place -------------------------------
lines = open(OUT, encoding="utf-8").read().split("\n")
out = []; i = 0; n = len(lines); si = 0; seen_appendix = False
while i < n:
    l = lines[i]
    if l.strip().startswith("# Appendix A"):
        seen_appendix = True
    # Appendix A: replace everything from the first per-country heading to EOF
    if seen_appendix and l.strip().startswith("## ETHIOPIA"):
        out.append(appx)
        break
    hdr = l.lstrip()
    repl = None
    if hdr.startswith("| Country | Year | Rented-in") and si < len(share_tables):
        repl = share_tables[si]; si += 1
    elif hdr.startswith("| Country | Variable | Missing year"):
        repl = missing_tbl
    elif hdr.startswith("| Country | Sharecropping"):
        repl = share_tbl
    if repl is not None:
        out.append(repl)
        i += 1
        while i < n and lines[i].lstrip().startswith("|"):   # skip old table
            i += 1
        continue
    out.append(l); i += 1

open(OUT, "w", encoding="utf-8").write("\n".join(out).rstrip("\n") + "\n")

# ---- copy figures next to the report ---------------------------------------
shutil.copyfile(f"{FIG}/trends_by_country_plot.png", f"{HERE}/figure_trends.png")
shutil.copyfile(f"{FIG}/trends_by_country_hh.png",   f"{HERE}/figure_trends_hh.png")

print(f"Refreshed Tables 3-7 + Appendix A + figures in {OUT} "
      f"({si} share tables, missing/sharecropping, appendix).")
