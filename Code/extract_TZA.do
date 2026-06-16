/*********************************************************************************
* extract_TZA.do  -- Tanzania (NPS waves 1-5)  -- PARCEL-LEVEL
* Part of ssa-land-rental.  Run via MASTER.do (needs globals set).
* Paths use forward slashes (work in Stata on Mac/Windows/Linux).
*--------------------------------------------------------------------------------
* SOURCE: National Panel Survey, 5 waves. Waves 4 (2014/15) and 5 (2019/20) each
* split into an EXTENDED (long panel) and a REFRESH subsample - 7 datasets total,
* combined here into waves 4 and 5 using each subsample's own weights.
*   wave 1 = NPS 08 (2009)        hh = hhid
*   wave 2 = NPS 10 (2011)        hh = y2_hhid
*   wave 3 = NPS 12 (2013)        hh = y3_hhid
*   wave 4 = NPS 14 - extended + NPS 14 - refresh (2015)   hh = y4_hhid
*   wave 5 = NPS 19 - extended (sdd_hhid) + NPS 19 - refresh (y5_hhid)  (2019)
*
* UNIT = PARCEL (the plot). Tenure (incl. acquisition & use) is in the plot-inputs
* module; area is in the plot roster - merged on hhid-plotnum.
*
* OUTPUT (per parcel): parcel_rentedin parcel_rentedout parcel_certificate
*   parcel_purchased parcel_area_ha n_fields + country wave year weight
*   strataid ea_id hh_id parcel_id
*
* CODES (verified against the raw value labels):
*  Tenure question shifts between an EARLY scheme (NPS1-3) and a LATE scheme (NPS4-5):
*   EARLY  s3aq22 (w1) / ag3a_24 (w2) / ag3a_25 (w3)  "ownership status of plot":
*     1 owned | 2 used free | 3 RENTED IN | 4 SHARED RENT (sharecrop) | 5 shared own
*     -> rented-in = inlist(.,3,4) ;  owned = inlist(.,1,5) ;  PURCHASE NOT ASKED (->.)
*   LATE   ag3a_25 (w4,w5)  "How was this plot acquired?":
*     1 inheritance | 2 gift | 3 borrowing | 4 village allocation | 5 PURCHASED |
*     6 used free | 7 RENTED IN | 8 SHARED-RENT (sharecrop) | 9 shared-own | 10 squatting | 11 other
*     -> rented-in = inlist(.,7,8) ; purchased = (.==5) ; owned = inlist(.,1,2,5,9)
*  Rented-OUT  s3aq3 / ag3a_03  "how plot was used": 2 = RENTED OUT (all waves).
*    The roster lists plots OWNED OR CULTIVATED, so rented-out is well-captured.
*  Certificate: w1 s3aq25 / w2 ag3a_27 (1=yes,2=no); w3 ag3a_28 (9,10,11=no, else yes);
*    w4-5 ag3a_28a (1,2=yes,3=no) OR ag3a_28d in 1-5.  Set 0 if not owned.
*
*  -> parcel_purchased is MISSING for waves 1-3 (the early scheme has no purchase
*     category); measurable (code 5) only from wave 4. Estimate it separately.
*
* AREA: GPS else self-reported (deterministic; both acres x 0.404686 -> ha).
*   self-reported = s2aq4 (w1) / ag2a_04 (w2-5); GPS = `area' (w1) / ag2a_09 (w2-5).
*
* DESIGN: weight per dataset (cover file); strataid direct from cover; ea_id from the
*   cover's cluster/admin vars (falls back to the household id where unavailable).
*
* NOTE: complex (7 datasets, two schemes, panel+refresh). Treat the first Stata run
* as a shakedown - the cover ea_id construction and NPS5-refresh plot ids to watch.
*********************************************************************************/

capture program drop _tzafinal
program define _tzafinal
    label var country          "Country"
    label var wave             "Survey wave"
    label var year             "Survey year"
    label var weight           "Household survey weight"
    label var parcel_rentedin    "Parcel rented/sharecropped IN (0/1)"
    label var parcel_rentedout   "Parcel rented OUT (0/1)"
    label var parcel_certificate "Parcel has a land title/certificate (0/1)"
    label var parcel_purchased   "Parcel acquired through purchase (0/1; . if not asked)"
    label var parcel_area_ha     "Parcel area, ha (GPS, else self-reported)"
    label var n_fields           "Number of parcel records aggregated"
    label var ea_id              "Enumeration area (survey PSU)"
    label var strataid           "Survey design stratum"
    order country wave year weight strataid ea_id hh_id parcel_id ///
          parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased ///
          parcel_area_ha n_fields
end

* 7 datasets: s = 1..7 ; output wave tagged per dataset
forvalues s = 1/7 {

    if `s'==1 {
        local fold "NPS 08"
        local wv 1
        local year 2009
        local hhidv hhid
        local plotnumv plotnum
        local tmod SEC_3A.dta
        local tenurev s3aq22
        local scheme early
        local routv s3aq3
        local certv s3aq25
        local cscheme A
        local roster SEC_2A.dta
        local srv s2aq4
        local gpsv area
        local cover SEC_A_T.dta
        local wtv hh_weight
    }
    else if `s'==2 {
        local fold "NPS 10"
        local wv 2
        local year 2011
        local hhidv y2_hhid
        local plotnumv plotnum
        local tmod AG_SEC3A.dta
        local tenurev ag3a_24
        local scheme early
        local routv ag3a_03
        local certv ag3a_27
        local cscheme A
        local roster AG_SEC2A.dta
        local srv ag2a_04
        local gpsv ag2a_09
        local cover HH_SEC_A.dta
        local wtv y2_weight
    }
    else if `s'==3 {
        local fold "NPS 12"
        local wv 3
        local year 2013
        local hhidv y3_hhid
        local plotnumv plotnum
        local tmod AG_SEC_3A.dta
        local tenurev ag3a_25
        local scheme early
        local routv ag3a_03
        local certv ag3a_28
        local cscheme B
        local roster AG_SEC_2A.dta
        local srv ag2a_04
        local gpsv ag2a_09
        local cover HH_SEC_A.dta
        local wtv y3_weight
    }
    else if inlist(`s',4,5) {
        local wv 4
        local year 2015
        local hhidv y4_hhid
        local plotnumv plotnum
        local tmod AG_SEC_3A.dta
        local tenurev ag3a_25
        local scheme late
        local routv ag3a_03
        local cscheme C
        local roster AG_SEC_2A.dta
        local srv ag2a_04
        local gpsv ag2a_09
        local cover HH_SEC_A.dta
        local wtv y4_weights
        local fold = cond(`s'==4, "NPS 14 - extended", "NPS 14 - refresh")
    }
    else if inlist(`s',6,7) {
        local wv 5
        local year 2019
        local plotnumv plotnum
        local tmod AG_SEC_3A.dta
        local tenurev ag3a_25
        local scheme late
        local routv ag3a_03
        local cscheme C
        local roster AG_SEC_02.dta
        local srv ag2a_04
        local gpsv ag2a_09
        local cover HH_SEC_A.dta
        if `s'==6 {
            local fold "NPS 19 - extended"
            local hhidv sdd_hhid
            local wtv sdd_weights
        }
        else {
            local fold "NPS 19 - refresh"
            local hhidv y5_hhid
            local wtv y5_crossweight
            local plotnumv plot_id2          // NPS5-refresh: an existing plot_id is renamed
        }
    }

    di as txt _n "=========  TANZANIA  dataset `s'  ->  wave `wv'  (`fold', `year')  ========="

    *==========================================================================
    * (A) TENURE module (plot-inputs)
    *==========================================================================
    use "${Input}/Tanzania/`fold'/`tmod'", clear
    if `s'==7 capture rename plot_id plot_id2
    egen plot_id = concat(`hhidv' `plotnumv'), punct("-")

    if "`scheme'"=="early" {
        gen byte parcel_rentedin  = inlist(`tenurev',3,4)
        gen byte parcel_purchased = .
        gen byte _owned = inlist(`tenurev',1,5)
    }
    else {
        gen byte parcel_rentedin  = inlist(`tenurev',7,8)
        gen byte parcel_purchased = (`tenurev'==5)
        gen byte _owned = inlist(`tenurev',1,2,5,9)
    }
    gen byte parcel_rentedout = (`routv'==2)

    * certificate (scheme A: 1=yes; B: 9/10/11=no else yes; C: 28a in 1,2 or 28d 1-5)
    if "`cscheme'"=="A" {
        gen byte parcel_certificate = (`certv'==1) if !mi(`certv')
    }
    else if "`cscheme'"=="B" {
        gen byte parcel_certificate = !inlist(`certv',9,10,11) if !mi(`certv')
    }
    else {
        gen byte parcel_certificate = inlist(ag3a_28a,1,2)
        capture replace parcel_certificate = 1 if inrange(ag3a_28d,1,5)
        replace parcel_certificate = . if mi(ag3a_28a)
    }
    replace parcel_certificate = 0 if _owned==0

    keep `hhidv' plot_id parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased
    collapse (max) parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased, ///
        by(`hhidv' plot_id)
    tempfile tenure_f
    save `tenure_f', replace

    *==========================================================================
    * (B) AREA (plot roster); acres -> ha; GPS else self-reported
    *==========================================================================
    use "${Input}/Tanzania/`fold'/`roster'", clear
    if `s'==7 capture rename plot_id plot_id2
    egen plot_id = concat(`hhidv' `plotnumv'), punct("-")
    gen gps = `gpsv' * 0.404686
    replace gps = . if gps<=0
    gen sr  = `srv' * 0.404686
    gen plot_area_ha = gps
    replace plot_area_ha = sr if missing(plot_area_ha)
    keep `hhidv' plot_id plot_area_ha
    collapse (sum) parcel_area_ha = plot_area_ha (count) n_fields = plot_area_ha, ///
        by(`hhidv' plot_id)
    tempfile area_f
    save `area_f', replace

    *==========================================================================
    * (C) weight / strata / ea  (from cover)
    *==========================================================================
    use "${Input}/Tanzania/`fold'/`cover'", clear
    rename `wtv' weight
    capture confirm variable strataid
    if _rc gen strataid = .
    * ea_id: try admin/cluster vars, else household id
    local eaok 0
    capture egen ea_id = concat(region district ward ea), punct("-")
    if _rc==0 local eaok 1
    if !`eaok' {
        capture egen ea_id = concat(hh_a01_1 hh_a02_1 hh_a03_1 hh_a04_1), punct("-")
        if _rc==0 local eaok 1
    }
    if !`eaok' {
        capture confirm variable clusterid
        if _rc==0 {
            egen ea_id = concat(clusterid)
            local eaok 1
        }
    }
    if !`eaok' egen ea_id = concat(`hhidv')
    keep `hhidv' weight strataid ea_id
    duplicates drop
    bys `hhidv' (weight): keep if _n==1
    tempfile hhattr
    save `hhattr', replace

    *==========================================================================
    * (D) assemble
    *==========================================================================
    use `tenure_f', clear
    merge 1:1 `hhidv' plot_id using `area_f', nogen
    merge m:1 `hhidv' using `hhattr', keep(master match) nogen
    replace n_fields = 0 if missing(n_fields)
    gen str20 country = "Tanzania"
    gen int  wave = `wv'
    gen int  year = `year'
    rename plot_id parcel_id
    egen hh_id = concat(`hhidv')
    _tzafinal
    tempfile tza`s'
    save `tza`s'', replace
}

*================================================================================
* APPEND all 7 datasets (waves 4 & 5 = extended + refresh)
*================================================================================
use `tza1', clear
forvalues s = 2/7 {
    append using `tza`s''
}
* top-code implausible plot areas (data-entry outliers); threshold in MASTER
if "${area_max}"=="" global area_max 40
replace parcel_area_ha = . if parcel_area_ha > ${area_max} & !missing(parcel_area_ha)
label data "Tanzania NPS w1-5: PARCEL-level rental/tenure descriptives (built `c(current_date)')"
compress
save "${Final}/rental_TZA.dta", replace

*================================================================================
* QC
*================================================================================
di as txt _n "================  TANZANIA QC (parcel level)  ================"
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
