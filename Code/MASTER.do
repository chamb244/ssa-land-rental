/*********************************************************************************
* LSMS-ISA Harmonised Panel - SLIM RENTAL / TENURE EXTRACTOR
* Created: 2026-06-15 (JC)
*--------------------------------------------------------------------------------
* Purpose: Build a lightweight, plot-level dataset of land-tenure descriptives,
*          country by country, WITHOUT running the full harmonisation pipeline.
*
* Target variables (per parcel):
*     parcel_rentedin    - parcel rented/sharecropped IN   (0/1)
*     parcel_rentedout   - parcel rented/sharecropped OUT  (0/1)
*     parcel_certificate - parcel has certificate/document (0/1; . where not asked)
*     parcel_purchased   - parcel acquired through PURCHASE (0/1; . where not asked)
*     parcel_area_ha     - cultivated parcel area, ha (field GPS, else self-reported)
*
* Identifiers carried on every row:
*     country  wave  year  weight   + household / plot / parcel IDs
*
* NOTE on units: rental / certificate / purchase are PARCEL-level attributes in
* the raw surveys. Area is FIELD(plot)-level. This extractor produces a
* PLOT(field)-level file with the parcel attributes mapped down onto plots
* (m:1 on holder_id parcel_id), matching the structure of the published
* Plot_dataset. Aggregate to parcel or household level for participation rates.
*********************************************************************************/

cap log close _all
clear all
clear matrix
macro drop _all
set more off
set maxvar 10000
set type double
set seed 12345

*--------------------------------------------------------------------------------
* PATHS  -- EDIT THESE for your machine.
* Raw input data is REUSED from the existing Reproduction_v2 tree (not copied),
* so we do not duplicate the ~17 MB of survey inputs.
*--------------------------------------------------------------------------------
* Forward slashes work in Stata on both Mac and Windows. On Windows you can
* alternatively set: global root "C:/DATA/LSMS-ISA-harmonised-dataset-on-agricultural-productivity-and-welfare"
* Project root. Preferred home: a top-level "SSA-pooled-survey-data" umbrella (sibling to
* the LSMS-ISA folder) that holds "Input data/" beside the "ssa-land-rental" code repo.
* Falls back to the legacy location, so runs work before AND after you move things.
global root "/Users/jchamberlin/Library/CloudStorage/Dropbox/SSA-pooled-survey-data"
capture confirm file "${root}/ssa-land-rental/Code/MASTER.do"
if _rc global root "/Users/jchamberlin/Library/CloudStorage/Dropbox/LSMS-ISA-harmonised-dataset-on-agricultural-productivity-and-welfare"

global Do     "${root}/ssa-land-rental/Code"
global Temp   "${root}/ssa-land-rental/Output/Temp"
global Final  "${root}/ssa-land-rental/Output/Final"

* Raw survey inputs (never in git). Prefer "${root}/Input data"; else the legacy path.
global Input  "${root}/Input data"
capture confirm file "${Input}/Ethiopia/ESS 11/sect2_pp_w1.dta"
if _rc global Input "${root}/Reproduction_v2/Folder_structures/Input data"

* Plot-area top-code: parcel_area_ha above this (ha) is treated as a data-entry
* error and set missing. Smallholder parcels rarely exceed this; the raw data carry
* unit-error outliers (e.g. tens of thousands of "acres") that otherwise inflate means.
global area_max 40

*--------------------------------------------------------------------------------
* Packages used (for convenience / QC; core estimation uses base Stata)
*--------------------------------------------------------------------------------
foreach pkg in mdesc fre distinct {
    capture which `pkg'
    if _rc == 111 ssc install `pkg'
}

*--------------------------------------------------------------------------------
* Country-by-country extractors.
* ETH is the validated template; uncomment others as they are built & checked.
*--------------------------------------------------------------------------------
do "${Do}/extract_ETH.do"
do "${Do}/extract_MWI.do"
do "${Do}/extract_MLI.do"
do "${Do}/extract_NER.do"
do "${Do}/extract_NGA.do"
do "${Do}/extract_TZA.do"
do "${Do}/extract_UGA.do"
do "${Do}/extract_ZMB.do"      // non-LSMS (Zambia RALS 2012/2015/2019)
do "${Do}/extract_TZA_ASC.do"  // non-LSMS (Tanzania Agric. Sample Census 2009/2019, smallholder)

*--------------------------------------------------------------------------------
* Append all country files into one harmonised rental/tenure dataset
*--------------------------------------------------------------------------------
clear
foreach c in ETH MWI MLI NER NGA TZA UGA ZMB TZA_ASC {
    capture confirm file "${Final}/rental_`c'.dta"
    if _rc == 0 append using "${Final}/rental_`c'.dta"
}
save "${Final}/rental_tenure_ALL.dta", replace
