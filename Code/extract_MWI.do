/*********************************************************************************
* extract_MWI.do  -- Malawi, IHS repeated CROSS-SECTIONS  -- PARCEL-LEVEL
* Part of ssa-land-rental.  Run via MASTER.do (needs globals set).
*--------------------------------------------------------------------------------
* SOURCE: the Integrated Household Survey (IHS) nationally-representative
* cross-sections (NOT the IHPS panel). Three rounds with land data:
*     IHS3 2010/11   (folder "IHS3 2010", Full_Sample)   plot-level tenure (ag_mod_d)
*     IHS4 2016/17   (folder "IHS4 2016")                 garden-level tenure (ag_mod_b2)
*     IHS5 2019/20   (folder "IHS5 2019")                 garden-level tenure (ag_mod_b2)
* There is no IHS round in 2013, so the Malawi series is 2010/2016/2019. These are
* independent cross-sections (no panel attrition), each with its own cross-sectional
* household weight (hh_wgt); household id = case_id.
*
* UNIT = PARCEL: the cultivated PLOT in 2010 (ag_mod_d), the GARDEN in 2016/2019
* (ag_mod_b2, with plot areas in ag_mod_c summed to the garden). Tenure is mapped
* onto these units; area is GPS where measured, else self-reported (acres -> ha).
*
* CODES (verified against the raw value labels):
*  2010 (ag_d03, "how acquired"): 1 granted | 2 inherited | 3 bride price |
*       4 purchased w/ title | 5 purchased no title | 6 leasehold | 7 rent short-term |
*       8 farming as tenant | 9 borrowed free | 10 moved in w/o permission
*     -> rented_in = inlist(6,7,8); purchased = inlist(4,5); rent-out via ag_d19a-d (>0)
*       certificate not collected in 2010 -> .
*  2016 (ag_b203, same acquisition scheme; ag_b204_1 title doc 1/2/3 = has title):
*     -> rented_in = inlist(ag_b203,6,7,8); purchased = (ag_b203==4);
*        certificate = inlist(ag_b204_1,1,2,3); rent-out via ag_b217a (>0, cash received)
*  2019 (RESTRUCTURED - no acquisition-method or title question on the garden module):
*     -> rented_in  = (ag_b209a>0) | (ag_b208b>0)   rent PAID in cash / in output (sharecrop)
*        rented_out = (ag_b217a>0) | !mi(ag_b216a)   rent RECEIVED in cash / in output
*        purchased = . ; certificate = .   (not collected this round)
*
* Single agricultural season -> season = 1.
*********************************************************************************/

capture program drop _mwifinal
program define _mwifinal
    label var country          "Country"
    label var wave             "IHS round"
    label var year             "Survey year"
    label var season           "Cropping season (single = 1)"
    label var weight           "Household cross-sectional weight (hh_wgt)"
    label var parcel_rentedin    "Parcel rented/sharecropped IN (0/1)"
    label var parcel_rentedout   "Parcel rented/sharecropped OUT (0/1)"
    label var parcel_certificate "Parcel has a title/document (0/1; . if not asked)"
    label var parcel_purchased   "Parcel acquired through purchase (0/1; . if not asked)"
    label var parcel_area_ha     "Parcel area, ha (GPS, else self-reported)"
    label var n_fields           "Number of plots aggregated to the parcel"
    label var ea_id              "Enumeration area (survey PSU)"
    label var strataid           "Survey design stratum"
    capture confirm string variable parcel_id
    if _rc tostring parcel_id, replace force
    capture confirm string variable hh_id
    if _rc tostring hh_id, replace force
    capture confirm variable season
    if _rc gen byte season = 1
    keep country wave year season weight strataid ea_id hh_id parcel_id parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased parcel_area_ha n_fields
    order country wave year season weight strataid ea_id hh_id parcel_id ///
          parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased ///
          parcel_area_ha n_fields
end

local mwiroot "${Input}/Malawi"

forvalues k = 1/3 {

    if `k'==1 {              // IHS3 2010 (plot-level, pattern D)
        local wv 1
        local year 2010
        local pattern D
        local agdir "`mwiroot'/IHS3 2010/MWI_2010_IHS-III_v01_M_STATA8/Full_Sample/Agriculture"
        local hhdir "`mwiroot'/IHS3 2010/MWI_2010_IHS-III_v01_M_STATA8/Full_Sample/Household"
    }
    else if `k'==2 {         // IHS4 2016 (garden-level, pattern B)
        local wv 2
        local year 2016
        local pattern B
        local agdir "`mwiroot'/IHS4 2016/MWI_2016_IHS-IV_v04_M_STATA14/agriculture"
        local hhdir "`mwiroot'/IHS4 2016/MWI_2016_IHS-IV_v04_M_STATA14/household"
    }
    else if `k'==3 {         // IHS5 2019 (garden-level, pattern B, restructured)
        local wv 3
        local year 2019
        local pattern B
        local agdir "`mwiroot'/IHS5 2019/MWI_2019_IHS-V_v06_M_Stata"
        local hhdir "`mwiroot'/IHS5 2019/MWI_2019_IHS-V_v06_M_Stata"
    }

    di as txt _n "=================  MALAWI  IHS  `year'  (pattern `pattern')  ================="

    *==========================================================================
    * (0) HOUSEHOLD ATTRIBUTES from cover: weight, ea_id, strataid
    *==========================================================================
    use "`hhdir'/hh_mod_a_filt.dta", clear
    gen double weight = hh_wgt
    capture confirm variable ea_id
    if _rc gen ea_id = ""
    capture confirm variable region
    if !_rc {
        capture confirm variable reside
        if !_rc egen strataid = group(region reside)
        else    egen strataid = group(region)
    }
    else gen strataid = .
    keep case_id weight ea_id strataid
    duplicates drop
    bys case_id (weight): keep if _n==1
    tempfile hhattr
    save `hhattr', replace

    *==========================================================================
    * (A) AREA  (ag_mod_c, plot-level; acres -> ha; GPS else self-reported)
    *==========================================================================
    use "`agdir'/ag_mod_c.dta", clear
    gen double area_self_reported = ag_c04a * 0.404686
    capture replace area_self_reported = ag_c04a          if ag_c04b==2   // already ha
    capture replace area_self_reported = ag_c04a * 0.0001 if ag_c04b==3   // m^2 -> ha
    gen double plot_area_GPS = ag_c04c * 0.404686
    replace plot_area_GPS = . if plot_area_GPS<=0
    gen double plot_area_ha = plot_area_GPS
    replace plot_area_ha = area_self_reported if missing(plot_area_ha)

    if "`pattern'"=="D" {
        rename ag_c00 unit
        collapse (sum) parcel_area_ha = plot_area_ha (count) n_fields = plot_area_ha, by(case_id unit)
    }
    else {
        collapse (sum) parcel_area_ha = plot_area_ha (count) n_fields = plot_area_ha, by(case_id gardenid)
    }
    tempfile area
    save `area', replace

    *==========================================================================
    * (B) TENURE  (base = every tenure record)
    *==========================================================================
    if "`pattern'"=="D" {
        use "`agdir'/ag_mod_d.dta", clear
        rename ag_d00 unit
        gen byte parcel_rentedin  = inlist(ag_d03,6,7,8)
        gen byte parcel_purchased = inlist(ag_d03,4,5)
        egen _rout = rowmax(ag_d19a ag_d19b ag_d19c ag_d19d)
        gen byte parcel_rentedout = (_rout>0) & !mi(_rout)
        gen byte parcel_certificate = .                 // not collected in 2010
        collapse (max) parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased, by(case_id unit)
        merge 1:1 case_id unit using `area', keep(master match) nogen
        egen parcel_id = concat(case_id unit), punct("-")
    }
    else {
        use "`agdir'/ag_mod_b2.dta", clear
        if `wv'==2 {                                     // IHS4 2016 (acquisition + title)
            gen byte parcel_rentedin  = inlist(ag_b203,6,7,8)
            gen byte parcel_purchased = (ag_b203==4)
            gen byte parcel_certificate = inlist(ag_b204_1,1,2,3) if !mi(ag_b204_1)
            gen byte parcel_rentedout = (ag_b217a>0) & !mi(ag_b217a)
        }
        else {                                           // IHS5 2019 (restructured)
            capture confirm variable ag_b208b
            if _rc gen ag_b208b = .
            gen byte parcel_rentedin  = ((ag_b209a>0) & !mi(ag_b209a)) | ((ag_b208b>0) & !mi(ag_b208b))
            gen byte parcel_rentedout = ((ag_b217a>0) & !mi(ag_b217a)) | !mi(ag_b216a)
            gen byte parcel_purchased   = .
            gen byte parcel_certificate = .
        }
        collapse (max) parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased, by(case_id gardenid)
        merge 1:1 case_id gardenid using `area', keep(master match) nogen
        egen parcel_id = concat(case_id gardenid), punct("-")
    }
    replace n_fields = 0 if missing(n_fields)

    *==========================================================================
    * (C) weights / identifiers
    *==========================================================================
    merge m:1 case_id using `hhattr', keep(master match) keepusing(weight ea_id strataid) nogen
    gen str20 country = "Malawi"
    gen int  wave  = `wv'
    gen int  year  = `year'
    gen byte season = 1
    rename case_id hh_id

    _mwifinal
    tempfile mwi`k'
    save `mwi`k'', replace
}

*================================================================================
* APPEND rounds
*================================================================================
use `mwi1', clear
append using `mwi2'
append using `mwi3'
label data "Malawi IHS cross-sections (2010/2016/2019): parcel-level rental/tenure (built `c(current_date)')"
compress
if "${area_max}"=="" global area_max 40
replace parcel_area_ha = . if parcel_area_ha > ${area_max} & !missing(parcel_area_ha)
save "${Final}/rental_MWI.dta", replace

*================================================================================
* QC  (expect household renting-in ~10% all rounds)
*================================================================================
di as txt _n "================  MALAWI IHS QC  ================"
tab year
egen _psu   = group(wave ea_id)
egen _strat = group(wave strataid)
svyset _psu [pw=weight], strata(_strat) singleunit(centered)
foreach v in parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased {
    di as txt _n ">> `v'"
    capture svy: mean `v', over(year)
    if _rc di as error "   (not estimable)"
}
table year, stat(mean parcel_area_ha) stat(p50 parcel_area_ha) stat(count parcel_area_ha) nformat(%7.3f)

exit
