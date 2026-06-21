/*********************************************************************************
* extract_TZA_ASC.do  -- Tanzania AGRICULTURAL SAMPLE CENSUS (ASC), 2009 & 2019
*                        SMALLHOLDER component.  NON-LSMS (Tanzania NBS).
* Part of ssa-land-rental.  Run via MASTER.do (needs globals set).
*--------------------------------------------------------------------------------
* country label = "Tanzania (ASC)"  -- kept DISTINCT from the NPS series ("Tanzania")
* so the two can be compared side by side.
*
* SOURCE: module R041 (land ownership), smallholder component, one row per
*   household x land-tenure CATEGORY, with the area held under each category:
*     1 Leased / Certificate of ownership | 2 Owned under customary law |
*     3 Bought from others | 4 Rented from others | 5 Borrowed from others |
*     6 Share-cropped from others | 7 Other forms of tenure
*   2009 file R041.DTA   : cat=Q041C1, acres=Q041C2, weight=Wt_adjust,
*                          hh key = region-district-ward-village-hhnumber
*   2019 file R041_LAND_OWNERSHIP.dta : cat=q4_1_c0, acres=q4_1_c2,
*                          weight=finalweight_hh, hh key = HHID
*   strata = district (both); the ASC has no PSU variable (svyset uses strata only).
*
* UNIT: the ASC has NO cultivated-plot unit. We treat each household x category
*   holding (area>0) as a "parcel" (a tenure-homogeneous land holding). Household-
*   and AREA-share statistics are the meaningful outputs; PLOT-level rates are NOT
*   comparable to the LSMS plot tables (these are land-category holdings, not plots)
*   and should be excluded from the plot table.
*
* CONSTRUCTION (verified to reproduce the source do-files):
*   parcel_rentedin    = (category == 4)            "Rented from others"
*        -> set  global asc_sharecrop 1  to also count category 6 (share-cropped in),
*           matching the rent+sharecrop convention used for the LSMS countries.
*   parcel_purchased   = (category == 3)            "Bought from others"  [derived]
*   parcel_certificate = (category == 1)            "Leased / Certificate" [derived]
*   parcel_rentedout   = land-USE module "Area Rented to others" with area>0
*        (R041 records only land held FROM others; rented/lent OUT is in the land-use
*         module R042 (2009, Q042C1==10) / R051_LAND_USE (2019, q5_1_c0==11)). These
*         rented-out holdings are appended as extra parcels (rentedin/purchased/cert = .).
*   parcel_area_ha     = category acres x 0.404686
*   Validated weighted HOUSEHOLD renting-in: 2009 ~10.7% , 2019 ~20.1%; renting-OUT
*   2009 ~2.8%, 2019 ~2.9%.  AREA share rented-in: 2009 ~4.3%, 2019 ~7.8%.
*
* NOTE: smallholder component only (the large-scale-farm component is a separate,
*   much smaller commercial frame and is intentionally excluded for comparability
*   with the smallholder LSMS surveys).
*********************************************************************************/

if "${asc_sharecrop}"=="" global asc_sharecrop 0   // 0 = rented only (matches source do-files)

* ASC raw data live under "${root}/Input data/Tanzania" (the lifted location);
* fall back to the legacy ${Input}/Tanzania if not found there.
local ascbase "${root}/Input data/Tanzania"
capture confirm file "`ascbase'/ASC 09/R041.DTA"
if _rc local ascbase "${Input}/Tanzania"

capture program drop _ascfinal
program define _ascfinal
    label var country          "Country / source"
    label var wave             "ASC year"
    label var year             "Survey year"
    label var season           "Cropping season (single = 1)"
    label var weight           "Household survey weight"
    label var parcel_rentedin    "Land holding rented IN (0/1)"
    label var parcel_rentedout   "Rented OUT (. : not collected in ASC)"
    label var parcel_certificate "Holding leased / under certificate of ownership (0/1)"
    label var parcel_purchased   "Holding bought from others (0/1)"
    label var parcel_area_ha     "Area of holding, ha (acres x 0.404686)"
    label var n_fields           "Number of records aggregated (=1)"
    label var ea_id              "Survey PSU (blank: ASC has no PSU variable)"
    label var strataid           "Survey design stratum (district)"
    capture confirm string variable parcel_id
    if _rc tostring parcel_id, replace force
    capture confirm string variable hh_id
    if _rc tostring hh_id, replace force
    keep country wave year season weight strataid ea_id hh_id parcel_id parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased parcel_area_ha n_fields
    order country wave year season weight strataid ea_id hh_id parcel_id ///
          parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased ///
          parcel_area_ha n_fields
end

forvalues k = 1/2 {
    if `k'==1 {
        local fold "ASC 09"
        local file "R041.DTA"
        local year 2009
        local lc Q041C1
        local ac Q041C2
        local wt Wt_adjust
        local idv region district ward village hhnumber
        local distv district
        local lufile "R042.DTA"                 // land-USE module (rented-out)
        local lucat  Q042C1
        local luac   Q042C2
        local rocode 10                         // "Area Rented to others" (2009 code)
    }
    else {
        local fold "ASC 19"
        local file "R041_LAND_OWNERSHIP.dta"
        local year 2019
        local lc q4_1_c0
        local ac q4_1_c2
        local wt finalweight_hh
        local idv HHID
        local distv district
        local lufile "R051_LAND_USE.dta"        // land-USE module (rented-out)
        local lucat  q5_1_c0
        local luac   q5_1_c2
        local rocode 11                         // "Area Rented to Others" (2019 code)
    }

    di as txt _n "=========  TANZANIA ASC (smallholder)  `year'  ========="

    * ===== (A) OWNERSHIP module R041: rented-IN / purchased / certificate =====
    use "`ascbase'/`fold'/`file'", clear
    duplicates drop `idv' `lc', force
    gen double _ha = `ac' * 0.404686
    keep if _ha>0 & !missing(_ha)               // category holdings with positive area

    * NOTE: egen concat() formats numeric variables with their *display* format.
    * The ASC-2019 HHID is a 14-digit number stored with %10.0g, which concat would
    * truncate to ~4 significant digits and collapse ~30,650 households into ~100
    * groups (inflating household-level shares). Force every numeric id component to a
    * full-precision string before concatenating.
    foreach _v of local idv {
        capture confirm numeric variable `_v'
        if !_rc tostring `_v', replace format(%17.0f)
    }
    egen hh_id     = concat(`idv'), punct("-")
    egen _cat      = concat(`lc')
    gen  parcel_id = hh_id + "-c" + _cat

    gen byte parcel_rentedin   = (`lc'==4)
    if "${asc_sharecrop}"=="1" replace parcel_rentedin = 1 if `lc'==6
    gen byte parcel_purchased  = (`lc'==3)
    gen byte parcel_certificate= (`lc'==1)
    gen byte parcel_rentedout  = 0             // measured from the land-USE module (B)
    gen double parcel_area_ha  = _ha

    gen double weight = `wt'
    egen strataid = group(`distv')
    gen ea_id = ""
    gen int  n_fields = 1
    gen str20 country = "Tanzania (ASC)"
    gen int  wave = `year'
    gen int  year = `year'
    gen byte season = 1
    _ascfinal
    tempfile own`k'
    save `own`k'', replace

    * ===== (B) LAND-USE module: rented-OUT holdings (use category `rocode', area>0) =====
    * R041 records only land held FROM others; land rented/lent OUT is in the land-USE
    * module under "Area Rented to others" (2009 Q042C1==10 ; 2019 q5_1_c0==11).
    use "`ascbase'/`fold'/`lufile'", clear
    duplicates drop `idv' `lucat', force
    gen double _ha = `luac' * 0.404686
    keep if _ha>0 & !missing(_ha) & `lucat'==`rocode'
    foreach _v of local idv {
        capture confirm numeric variable `_v'
        if !_rc tostring `_v', replace format(%17.0f)
    }
    egen hh_id     = concat(`idv'), punct("-")
    gen  parcel_id = hh_id + "-rout"
    gen byte parcel_rentedout  = 1
    gen byte parcel_rentedin   = .             // undefined on a rented-out holding
    gen byte parcel_purchased  = .
    gen byte parcel_certificate= .
    gen double parcel_area_ha  = _ha
    gen double weight = `wt'
    egen strataid = group(`distv')
    gen ea_id = ""
    gen int  n_fields = 1
    gen str20 country = "Tanzania (ASC)"
    gen int  wave = `year'
    gen int  year = `year'
    gen byte season = 1
    _ascfinal
    append using `own`k''
    tempfile asc`k'
    save `asc`k'', replace
}

use `asc1', clear
append using `asc2'
label data "Tanzania ASC (smallholder) 2009 & 2019: household land-holding tenure (built `c(current_date)')"
compress
if "${area_max}"=="" global area_max 40
replace parcel_area_ha = . if parcel_area_ha > ${area_max} & !missing(parcel_area_ha)
save "${Final}/rental_TZA_ASC.dta", replace

*================================================================================
* QC  (household-level renting-in should match the source do-files)
*================================================================================
di as txt _n "================  TANZANIA ASC QC  ================"
tab year
* household-level: collapse to household, max over its holdings
preserve
    collapse (max) parcel_rentedin parcel_rentedout parcel_purchased parcel_certificate (firstnm) weight strataid, by(country year hh_id)
    svyset, clear
    svyset [pw=weight], strata(strataid) singleunit(centered)
    di as txt "-- HOUSEHOLD share (expect rent-in 2009 ~10.7%, 2019 ~20.1%; rent-out ~2.8%/2.9%) --"
    foreach v in parcel_rentedin parcel_rentedout parcel_purchased parcel_certificate {
        svy: mean `v', over(year)
    }
restore
di as txt "-- AREA share rented-in (expect 2009 ~4.3%, 2019 ~7.8%) --"
gen _num = parcel_area_ha*parcel_rentedin
table year [pw=weight], stat(sum _num) stat(sum parcel_area_ha)
drop _num

exit
