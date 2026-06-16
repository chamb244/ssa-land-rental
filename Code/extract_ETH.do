/*********************************************************************************
* extract_ETH.do  -- Ethiopia (ESS waves 1-5)  -- PARCEL-LEVEL  -- TEMPLATE
* Part of ssa-land-rental.  Run via MASTER.do (needs globals set).
* Paths use forward slashes (work in Stata on Mac and Windows).
*--------------------------------------------------------------------------------
* UNIT = PARCEL. The universe is every parcel in the parcel roster, so parcels
* that are entirely rented/sharecropped out (and therefore have NO cultivated
* field records) are RETAINED. This fixes the earlier bug where rented-out
* collapsed to 0 in waves 4-5: those whole-parcel disposals never appear in the
* plot/field roster, so a plot-based frame dropped them all.
*
* Produces, per ESS wave, a PARCEL-level file with:
*   parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased
*   parcel_area_ha  (= sum of field areas: GPS where measured, else self-reported)  n_fields
*   + country wave year weight + household/holder/parcel IDs
* then appends waves 1-5 into:  ${Final}/rental_ETH.dta
*
* SOURCES & CODES: tenure recodes transcribed from
*   Reproduction_v2/Code/Cleaning_code/ETH_ESS1-5.do and VERIFIED against the
*   raw parcel rosters (sect2_pp_w*.dta) value labels.
*   Acquisition (how parcel acquired):  w1-3 = pp_s2q03   w4-5 = s2q05
*     1 Granted | 2 Inherited | 3 Rent | 4 Borrowed free | 5 Moved in w/o perm |
*     6 (w1-2: Other; w3-5: Shared crop in) | 7 Purchased (w3-5 only) | 8 Other
*   Rented OUT:  w1-3 = pp_s2q10 (1=Yes any fields)
*                w4-5 = s2q13   (1=all rented out, 2=all sharecropped out)
*   Certificate/document:  w1-3 = pp_s2q04   w4-5 = s2q03   (1=Yes,2=No)
*
* KEY DATA NOTES:
*  - "Purchased" (code 7) exists ONLY from wave 3 (ESS15) on. ESS11/ESS13 had no
*    purchase category, so parcel_purchased is MISSING (.) in w1-2, not 0.
*  - Rented-IN widens from "rent" (w1-2) to "rent + sharecrop-in" (w3-5);
*    rented-OUT widens from a yes/no item (w1-3) to "all rented + all sharecropped
*    out" (w4-5). These follow the published harmonisation; mind cross-wave levels.
*  - parcel_area_ha is CULTIVATED area summed from field GPS (imputed). Parcels
*    with no cultivated fields (e.g. fully rented out) get MISSING area, not 0.
*
* DEVIATIONS (documented):
*  (a) Plot area is GPS where measured, else self-reported (both in ha) - a
*      deterministic measure. The published pipeline instead model-imputes missing
*      GPS area (pmm); we drop that so area is fully reproducible across languages
*      and does not depend on an RNG. Tenure variables are unaffected.
*  (b) Weight taken from the household cover file (hhid + wave weight).
*  (c) ESS21 ag-extension area supplement (sect12c) omitted: its source merge key
*      is inconsistent (household_id+field_id vs holder_id+parcel_id+field_id).
*      w5 area uses the plot-roster GPS/self-reported measure like w4.
*********************************************************************************/

* ---- helper program: label & order the harmonised output vars ----------------
capture program drop _ethfinal
program define _ethfinal
    label var country            "Country"
    label var wave               "Survey wave"
    label var year               "Survey year"
    label var weight             "Household survey weight"
    label var parcel_rentedin    "Parcel rented/sharecropped IN (0/1)"
    label var parcel_rentedout   "Parcel rented/sharecropped OUT (0/1)"
    label var parcel_certificate "Parcel has certificate/document (0/1)"
    label var parcel_purchased   "Parcel acquired through purchase (0/1; . if not asked)"
    label var parcel_area_ha     "Cultivated parcel area, ha (field GPS, else self-reported)"
    label var n_fields           "Number of cultivated fields on parcel"
    label var ea_id              "Enumeration area (survey PSU)"
    label var strataid           "Survey design stratum"
    * harmonise id types to string so country files append cleanly into the pool
    capture confirm string variable parcel_id
    if _rc tostring parcel_id, replace force
    capture confirm string variable holder_id
    if _rc tostring holder_id, replace force
    order country wave year weight strataid ea_id hh_id holder_id parcel_id ///
          parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased ///
          parcel_area_ha n_fields
end

*================================================================================
* WAVE LOOP
*================================================================================
forvalues w = 1/5 {

    *--- wave-specific macros --------------------------------------------------
    if `w'==1 {
        local fold "ESS 11"
        local year 2012
        local hhid household_id
        local wtvar pw
        local cover sect_cover_hh_w1.dta
        local parcel sect2_pp_w1.dta
        local plotf  sect3_pp_w1.dta
        local conv   "ESS 11"
        local acq    pp_s2q03
        local rincodes 3
        local rentout pp_s2q10
        local routcodes 1
        local cert   pp_s2q04
        local hascert_replace 1     // set cert=0 for rented/borrowed/sharecrop parcels
        local haspurchase 0         // no purchase category this wave
    }
    else if `w'==2 {
        local fold "ESS 13"
        local year 2014
        local hhid household_id2
        local wtvar pw2
        local cover sect_cover_hh_w2.dta
        local parcel sect2_pp_w2.dta
        local plotf  sect3_pp_w2.dta
        local conv   "ESS 13"
        local acq    pp_s2q03
        local rincodes 3
        local rentout pp_s2q10
        local routcodes 1
        local cert   pp_s2q04
        local hascert_replace 1
        local haspurchase 0
    }
    else if `w'==3 {
        local fold "ESS 15"
        local year 2016
        local hhid household_id2
        local wtvar pw_w3
        local cover sect_cover_hh_w3.dta
        local parcel sect2_pp_w3.dta
        local plotf  sect3_pp_w3.dta
        local conv   "ESS 15"
        local acq    pp_s2q03
        local rincodes 3 6
        local rentout pp_s2q10
        local routcodes 1
        local cert   pp_s2q04
        local hascert_replace 1
        local haspurchase 1
    }
    else if `w'==4 {
        local fold "ESS 18"
        local year 2019
        local hhid household_id
        local wtvar pw_w4
        local cover sect_cover_hh_w4.dta
        local parcel sect2_pp_w4.dta
        local plotf  sect3_pp_w4.dta
        local conv   "ESS 18"
        local acq    s2q05
        local rincodes 3 6
        local rentout s2q13
        local routcodes 1 2
        local cert   s2q03
        local hascert_replace 0
        local haspurchase 1
    }
    else if `w'==5 {
        local fold "ESS 21"
        local year 2022
        local hhid household_id
        local wtvar pw_w5
        local cover sect_cover_hh_w5.dta
        local parcel sect2_pp_w5.dta
        local plotf  sect3_pp_w5.dta
        local conv   "ESS 18"        // ESS21 has no conversion file; reuse ESS18
        local acq    s2q05
        local rincodes 3 6
        local rentout s2q13
        local routcodes 1 2
        local cert   s2q03
        local hascert_replace 0
        local haspurchase 1
    }

    di as txt _n "=================  ETHIOPIA  wave `w'  (`fold', `year')  ================="

    *==========================================================================
    * (0) SURVEY-DESIGN STRATA (strataid), faithful to ETH_ESS`w'.do.
    *     w1-3: group(rural region) with small-region collapse, CHAINED across
    *           waves (w2 extends w1, w3 extends w2) to keep panel HHs aligned.
    *     w4-5: explicit region x rural/urban recode.
    *     Saved to ${Temp}/eth_strataid_w`w'.dta (w2,w3 read the prior wave).
    *     ea_id (the PSU) is carried separately, straight from the parcel roster.
    *==========================================================================
    if `w'==1 {
        use "${Input}/Ethiopia/`fold'/`cover'", clear
        gen region2 = saq01
        replace region2 = 99 if inlist(saq01,2,6,12,13,15)
        egen strataid = group(rural region2)
        keep household_id strataid
    }
    else if `w'==2 {
        use "${Temp}/eth_strataid_w1.dta", clear
        merge 1:m household_id using "${Input}/Ethiopia/`fold'/`cover'", ///
            keep(using match) keepusing(household_id2 rural saq01) force
        gen region2 = saq01
        replace region2 = 99 if inlist(saq01,2,6,12,13,15)
        egen strataid2 = group(rural region2) if rural==3
        replace strataid2 = 10 + strataid2
        replace strataid = strataid2 if _merge==2     // add the new (urban) strata
        keep household_id2 strataid
    }
    else if `w'==3 {
        use "${Temp}/eth_strataid_w2.dta", clear
        merge 1:1 household_id2 using "${Input}/Ethiopia/`fold'/`cover'", ///
            keepusing(household_id2 rural saq01) force
        bys saq01 rural: egen strataid2 = max(strataid)
        replace strataid = strataid2 if _merge==2
        keep household_id2 strataid
    }
    else {
        * w4 & w5: explicit region(saq01) x rural/urban(saq14) recode
        use "${Input}/Ethiopia/`fold'/`cover'", clear
        gen strataid = .
        replace strataid = 17 if saq14==1 & saq01==2     // rural, new small region
        replace strataid = 18 if saq14==1 & saq01==5
        replace strataid = 19 if saq14==1 & saq01==6
        replace strataid = 20 if saq14==1 & saq01==12
        replace strataid = 21 if saq14==1 & saq01==13
        replace strataid = 22 if saq14==1 & saq01==15
        replace strataid = 23 if saq14==2 & saq01==2     // urban, new small region
        replace strataid = 24 if saq14==2 & saq01==5
        replace strataid = 25 if saq14==2 & saq01==6
        replace strataid = 26 if saq14==2 & saq01==12
        replace strataid = 27 if saq14==2 & saq01==13
        replace strataid = 28 if saq14==2 & saq01==15
        replace strataid = 1  if saq14==1 & saq01==1     // Rural Tigray
        replace strataid = 2  if saq14==1 & saq01==3     // Rural Amhara
        replace strataid = 3  if saq14==1 & saq01==4     // Rural Oromia
        replace strataid = 5  if saq14==1 & saq01==7     // Rural SNNP
        replace strataid = 29 if saq14==2 & saq01==1     // Urban Tigray
        replace strataid = 30 if saq14==2 & saq01==3     // Urban Amhara
        replace strataid = 31 if saq14==2 & saq01==4     // Urban Oromia
        replace strataid = 32 if saq14==2 & saq01==7     // Urban SNNP
        replace strataid = 99 if saq01==14               // Addis
        keep household_id strataid
    }
    duplicates drop
    save "${Temp}/eth_strataid_w`w'.dta", replace

    *==========================================================================
    * (A) CULTIVATED PLOT AREA (ha) at FIELD level, GPS else self-reported,
    *     then AGGREGATED to the parcel (sum of field areas).
    *     Transcribed per wave from ETH_ESS`w'.do (area block).
    *==========================================================================
    use "${Input}/Ethiopia/`fold'/`plotf'", clear
    egen plot_id = concat(holder_id parcel_id field_id), punct("-")

    rename saq01 region
    rename saq02 zone
    rename saq03 woreda

    if inlist(`w',1,2,3) {
        * --- waves 1-3: GPS = pp_s3q05_a ; SR = pp_s3q02_a ; unit = pp_s3q02_c
        rename pp_s3q02_c local_unit
        merge m:1 region zone woreda local_unit ///
            using "${Input}/Ethiopia/`conv'/ET_local_area_unit_conversion.dta", ///
            keep(master match) nogen

        gen area_self_reported = pp_s3q02_a
        replace area_self_reported = area_self_reported * conversion
        replace area_self_reported = pp_s3q02_a if local_unit==2   // already m^2
        replace area_self_reported = area_self_reported * 0.0001    // -> hectares
        replace area_self_reported = pp_s3q02_a if local_unit==1    // already ha

        gen plot_area_GPS = pp_s3q05_a * 0.0001
        replace plot_area_GPS = . if plot_area_GPS<=0
    }
    else {
        * --- waves 4-5: GPS = s3q08 (flag s3q07) ; SR = s3q02a ; unit = s3q02b
        rename s3q02b local_unit
        capture destring zone,   replace
        capture destring woreda, replace
        merge m:1 region zone woreda local_unit ///
            using "${Input}/Ethiopia/`conv'/ET_local_area_unit_conversion.dta", ///
            keep(master match) nogen

        gen area_self_reported = s3q02a
        replace area_self_reported = area_self_reported * conversion
        replace area_self_reported = s3q02a if local_unit==2        // already m^2
        replace area_self_reported = area_self_reported * 0.0001     // -> hectares
        replace area_self_reported = s3q02a if local_unit==1         // already ha

        if `w'==4  gen plot_area_GPS = s3q08 * 0.0001 if s3q07==1
        if `w'==5  gen plot_area_GPS = s3q08 * 0.0001 if inlist(s3q07,1,2)
        * (ESS21 ag-extension supplement omitted - see header note c.)
    }

    * --- deterministic plot area: GPS where measured, else self-reported -------
    *     (no model-based imputation; fully reproducible across Stata/R/Python)
    gen plot_area_ha = plot_area_GPS
    replace plot_area_ha = area_self_reported if missing(plot_area_ha)

    * --- aggregate field area up to the parcel ---------------------------------
    collapse (sum) parcel_area_ha = plot_area_ha (count) n_fields = plot_area_ha, ///
        by(holder_id parcel_id)
    * (count) ignores missing, so n_fields = # fields with a (possibly imputed) area
    tempfile area
    save `area', replace

    *==========================================================================
    * (B) PARCEL BASE + TENURE  -- universe = every parcel in the parcel roster
    *==========================================================================
    use "${Input}/Ethiopia/`fold'/`parcel'", clear
    capture confirm variable ea_id       // PSU; present in all ESS parcel rosters
    if _rc gen ea_id = ""

    * rented in (rent, +sharecrop-in where available)
    gen byte parcel_rentedin = inlist(`acq', `=subinstr("`rincodes'"," ",",",.)')

    * rented out (whole-parcel disposal in w4-5; any-fields yes/no in w1-3)
    gen byte parcel_rentedout = inlist(`rentout', `=subinstr("`routcodes'"," ",",",.)')

    * certificate / document
    recode `cert' (1=1) (2=0) (else=.), gen(parcel_certificate)
    if `hascert_replace'==1 {
        replace parcel_certificate = 0 if inlist(`acq',3,4,6)   // rented/borrowed/sharecrop
    }

    * purchased (code 7); missing where the survey never offered the option
    if `haspurchase'==1  gen byte parcel_purchased = (`acq'==7) if !missing(`acq')
    if `haspurchase'==0  gen byte parcel_purchased = .

    * one row per parcel (carry hhid for the weight merge)
    collapse (max) parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased ///
             (firstnm) `hhid' ea_id, by(holder_id parcel_id)

    *==========================================================================
    * (C) MERGE area (left join: keep ALL parcels) + weights, tag identifiers
    *==========================================================================
    merge 1:1 holder_id parcel_id using `area', keep(master match) nogen
    replace n_fields = 0 if missing(n_fields)   // parcels with no cultivated field

    * survey-design strata (PSU = ea_id, carried above)
    merge m:1 `hhid' using "${Temp}/eth_strataid_w`w'.dta", keep(master match) nogen

    * weights (from household cover)
    preserve
        use "${Input}/Ethiopia/`fold'/`cover'", clear
        keep `hhid' `wtvar'
        duplicates drop
        rename `wtvar' weight
        tempfile wts
        save `wts', replace
    restore
    merge m:1 `hhid' using `wts', keep(master match) nogen

    gen str20 country = "Ethiopia"
    gen int  wave    = `w'
    gen int  year    = `year'
    rename `hhid' hh_id

    _ethfinal
    tempfile eth`w'
    save `eth`w'', replace
}

*================================================================================
* APPEND waves 1-5
*================================================================================
use `eth1', clear
forvalues w = 2/5 {
    append using `eth`w''
}

label data "Ethiopia ESS w1-5: PARCEL-level rental/tenure descriptives (built `c(current_date)')"
compress
* top-code implausible plot areas (data-entry outliers); threshold in MASTER
if "${area_max}"=="" global area_max 40
replace parcel_area_ha = . if parcel_area_ha > ${area_max} & !missing(parcel_area_ha)
save "${Final}/rental_ETH.dta", replace

*================================================================================
* QC SUMMARY
*================================================================================
di as txt _n "================  ETHIOPIA QC (parcel level)  ================"
tab country wave

* Design-based (pweighted) estimates. PSU=ea_id, strata=strataid, made unique
* across waves so pooled svyset is valid. singleunit(centered) guards strata
* that contain a single sampled PSU.
egen _psu   = group(wave ea_id)
egen _strat = group(wave strataid)
svyset _psu [pw=weight], strata(_strat) singleunit(centered)

di as txt "-- design-weighted participation rates by year (svy: mean) --"
* NB: estimate ONE variable per call. A joint call would use casewise deletion,
* and because parcel_purchased is missing for ALL of 2012-2014 (no purchase
* category those waves), a joint call silently drops those two years entirely.
foreach v in parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased {
    svy: mean `v', over(year)
}

di as txt _n "-- quick unweighted means for comparison --"
foreach v in parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased {
    di as txt _n "`v':"
    table wave [aw=weight], stat(mean `v') stat(count `v') nformat(%6.3f)
}
di as txt _n "-- cultivated parcel area (ha) by wave --"
table wave, stat(mean parcel_area_ha) stat(p50 parcel_area_ha) stat(count parcel_area_ha) nformat(%7.3f)
di as txt _n "-- parcels with NO cultivated field (e.g. fully rented out), by wave --"
table wave, stat(mean parcel_rentedout) stat(sum parcel_rentedout) nformat(%7.3f)
count if n_fields==0
di as txt "  (parcels with n_fields==0: " r(N) ")"
di as txt _n "-- missingness check --"
capture mdesc parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased parcel_area_ha weight
