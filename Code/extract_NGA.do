/*********************************************************************************
* extract_NGA.do  -- Nigeria (GHS-Panel waves 1-5)  -- PARCEL-LEVEL
* Part of ssa-land-rental.  Run via MASTER.do (needs globals set).
* Paths use forward slashes (work in Stata on Mac/Windows/Linux).
*--------------------------------------------------------------------------------
* SOURCE: General Household Survey-Panel, 5 waves (2010/11, 2012/13, 2015/16,
* 2018/19, 2023). Folders Nigeria/GHS 10|12|15|18|23. Plot id = hhid-plotid.
*
* UNIT = PARCEL (the plot record). Tenure (incl. acquisition & rented-out) is in the
* tenure module; area is in the plot roster - two files merged on hhid-plotid.
*   tenure module = sect11b_plantingw1.dta (w1, s11bq*) / sect11b1_plantingwN.dta (w2-5, s11b1q*)
*   plot roster   = sect11a1_plantingwN.dta
*
* OUTPUT (per parcel): parcel_rentedin parcel_rentedout parcel_certificate
*   parcel_purchased parcel_area_ha n_fields + country wave year weight
*   strataid ea_id hh_id parcel_id
*
* CODES (verified against GHS10 value labels; applied across waves under the
* consistent GHS "How was [PLOT] acquired?" instrument):
*   Acquisition  s11bq4 (w1) / s11b1q4 (w2-5)  "How was [PLOT] acquired?":
*     1 outright purchase | 2 rented for cash/in-kind | 3 used free of charge |
*     4 distributed by community/family | (w3+ add 5 = other ownership; w5 adds
*     more non-owned codes incl. 6 = another rental type)
*     -> parcel_purchased = (acq==1)
*     -> parcel_rentedin  = (acq==2)            [w5: inlist(acq,2,6)]
*   Rented-out  "main use / was it rented out":
*     w1  s11bq17==2  (main use = rented out)
*     w2-4 s11b1q28 in {2,3} ; w5 s11b1q44 in {2,3}
*   Certificate (has a certificate of occupancy):
*     w1  none asked -> missing
*     w2-4 s11b1q7 (1=yes,2=no,3=.) ; w5 s11b1q8 ; 0 if not owned
*
* AREA: GPS where measured, else self-reported (deterministic; no imputation).
*   Self-reported is in local units (heaps/ridges/stands/plots/acres/m2/ha) with
*   REGION-SPECIFIC conversion factors (identical across waves; transcribed below).
*   GPS = `plot_area' * 0.0001 (m2 -> ha) as in the upstream pipeline.
*
* DESIGN: weight per wave (consumption/cover files). ea_id = lga-ea, strataid = zone,
*   taken from each wave's cover with the GHS10 cover as panel fallback (the panel
*   covers drop ea/lga for non-refresh households).
*
* NOTE: Nigeria is the most intricate country (5 waves, region-specific area
* conversions, panel geography). Treat the first Stata run as a shakedown - the area
* GPS source (`plot_area') and the per-wave cover merges are the spots to watch.
*********************************************************************************/

capture program drop _ngafinal
program define _ngafinal
    label var country          "Country"
    label var wave             "Survey wave"
    label var year             "Survey year"
    label var weight           "Household survey weight"
    label var parcel_rentedin    "Parcel rented IN (0/1)"
    label var parcel_rentedout   "Parcel rented OUT (0/1)"
    label var parcel_certificate "Parcel has certificate of occupancy (0/1; . if not asked)"
    label var parcel_purchased   "Parcel acquired through purchase (0/1)"
    label var parcel_area_ha     "Parcel area, ha (GPS, else self-reported)"
    label var n_fields           "Number of parcel records aggregated"
    label var ea_id              "Enumeration area (survey PSU)"
    label var strataid           "Survey design stratum (zone)"
    order country wave year weight strataid ea_id hh_id parcel_id ///
          parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased ///
          parcel_area_ha n_fields
end

forvalues w = 1/5 {

    if `w'==1 {
        local fold "GHS 10"
        local year 2011
        local tenure   sect11b_plantingw1.dta
        local roster   sect11a1_plantingw1.dta
        local acqv s11bq4
        local routv s11bq17
        local routcodes 2
        local certv ""                       // no certificate question in w1
        local srv s11aq4a
        local unitv s11aq4b
        local gpsv s11aq4d
        local rincodes 2
        local cover secta_plantingw1.dta
    }
    else if `w'==2 {
        local fold "GHS 12"
        local year 2013
        local tenure   sect11b1_plantingw2.dta
        local roster   sect11a1_plantingw2.dta
        local acqv s11b1q4
        local routv s11b1q28
        local routcodes 2 3
        local certv s11b1q7
        local srv s11aq4a
        local unitv s11aq4b
        local gpsv s11aq4d
        local rincodes 2
        local cover secta_plantingw2.dta
    }
    else if `w'==3 {
        local fold "GHS 15"
        local year 2016
        local tenure   sect11b1_plantingw3.dta
        local roster   sect11a1_plantingw3.dta
        local acqv s11b1q4
        local routv s11b1q28
        local routcodes 2 3
        local certv s11b1q7
        local srv s11aq4a
        local unitv s11aq4b
        local gpsv s11aq4d
        local rincodes 2
        local cover secta_plantingw3.dta
    }
    else if `w'==4 {
        local fold "GHS 18"
        local year 2019
        local tenure   sect11b1_plantingw4.dta
        local roster   sect11a1_plantingw4.dta
        local acqv s11b1q4
        local routv s11b1q28
        local routcodes 2 3
        local certv s11b1q7
        local srv s11aq4aa
        local unitv s11aq4b
        local gpsv s11aq4d
        local rincodes 2
        local cover secta_plantingw4.dta
    }
    else if `w'==5 {
        local fold "GHS 23"
        local year 2023
        local tenure   sect11b1_plantingw5.dta
        local roster   sect11a1_plantingw5.dta
        local acqv s11b1q4
        local routv s11b1q44
        local routcodes 2 3
        local certv s11b1q8
        local srv s11aq3_number
        local unitv s11aq3_unit
        local gpsv s11mq3
        local rincodes 2 6
        local cover secta_plantingw5.dta
    }

    di as txt _n "=================  NIGERIA  wave `w'  (`year')  ================="

    *==========================================================================
    * (A) TENURE module: purchase, rented-in, rented-out, certificate
    *==========================================================================
    use "${Input}/Nigeria/`fold'/`tenure'", clear
    egen plot_id = concat(hhid plotid), punct("-")

    gen byte parcel_purchased = (`acqv'==1)
    gen byte parcel_rentedin  = inlist(`acqv', `=subinstr("`rincodes'"," ",",",.)')
    gen byte parcel_rentedout = inlist(`routv', `=subinstr("`routcodes'"," ",",",.)')
    gen byte _owned = inlist(`acqv',1,4,5)               // owned tenure (for cert gating)
    if "`certv'"=="" {
        gen byte parcel_certificate = .
    }
    else {
        recode `certv' (1=1) (2=0) (3=.), gen(parcel_certificate)
        replace parcel_certificate = 0 if _owned==0
    }
    collapse (max) parcel_purchased parcel_rentedin parcel_rentedout parcel_certificate, ///
        by(hhid plot_id)
    tempfile tenure_f
    save `tenure_f', replace

    *==========================================================================
    * (B) PLOT ROSTER: area (GPS else self-reported, region-specific conversions)
    *==========================================================================
    use "${Input}/Nigeria/`fold'/`roster'", clear
    rename (zone state lga) (admin_1 admin_2 admin_3)
    egen plot_id = concat(hhid plotid), punct("-")

    gen area_self_reported = `srv'
    * simple units (heaps/ridges/stands handled below by region)
    capture replace area_self_reported = . if `unitv'==8                       // w1 'missing' unit
    capture replace area_self_reported = area_self_reported * 0.0667 if `unitv'==4   // (w1-4 only)
    replace area_self_reported = area_self_reported * 0.4    if `unitv'==5      // acres -> ha
    replace area_self_reported = area_self_reported * 0.0001 if `unitv'==7      // m2 -> ha
    if `w'==5 {
        replace area_self_reported = area_self_reported * 0.0929  if `unitv'==8
        replace area_self_reported = area_self_reported * 0.04645 if `unitv'==9
        replace area_self_reported = area_self_reported * 0.405   if `unitv'==10
    }
    * heaps (unit 1), region-specific (admin_1 = zone 1-6) - identical across waves
    replace area_self_reported = area_self_reported * 0.00012 if `unitv'==1 & admin_1==1
    replace area_self_reported = area_self_reported * 0.00016 if `unitv'==1 & admin_1==2
    replace area_self_reported = area_self_reported * 0.00011 if `unitv'==1 & admin_1==3
    replace area_self_reported = area_self_reported * 0.00019 if `unitv'==1 & admin_1==4
    replace area_self_reported = area_self_reported * 0.00021 if `unitv'==1 & admin_1==5
    replace area_self_reported = area_self_reported * 0.00012 if `unitv'==1 & admin_1==6
    * ridges (unit 2)
    replace area_self_reported = area_self_reported * 0.0027  if `unitv'==2 & admin_1==1
    replace area_self_reported = area_self_reported * 0.004   if `unitv'==2 & admin_1==2
    replace area_self_reported = area_self_reported * 0.00494 if `unitv'==2 & admin_1==3
    replace area_self_reported = area_self_reported * 0.0023  if `unitv'==2 & admin_1==4
    replace area_self_reported = area_self_reported * 0.0023  if `unitv'==2 & admin_1==5
    replace area_self_reported = area_self_reported * 0.00001 if `unitv'==2 & admin_1==6
    * stands (unit 3)
    replace area_self_reported = area_self_reported * 0.00006 if `unitv'==3 & admin_1==1
    replace area_self_reported = area_self_reported * 0.00016 if `unitv'==3 & admin_1==2
    replace area_self_reported = area_self_reported * 0.00004 if `unitv'==3 & admin_1==3
    replace area_self_reported = area_self_reported * 0.00004 if `unitv'==3 & admin_1==4
    replace area_self_reported = area_self_reported * 0.00013 if `unitv'==3 & admin_1==5
    replace area_self_reported = area_self_reported * 0.00041 if `unitv'==3 & admin_1==6

    * GPS: upstream uses `plot_area' (m2) -> ha; fall back to the section GPS var.
    * Always create gps so it exists even when neither source is present (-> uses SR).
    gen double gps = .
    capture replace gps = `gpsv'
    capture replace gps = plot_area * 0.0001
    gen plot_area_ha = gps
    replace plot_area_ha = area_self_reported if missing(plot_area_ha)

    keep hhid plot_id plot_area_ha
    collapse (sum) parcel_area_ha = plot_area_ha (count) n_fields = plot_area_ha, ///
        by(hhid plot_id)
    tempfile area_f
    save `area_f', replace

    *==========================================================================
    * (C) GEO (ea_id, strataid) - wave cover with GHS10 panel fallback; + WEIGHT
    *==========================================================================
    * panel-base geography from GHS10 cover
    use "${Input}/Nigeria/GHS 10/secta_plantingw1.dta", clear
    keep hhid zone lga ea
    rename (zone lga ea) (zone0 lga0 ea0)
    tempfile geo0
    save `geo0', replace
    * this wave's own cover (refresh households)
    use "${Input}/Nigeria/`fold'/`cover'", clear
    capture keep hhid zone lga ea
    if _rc {
        keep hhid
        gen zone=.
        gen lga=.
        gen ea=.
    }
    merge 1:1 hhid using `geo0', nogen
    foreach v in zone lga ea {
        capture replace `v' = `v'0 if missing(`v')
    }
    egen ea_id = concat(lga ea), punct("-")
    rename zone strataid
    keep hhid ea_id strataid
    duplicates drop
    bys hhid: keep if _n==1
    tempfile geo
    save `geo', replace

    * weights (wave-specific source)
    if inlist(`w',1,2,3) {
        local v1 cons_agg_wave`w'_visit1.dta
        local v2 cons_agg_wave`w'_visit2.dta
        use "${Input}/Nigeria/`fold'/`v1'", clear
        capture merge 1:1 hhid using "${Input}/Nigeria/`fold'/`v2'", nogen
        rename hhweight weight
    }
    else if `w'==4 {
        use "${Input}/Nigeria/`fold'/totcons_final.dta", clear
        rename wt_wave4 weight
    }
    else if `w'==5 {
        use "${Input}/Nigeria/`fold'/`cover'", clear
        rename wt_cross_wave5 weight
    }
    keep hhid weight
    duplicates drop
    bys hhid (weight): keep if _n==1
    merge 1:1 hhid using `geo', nogen
    tempfile hhattr
    save `hhattr', replace

    *==========================================================================
    * (D) assemble
    *==========================================================================
    use `tenure_f', clear
    merge 1:1 hhid plot_id using `area_f', nogen
    merge m:1 hhid using `hhattr', keep(master match) nogen
    replace n_fields = 0 if missing(n_fields)
    rename plot_id parcel_id
    gen str20 country = "Nigeria"
    gen int  wave = `w'
    gen int  year = `year'
    egen hh_id = concat(hhid)
    _ngafinal
    tempfile nga`w'
    save `nga`w'', replace
}

*================================================================================
* APPEND waves 1-5
*================================================================================
use `nga1', clear
forvalues w = 2/5 {
    append using `nga`w''
}
label data "Nigeria GHS w1-5: PARCEL-level rental/tenure descriptives (built `c(current_date)')"
compress
save "${Final}/rental_NGA.dta", replace

*================================================================================
* QC
*================================================================================
di as txt _n "================  NIGERIA QC (parcel level)  ================"
tab country wave
egen _psu   = group(wave ea_id)
egen _strat = group(wave strataid)
svyset _psu [pw=weight], strata(_strat) singleunit(centered)
foreach v in parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased {
    svy: mean `v', over(year)
}
table wave, stat(mean parcel_area_ha) stat(p50 parcel_area_ha) stat(count parcel_area_ha) nformat(%7.3f)
capture mdesc parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased parcel_area_ha weight

exit
