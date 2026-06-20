/*********************************************************************************
* audit_TZA_2015.do  --  STANDALONE verification of the 5 tenure variables for
*                        TANZANIA, NPS wave 4 (2014/15).
*--------------------------------------------------------------------------------
* PURPOSE. Reconstruct each variable directly from the RAW NPS4 files and SHOW the
* raw source variable, its value labels, and a cross-tab against the constructed
* 0/1 flag, so the mapping can be eyeballed against the questionnaire. This script
* is fully self-contained: it sets NO globals and does NOT call MASTER.do. The only
* thing to edit is the `raw' path on the line below.
*
* NPS4 ships as TWO subsamples - an EXTENDED panel and a REFRESH cross-section -
* in folders "NPS 14 - extended" and "NPS 14 - refresh"; both are appended here.
*
* WHAT TO EXPECT (design-weighted, plot level; matches the published table):
*     rented-in 0.063 | rented-out 0.007 | purchased 0.247 | certificate 0.143
*
* SOURCES (NPS4, both subsamples):
*   ag_sec_3a  (plot tenure/use module): ag3a_25 acquisition, ag3a_03 use,
*              ag3a_28a legal-certificate type, ag3a_28d other ownership documents
*   ag_sec_2a  (plot roster): ag2a_09 GPS acres, ag2a_04 self-reported acres
*   hh_sec_a   (cover): y4_weights, strataid, clusterid
*   plot key = y4_hhid + plotnum
*
* CONSTRUCTION (verified; same as extract_TZA.do, "late"/C scheme):
*   rented_in    = inlist(ag3a_25, 7, 8)         7 RENTED IN, 8 SHARED-RENT (sharecrop)
*   purchased    = (ag3a_25 == 5)                5 PURCHASED
*   owned        = inlist(ag3a_25, 1,2,5,9)      inheritance/gift/purchase/shared-own
*   rented_out   = (ag3a_03 == 2)                2 RENTED OUT (plot-use question)
*   certificate  = inlist(ag3a_28a,1,2)          1 granted right of occupancy, 2 CCRO
*                  OR inrange(ag3a_28d,1,5)      semi-formal docs (purchase agreement,
*                                                inheritance/allocation letter, gov doc)
*                  ; missing if ag3a_28a missing ; set 0 for non-owned plots
*   *** VERIFY: certificate mixes a FORMAL certificate (28a in {1,2}) with semi-formal
*       DOCUMENTS (28d in {1..5}). Decide whether 28d should count. ***
*
* AREA: GPS where measured (ag2a_09), else self-reported (ag2a_04); acres x 0.404686.
*********************************************************************************/

clear all
set more off
set type double

*--- EDIT THIS ONE LINE: folder containing "NPS 14 - extended" and "NPS 14 - refresh"
local raw "/Users/jchamberlin/Library/CloudStorage/Dropbox/LSMS-ISA-harmonised-dataset-on-agricultural-productivity-and-welfare/Reproduction_v2/Folder_structures/Input data/Tanzania"

local subs `""NPS 14 - extended" "NPS 14 - refresh""'

*================================================================================
* (A) TENURE / USE module  (ag_sec_3a), appended across the two subsamples
*================================================================================
clear
tempfile ten
save `ten', emptyok replace
foreach s of local subs {
    use y4_hhid plotnum ag3a_03 ag3a_25 ag3a_28a ag3a_28d ///
        using "`raw'/`s'/ag_sec_3a.dta", clear
    gen str20 subsample = "`s'"
    append using `ten'
    save `ten', replace
}
use `ten', clear
di as result _n "*** N plot-tenure records (both subsamples): " _N " ***"

*--- RENTED-IN  <- ag3a_25 (codes 7,8) -----------------------------------------
di as txt _n "{hline 72}" _n "  RENTED-IN  <- ag3a_25 'How was this plot acquired?'  (7,8)" _n "{hline 72}"
tab ag3a_25, m
gen byte rentedin = inlist(ag3a_25,7,8)
label var rentedin "parcel_rentedin (constructed)"
di as txt _n ">> cross-tab: source x constructed (confirm only 7,8 -> 1)"
tab ag3a_25 rentedin, m

*--- PURCHASED  <- ag3a_25 (code 5) --------------------------------------------
di as txt _n "{hline 72}" _n "  PURCHASED  <- ag3a_25  (5 = PURCHASED)" _n "{hline 72}"
gen byte purchased = (ag3a_25==5)
label var purchased "parcel_purchased (constructed)"
tab ag3a_25 purchased, m

*--- RENTED-OUT  <- ag3a_03 (code 2) -------------------------------------------
di as txt _n "{hline 72}" _n "  RENTED-OUT  <- ag3a_03 'How did you use this plot...'  (2 = RENTED OUT)" _n "{hline 72}"
tab ag3a_03, m
gen byte rentedout = (ag3a_03==2)
label var rentedout "parcel_rentedout (constructed)"
tab ag3a_03 rentedout, m

*--- CERTIFICATE  <- ag3a_28a (1,2) / ag3a_28d (1-5) ; 0 if not owned -----------
di as txt _n "{hline 72}" _n "  CERTIFICATE  <- ag3a_28a (1,2 formal) OR ag3a_28d (1-5 semi-formal)" _n "{hline 72}"
gen byte owned = inlist(ag3a_25,1,2,5,9)
di as txt ">> ag3a_28a  (legal certificate type)"
tab ag3a_28a, m
di as txt ">> ag3a_28d  (other ownership/legal documents)"
tab ag3a_28d, m
gen byte certificate = inlist(ag3a_28a,1,2)
replace certificate = 1 if inrange(ag3a_28d,1,5)
replace certificate = . if mi(ag3a_28a)
replace certificate = 0 if owned==0
label var certificate "parcel_certificate (constructed)"
di as txt _n ">> cross-tab: ag3a_28a x constructed (note 28d and 'owned' also feed it)"
tab ag3a_28a certificate, m

collapse (max) rentedin rentedout purchased certificate, by(y4_hhid plotnum)
tempfile tenure
save `tenure', replace

*================================================================================
* (B) AREA  (ag_sec_2a): GPS else self-reported, acres -> ha
*================================================================================
clear
tempfile arf
save `arf', emptyok replace
foreach s of local subs {
    use y4_hhid plotnum ag2a_04 ag2a_09 using "`raw'/`s'/ag_sec_2a.dta", clear
    append using `arf'
    save `arf', replace
}
use `arf', clear
gen double area_ha = ag2a_09 * 0.404686
replace area_ha = . if area_ha<=0
replace area_ha = ag2a_04 * 0.404686 if missing(area_ha)
di as txt _n "{hline 72}" _n "  AREA (ha)  <- ag2a_09 GPS acres, else ag2a_04 self-reported, x 0.404686" _n "{hline 72}"
summarize area_ha, detail
collapse (sum) area_ha, by(y4_hhid plotnum)
tempfile area
save `area', replace

*================================================================================
* (C) WEIGHTS / DESIGN  (hh_sec_a)
*================================================================================
clear
tempfile cvf
save `cvf', emptyok replace
foreach s of local subs {
    use y4_hhid y4_weights strataid clusterid using "`raw'/`s'/hh_sec_a.dta", clear
    append using `cvf'
    save `cvf', replace
}
use `cvf', clear
duplicates drop y4_hhid, force
tempfile cover
save `cover', replace

*================================================================================
* (D) ASSEMBLE + design-weighted shares (compare to expected)
*================================================================================
use `tenure', clear
merge 1:1 y4_hhid plotnum using `area',  keep(master match) nogen
merge m:1 y4_hhid        using `cover', keep(master match) nogen

svyset clusterid [pw=y4_weights], strata(strataid) singleunit(centered)

di as result _n "{hline 72}"
di as result "  WEIGHTED PLOT-LEVEL SHARES   (expected: rin .063  rout .007  pur .247  cert .143)"
di as result "{hline 72}"
svy: mean rentedin rentedout purchased certificate
di as txt _n "  parcel area (ha):"
tabstat area_ha [aw=y4_weights], stat(mean p50 n) format(%7.3f)

exit
