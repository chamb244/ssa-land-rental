#!/usr/bin/env bash
# Render the consolidated report to PDF + Word from the Markdown source.
# (Run assemble_report.py first if you need to refresh tables/figure/appendix.)
set -e
cd "$(dirname "$0")"
SRC=consolidated_report.md

# PDF (xelatex handles the wide reference tables better than pdflatex).
# Sanitize a few non-ASCII glyphs missing from the default LaTeX font into a
# temp copy so the build needs no special fonts (the GitHub .md keeps the arrows).
sed -e 's/\xe2\x86\x94/<->/g' -e 's/\xe2\x86\x92/->/g' \
    -e 's/\xe2\x89\xa5/>=/g' -e 's/\xe2\x89\xa4/<=/g' \
    -e 's/\xe2\x89\x88/~/g' -e 's/\xc2\xb2/2/g' -e 's/\xce\xa3/Sum/g' \
    -e 's/\xe2\x88\x88/ in /g' -e 's/\xc3\x97/x/g' "$SRC" > .pdf_src.md
pandoc .pdf_src.md -o consolidated_report.pdf --pdf-engine=xelatex --toc \
  -V geometry:margin=1in -V fontsize=10pt -V colorlinks=true || \
  echo "PDF build failed (is a LaTeX engine installed?)"
rm -f .pdf_src.md

# Word
pandoc "$SRC" -o consolidated_report.docx --toc

echo "Built: consolidated_report.pdf, consolidated_report.docx"
