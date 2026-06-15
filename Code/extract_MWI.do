/*********************************************************************************
* extract_MWI.do  -- Malawi (IHPS waves 1-4)  -- PARCEL-LEVEL
* Part of Reproduction_rental_260615.  Run via MASTER.do (needs globals set).
* Paths use forward slashes (work in Stata on Mac/Windows/Linux).
*--------------------------------------------------------------------------------
* SOURCE: the four-wave IHPS *panel* release MWI_2010-2019_IHPS_v06, extracted flat
* (one folder, files year-suffixed _10/_13/_16/_19). All four waves point at:
*   ${Input}/Malawi/IHPS_panel_v6/MWI_2010-2019_IHPS_v06_M_Stata
* (Edit `mwidir` below if your extraction path differs.)
*
* UNIT = PARCEL, but the survey's land unit CHANGED across waves:
*   waves 1-2 (2010/2013): tenure asked at the PLOT level (module ag_mod_d, id ag_d00);
*                          there is no "garden" grouping. parcel := plot.
*   waves 3-4 (2016/2019): tenure asked at the GARDEN level (module ag_mod_b2, gardenid);
*                          plots nest within gardens. parcel := garden; area summed
*                          from the garden's plots.
* Treat cross-wave levels of area / counts with this structural change in mind.
*
* OUTPUT (per parcel): parcel_rentedin parcel_rentedout parcel_certificate
*   parcel_purchased parcel_area_ha n_fields + country wave year weight
*   strataid ea_id hh_id parcel_id
*
* CODES (verified against the raw value labels):
*   Acquisition ag_d03 (w1-2) / ag_b203 (w3) "How acquired?":
*     1 granted | 2 inherited | 3 bride price | 4 purchased(w/title) |
*     5 purchased(no title; w1-2 only) | 6 leasehold | 7 rent short-term |
*     8 farming as a tenant | 9 borrowed free | 10 moved in | 11 other |
*     (w3+) 12 allocated by family | 13 gift from non-HH.
*   -> rented-in   = acq in {6,7,8}        (leasehold / rent / tenant)
*   -> purchased   = acq in {4,5}
*   Rented-OUT = household received rent for the plot/garden
*     w1-2: ag_d19a-d (cash/in-kind received / still to receive)
*     w3  : ag_b219a-d
*     w4  : explicit flag ag_brentedout==1 ("received output as rent"), or ag_b219a-d
*   Certificate: w2 ag_d03_1 (title y/n); w3 ag_b204_1 (codes 1-3 = yes);
*                w1 not asked (.); w4 not asked (.)
*
* WAVE 4 (2019) is structurally different: the categorical "how acquired" question
* was DROPPED (only "from whom" / "year" remain). Therefore:
*   - parcel_purchased   = . (missing; not measurable)
*   - parcel_certificate = . (no title/document question)
*   - parcel_rentedin    = ag_brentedin==1 (gave output as rent) OR paid the owner
*                          (ag_b211a/b > 0)  -- payment-based proxy.
*
* DECISIONS / CAVEATS to confirm:
*   - "rented-in" excludes "borrowed for free" (code 9) - non-market access.
*   - "rented-out" relies on positive rent received (no clean yes/no gate in w1-3).
*   - Plot area = GPS where measured, else self-reported (deterministic; the
*     published pipeline model-imputes missing GPS area, which we drop for
*     cross-language reproducibility). Tenure variables are unaffected.
*   - strataid: waves 1-2 use the baseline `stratum` (region x urban/rural);
*     waves 3-4 build group(region reside) (their cover has no `stratum`).
*   - Year map 2010/2013/2016/2019 follows the IHPS rounds; the shocks do-file
*     labeled w3/w4 as 2017/2020 - adjust `year` below if you prefer that.
*********************************************************************************/

local mwidir "${Input}/Malawi/IHPS_panel_v6/MWI_2010-2019_IHPS_v06_M_Stata"

capture program drop _mwifinal
program define _mwifinal
    label var country          "Country"
    label var wave             "Survey wave"
    label var year             "Survey year"
    label var weight           "Household survey weight"
    label var parcel_rentedin    "Parcel rented/sharecropped IN (0/1)"
    label var parcel_rentedout   "Parcel rented OUT (0/1)"
    label var parcel_certificate "Parcel has certificate/title (0/1; . if not asked)"
    label var parcel_purchased   "Parcel acquired through purchase (0/1; . if not asked)"
    label var parcel_area_ha     "Cultivated parcel area, ha (field GPS, else self-reported)"
    label var n_fields           "Number of cultivated fields on parcel"
    label var ea_id              "Enumeration area (survey PSU)"
    label var strataid           "Survey design stratum"
    order country wave year weight strataid ea_id hh_id parcel_id ///
          parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased ///
          parcel_area_ha n_fields
end

forvalues w = 1/4 {

    if `w'==1 {
        local hhid case_id
        local year 2010
        local wtvar hh_wgt
        local cover hh_mod_a_filt_10.dta
        local distvar hh_a01
        local cfile ag_mod_c_10.dta
        local dfile ag_mod_d_10.dta
        local peren ""
        local pattern D
    }
    else if `w'==2 {
        local hhid y2_hhid
        local year 2013
        local wtvar panelweight
        local cover hh_mod_a_filt_13.dta
        local distvar district
        local cfile ag_mod_c_13.dta
        local dfile ag_mod_d_13.dta
        local peren ag_mod_o2_13.dta
        local pattern D
    }
    else if `w'==3 {
        local hhid y3_hhid
        local year 2016
        local wtvar panelweight_2016
        local cover hh_mod_a_filt_16.dta
        local distvar district
        local cfile ag_mod_c_16.dta
        local bfile ag_mod_b2_16.dta
        local peren ag_mod_o2_16.dta
        local pattern B
    }
    else if `w'==4 {
        local hhid y4_hhid
        local year 2019
        local wtvar panelweight_2019
        local cover hh_mod_a_filt_19.dta
        local distvar district
        local cfile ag_mod_c_19.dta
        local bfile ag_mod_b2_19.dta
        local peren ag_mod_o2_19.dta
        local pattern B
    }

    di as txt _n "=================  MALAWI  wave `w'  (`year', pattern `pattern')  ================="

    *==========================================================================
    * (0) HOUSEHOLD ATTRIBUTES from cover: weight, ea_id, strataid, district
    *==========================================================================
    use "`mwidir'/`cover'", clear
    capture confirm variable ea_id
    if _rc gen ea_id = ""
    rename `wtvar' weight
    if inlist(`w',1,2) {
        capture confirm variable stratum
        if !_rc  rename stratum strataid
        else     egen strataid = group(region reside)
    }
    else {
        egen strataid = group(region reside)
    }
    keep `hhid' weight ea_id strataid
    duplicates drop
    bys `hhid' (weight): keep if _n==1     // one row per household
    tempfile hhattr
    save `hhattr', replace

    *==========================================================================
    * (A) AREA  -- field level, GPS else self-reported
    *==========================================================================
    use "`mwidir'/`cfile'", clear

    if "`pattern'"=="D" {
        * ---- waves 1-2: plot-level area (module C); unit id = plot number ----
        if `w'==2 {
            rename ag_c00 ag_o00
            merge m:1 `hhid' ag_o00 using "`mwidir'/`peren'", gen(_pmerge)
            rename ag_o00 unit
            * perennial self-reported/GPS come in as ag_o04*
        }
        else rename ag_c00 unit

        gen area_self_reported = ag_c04a * 0.404686            // acres -> ha (default)
        replace area_self_reported = ag_c04a          if ag_c04b==2   // already ha
        replace area_self_reported = ag_c04a * 0.0001 if ag_c04b==3   // m^2 -> ha
        gen plot_area_GPS = ag_c04c * 0.404686                  // GPS acres -> ha
        if `w'==2 {
            replace area_self_reported = ag_o04a * 0.404686 if ag_o04b==1 & _pmerge==2
            replace area_self_reported = ag_o04a            if ag_o04b==2 & _pmerge==2
            replace area_self_reported = ag_o04a * 0.0001   if ag_o04b==3 & _pmerge==2
            capture replace plot_area_GPS = ag_o04c if _pmerge==2
        }
    }
    else {
        * ---- waves 3-4: plot-in-garden area (module C + perennial) ----
        merge m:1 `hhid' gardenid plotid using "`mwidir'/`peren'", gen(_pmerge)
        gen area_self_reported = ag_c04a * 0.404686
        replace area_self_reported = ag_c04a          if ag_c04b==2
        replace area_self_reported = ag_c04a * 0.0001 if ag_c04b==3
        capture replace area_self_reported = ag_c04a * 0.0001 if ag_c04b_oth=="METERS"
        gen plot_area_GPS = ag_c04c * 0.404686
        replace area_self_reported = ag_o04a * 0.404686 if ag_o04b==1 & _pmerge==2
        replace area_self_reported = ag_o04a            if ag_o04b==2 & _pmerge==2
        replace area_self_reported = ag_o04a * 0.0001   if ag_o04b==3 & _pmerge==2
        capture replace plot_area_GPS = ag_o04c if _pmerge==2
    }
    replace plot_area_GPS = . if plot_area_GPS<=0

    * deterministic plot area: GPS where measured, else self-reported
    * (no model-based imputation; fully reproducible across Stata/R/Python)
    gen plot_area_ha = plot_area_GPS
    replace plot_area_ha = area_self_reported if missing(plot_area_ha)

    * aggregate to the PARCEL unit (plot for w1-2; garden for w3-4)
    if "`pattern'"=="D" {
        collapse (sum) parcel_area_ha = plot_area_ha (count) n_fields = plot_area_ha, ///
            by(`hhid' unit)
    }
    else {
        collapse (sum) parcel_area_ha = plot_area_ha (count) n_fields = plot_area_ha, ///
            by(`hhid' gardenid)
    }
    tempfile area
    save `area', replace

    *==========================================================================
    * (B) TENURE  + base = every tenure record (plot for w1-2; garden for w3-4)
    *==========================================================================
    if "`pattern'"=="D" {
        use "`mwidir'/`dfile'", clear
        rename ag_d00 unit
        gen byte parcel_rentedin  = inlist(ag_d03,6,7,8)
        gen byte parcel_purchased = inlist(ag_d03,4,5)
        egen _rout = rowmax(ag_d19a ag_d19b ag_d19c ag_d19d)
        gen byte parcel_rentedout = (_rout>0) & !mi(_rout)
        if `w'==1 gen byte parcel_certificate = .
        if `w'==2 gen byte parcel_certificate = (ag_d03_1==1) if !mi(ag_d03_1)
        collapse (max) parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased, ///
            by(`hhid' unit)
        merge 1:1 `hhid' unit using `area', keep(master match) nogen
        egen parcel_id = concat(`hhid' unit), punct("-")
    }
    else {
        use "`mwidir'/`bfile'", clear
        if `w'==3 {
            gen byte parcel_rentedin  = inlist(ag_b203,6,7,8)
            gen byte parcel_purchased = (ag_b203==4)
            gen byte parcel_certificate = inlist(ag_b204_1,1,2,3) if !mi(ag_b204_1)
            egen _rout = rowmax(ag_b219a ag_b219b ag_b219c ag_b219d)
            gen byte parcel_rentedout = (_rout>0) & !mi(_rout)
        }
        else {   /* wave 4: no acquisition-method question */
            egen _paid = rowmax(ag_b211a ag_b211b)
            gen byte parcel_rentedin  = (ag_brentedin==1) | (_paid>0 & !mi(_paid))
            egen _rout = rowmax(ag_b219a ag_b219b ag_b219c ag_b219d)
            gen byte parcel_rentedout = (ag_brentedout==1) | (_rout>0 & !mi(_rout))
            gen byte parcel_purchased   = .
            gen byte parcel_certificate = .
        }
        collapse (max) parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased, ///
            by(`hhid' gardenid)
        merge 1:1 `hhid' gardenid using `area', keep(master match) nogen
        egen parcel_id = concat(`hhid' gardenid), punct("-")
    }
    replace n_fields = 0 if missing(n_fields)

    *==========================================================================
    * (C) weights / design / identifiers
    *==========================================================================
    merge m:1 `hhid' using `hhattr', keep(master match) keepusing(weight ea_id strataid) nogen

    gen str20 country = "Malawi"
    gen int  wave  = `w'
    gen int  year  = `year'
    rename `hhid' hh_id
    capture confirm string variable hh_id
    if _rc tostring hh_id, replace force

    _mwifinal
    tempfile mwi`w'
    save `mwi`w'', replace
}

*================================================================================
* APPEND waves 1-4
*================================================================================
use `mwi1', clear
forvalues w = 2/4 {
    append using `mwi`w''
}
label data "Malawi IHPS w1-4: PARCEL-level rental/tenure descriptives (built `c(current_date)')"
compress
save "${Final}/rental_MWI.dta", replace

*================================================================================
* QC SUMMARY
*================================================================================
di as txt _n "================  MALAWI QC (parcel level)  ================"
tab country wave
egen _psu   = group(wave ea_id)
egen _strat = group(wave strataid)
svyset _psu [pw=weight], strata(_strat) singleunit(centered)
di as txt "-- design-weighted participation rates by year (one var per call) --"
foreach v in parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased {
    svy: mean `v', over(year)
}
di as txt _n "-- cultivated parcel area (ha) by wave --"
table wave, stat(mean parcel_area_ha) stat(p50 parcel_area_ha) stat(count parcel_area_ha) nformat(%7.3f)
di as txt _n "-- missingness --"
capture mdesc parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased parcel_area_ha weight
