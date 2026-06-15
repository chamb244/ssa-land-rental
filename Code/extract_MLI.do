/*********************************************************************************
* extract_MLI.do  -- Mali (EACI 2014 & 2017)  -- PARCEL-LEVEL
* Part of Reproduction_rental_260615.  Run via MASTER.do (needs globals set).
* Paths use forward slashes (work in Stata on Mac/Windows/Linux).
*--------------------------------------------------------------------------------
* SOURCE: two separate EACI rounds (Enquete Agricole de Conjoncture Integree),
* extracted to (note the different file-naming scheme in 2017):
*   ${Input}/Mali/EACI 14/   (2014; files EACI*_p1/p2.dta)
*   ${Input}/Mali/EACI 17/   (2017; files eaci17_sNNpY.dta)
*
* UNIT = PARCEL. Everything we need (tenure, acquisition, disposition, area) is in
* the single parcel/exploitation roster, so no cross-module merges:
*   2014 roster = EACIEXPLOI_p1.dta   (vars s1bq*)   hh = grappe-menage
*   2017 roster = eaci17_s11bp1.dta   (vars s11bq*)  hh = grappe-exploitation
*
* OUTPUT (per parcel): parcel_rentedin parcel_rentedout parcel_certificate
*   parcel_purchased parcel_area_ha n_fields + country wave year weight
*   strataid ea_id hh_id parcel_id
*
* CODES (verified against the raw French value labels):
*  Occupation mode  s1bq17 / s11bq17  "Mode d'occupation/propriete de la parcelle":
*    1 Propriete avec titre | 2 Propriete sans titre | 3 Pret gratuit |
*    4 Location | 5 Metayage | 6 Gage | 7 Autre | (9 / 99 = missing)
*    -> parcel_rentedin   = inlist(.,4,5)   (Location + Metayage = rent + sharecrop)
*    -> parcel_certificate= (. == 1)        (owned WITH formal title)
*  Acquisition mode s1bq22 / s11bq22  "Mode d'acquisition de la parcelle":
*    1 Heritage | 2 Par mariage | 3 Attribution coutumiere | 4 Don |
*    5 Attribution ODR | 6 Appropriation | 7 Achat | 8 Autre
*    -> parcel_purchased  = (. == 7)        (Achat; available BOTH waves)
*
* RENTED-OUT IS NOT MEASURABLE in EACI (set missing both waves):
*   The roster covers parcels the household OPERATES (exploitation), so land
*   rented/lent OUT is out of frame. The disposition item (s1bq32 / s11bq32) has
*   no rented-out code in 2014, and in 2017 ("Louee/Pretee") it flags only 5 of
*   ~24,250 parcels - a structural undercount, not a real ~0% rate.
*
* AREA: GPS where measured, else self-reported (deterministic; no imputation).
*   2014: GPS s1bq05a, SR s1bq10 (both treated as ha; 99 = missing).
*   2017: GPS s11bq07, SR s11bq11a (x0.0001 when unit s11bq11b==2).
*
* DESIGN: weight from the sample/weights file; ea_id = grappe (PSU).
*   strataid: 2017 uses the official `strate`; 2014 has no strate in its own files,
*   so we build group(region milieu) = group(s00q01 s00q04) from the cover.
*********************************************************************************/

capture program drop _mlifinal
program define _mlifinal
    label var country          "Country"
    label var wave             "Survey wave"
    label var year             "Survey year"
    label var weight           "Household survey weight"
    label var parcel_rentedin    "Parcel rented/sharecropped IN (0/1)"
    label var parcel_rentedout   "Parcel rented OUT (0/1; . = not measurable in EACI)"
    label var parcel_certificate "Parcel owned with formal title (0/1)"
    label var parcel_purchased   "Parcel acquired through purchase (0/1)"
    label var parcel_area_ha     "Parcel area, ha (GPS, else self-reported)"
    label var n_fields           "Number of parcel records aggregated"
    label var ea_id              "Enumeration area / cluster (survey PSU)"
    label var strataid           "Survey design stratum"
    order country wave year weight strataid ea_id hh_id parcel_id ///
          parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased ///
          parcel_area_ha n_fields
end

forvalues w = 1/2 {

    if `w'==1 {
        local fold  "EACI 14"
        local year  2014
        local roster EACIEXPLOI_p1.dta
        local hhparts grappe menage
        local plotparts grappe menage s1bq01 s1bq02
        local tenure s1bq17
        local acq    s1bq22
        local gpsv   s1bq05a
        local srv    s1bq10
        local wtfile EACIPOIDS.dta
        local wtvar  poids_menage
        local wtkey  grappe menage
        local cover  EACICONTROLE_p1.dta
    }
    else if `w'==2 {
        local fold  "EACI 17"
        local year  2017
        local roster eaci17_s11bp1.dta
        local hhparts grappe exploitation
        local plotparts grappe exploitation s11bq01 s11bq02
        local tenure s11bq17
        local acq    s11bq22
        local gpsv   s11bq07
        local srv    s11bq11a
        local wtfile EACI17_ECHANTILLON.dta
        local wtvar  poids_leger
        local wtkey  grappe exploitation
        local cover  eaci17_s00p1.dta
    }

    di as txt _n "=================  MALI  wave `w'  (`year')  ================="

    *==========================================================================
    * (A) PARCEL roster: tenure, acquisition, disposition, area  (all one file)
    *==========================================================================
    use "${Input}/Mali/`fold'/`roster'", clear
    egen hh_id     = concat(`hhparts'), punct("-")
    egen parcel_id = concat(`plotparts'), punct("-")
    egen ea_id     = concat(grappe)                     // PSU

    * tenure-based indicators
    gen byte parcel_rentedin    = inlist(`tenure',4,5)          // Location + Metayage
    gen byte parcel_certificate = (`tenure'==1)                 // owned with title
    gen byte parcel_purchased   = (`acq'==7)                    // Achat
    gen byte parcel_rentedout   = .                             // not measurable (see header)

    * area: GPS else self-reported (ha)
    gen gps = `gpsv'
    replace gps = . if gps==99
    gen sr  = `srv'
    replace sr = . if sr==99
    if `w'==2 replace sr = sr * 0.0001 if s11bq11b==2           // local-unit -> ha
    gen plot_area_ha = gps
    replace plot_area_ha = sr if missing(plot_area_ha)

    collapse (max) parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased ///
             (sum) parcel_area_ha = plot_area_ha (count) n_fields = plot_area_ha ///
             (firstnm) ea_id, by(hh_id parcel_id)
    replace n_fields = 0 if missing(n_fields)
    tempfile parcels
    save `parcels', replace

    *==========================================================================
    * (B) weights + design strata  (built per wave; merged on hh_id)
    *==========================================================================
    * --- weights (and, for 2017, the official stratum) ---
    use "${Input}/Mali/`fold'/`wtfile'", clear
    egen hh_id = concat(`wtkey'), punct("-")
    rename `wtvar' weight
    if `w'==2 {
        capture confirm variable strate
        if !_rc  rename strate strataid
        else     gen strataid = .
        keep hh_id weight strataid
    }
    else keep hh_id weight
    duplicates drop
    bys hh_id (weight): keep if _n==1
    tempfile wts
    save `wts', replace

    * --- 2014 has no `strate` in its own files: build region x milieu from cover ---
    if `w'==1 {
        use "${Input}/Mali/`fold'/`cover'", clear
        egen hh_id = concat(`hhparts'), punct("-")
        capture egen strataid = group(s00q01 s00q04)   // region x milieu (urban/rural)
        if _rc gen strataid = .
        keep hh_id strataid
        duplicates drop
        bys hh_id: keep if _n==1
        merge 1:1 hh_id using `wts', nogen
        save `wts', replace
    }

    *==========================================================================
    * (C) assemble
    *==========================================================================
    use `parcels', clear
    merge m:1 hh_id using `wts', keep(master match) nogen

    gen str20 country = "Mali"
    gen int  wave = `w'
    gen int  year = `year'

    _mlifinal
    tempfile mli`w'
    save `mli`w'', replace
}

*================================================================================
* APPEND waves
*================================================================================
use `mli1', clear
append using `mli2'
label data "Mali EACI 2014 & 2017: PARCEL-level rental/tenure descriptives (built `c(current_date)')"
compress
save "${Final}/rental_MLI.dta", replace

*================================================================================
* QC
*================================================================================
di as txt _n "================  MALI QC (parcel level)  ================"
tab country wave
egen _psu   = group(wave ea_id)
egen _strat = group(wave strataid)
svyset _psu [pw=weight], strata(_strat) singleunit(centered)
foreach v in parcel_rentedin parcel_certificate parcel_purchased {
    svy: mean `v', over(year)
}
di as txt _n "(parcel_rentedout is missing for Mali by design - not estimated)"
table wave, stat(mean parcel_area_ha) stat(p50 parcel_area_ha) stat(count parcel_area_ha) nformat(%7.3f)
capture mdesc parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased parcel_area_ha weight

exit
