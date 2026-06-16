/*********************************************************************************
* extract_NER.do  -- Niger (ECVMA 2011 & 2014)  -- PARCEL-LEVEL
* Part of ssa-land-rental.  Run via MASTER.do (needs globals set).
* Paths use forward slashes (work in Stata on Mac/Windows/Linux).
*--------------------------------------------------------------------------------
* SOURCE: two ECVMA rounds (Enquete Nationale sur les Conditions de Vie). The 2014
* round uses UPPERCASE variable names (AS01Q*) and a 3-part household id; 2011 uses
* lowercase (as01q*) and a single `hid`. Some files are Latin-1 (French accents).
*   2011 roster = ecvmaas1_p1.dta   (as01q*)   hh = hid
*   2014 roster = ECVMA2_AS1P1.dta  (AS01Q*)   hh = GRAPPE-MENAGE-EXTENSION
*
* UNIT = PARCEL. Tenure, acquisition, disposition, title and area are all in the one
* parcel roster - no cross-module merge for the substantive variables.
*
* OUTPUT (per parcel): parcel_rentedin parcel_rentedout parcel_certificate
*   parcel_purchased parcel_area_ha n_fields + country wave year weight
*   strataid ea_id hh_id parcel_id
*
* CODES (verified against the raw French value labels):
*  Occupation mode  "Mode d'occupation de la parcelle":
*     2011 as01q16: 1 propriete | 2 pret(gratuit) | 3 hypotheque(gage) | 4 LOCATION | 5 autres
*     2014 AS01Q14: 1 propriete | 2 copropriete | 3 LOCATION | 4 hypotheque | 5 pret | 6 autres
*     -> parcel_rentedin = (occupation == LOCATION)   [2011: 4 ; 2014: 3]
*        Niger has NO sharecropping category, so rented-in = cash/fixed RENTAL only;
*        free loan (pret) and pledge (hypotheque) are excluded as non-market.
*  Acquisition mode  as01q19 / AS01Q18  "Mode d'acquisition de la parcelle":
*     1 Achat | 2 Heritage | 3 Don | 4 Prise de possession | 5 Autres | 9 manquant
*     -> parcel_purchased = (acq == 1)   (Achat; both waves)
*  Title document  as01q18 / AS01Q15  "Type de titre de propriete":
*     1 titre foncier | 2 certificat coutumier | 3 attestation de vente |
*     4 autre document | 5 aucun document | 9 manquant
*     -> parcel_certificate = inlist(.,1,2,3,4)  (any tenure document); 9 -> missing
*  Disposition (reason for NON-cultivation)  as01q41 / AS01Q39:
*     1 jachere | 2 prete a un autre | 3 hypothequee | 4 LOUEE a un autre | 5 autre
*     -> parcel_rentedout = (reason == 4)   (rented out for payment)
*
* CAVEATS (see provenance doc, Niger section):
*  - rented-out UNDERCOUNTS: it surfaces only via the "reason for non-cultivation"
*    path, so parcels rented out are largely under-represented in this operated-
*    parcel roster (weighted rate ~0.0-0.2%). Treat as a lower bound.
*  - 2011 and 2014 are independent cross-sections with different category schemes
*    and samples; rented-in levels are NOT directly comparable (14% vs 2.4%).
*
* AREA: GPS where measured, else self-reported (deterministic; no imputation).
*   self-reported & GPS are in m^2 (x0.0001 -> ha); 999999 = missing; GPS 0 = missing.
*
* DESIGN: 2011 weight/grappe/strate from the housing file; 2014 weight from the
*   consumption file, region (proxy stratum) from the cover. ea_id = grappe (PSU).
*********************************************************************************/

capture program drop _nerfinal
program define _nerfinal
    label var country          "Country"
    label var wave             "Survey wave"
    label var year             "Survey year"
    label var weight           "Household survey weight"
    label var parcel_rentedin    "Parcel rented IN (location; 0/1)"
    label var parcel_rentedout   "Parcel rented OUT (0/1; undercount - lower bound)"
    label var parcel_certificate "Parcel has a tenure document (0/1)"
    label var parcel_purchased   "Parcel acquired through purchase (0/1)"
    label var parcel_area_ha     "Parcel area, ha (GPS, else self-reported)"
    label var n_fields           "Number of parcel records aggregated"
    label var ea_id              "Enumeration cluster / grappe (survey PSU)"
    label var strataid           "Survey design stratum"
    keep country wave year weight strataid ea_id hh_id parcel_id parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased parcel_area_ha n_fields
    order country wave year weight strataid ea_id hh_id parcel_id ///
          parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased ///
          parcel_area_ha n_fields
end

forvalues w = 1/2 {

    if `w'==1 {
        local fold   "ECVMA 11"
        local year   2011
        local roster ecvmaas1_p1.dta
        local hhcat  hid
        local plotcat hid as01q03 as01q05
        local occ    as01q16
        local rincode 4
        local acq    as01q19
        local titlev as01q18
        local routv  as01q41
        local gpsv   as01q09
        local srv    as01q08
    }
    else if `w'==2 {
        local fold   "ECVMA 14"
        local year   2014
        local roster ECVMA2_AS1P1.dta
        local hhcat  GRAPPE MENAGE EXTENSION
        local plotcat GRAPPE MENAGE EXTENSION AS01Q01 AS01Q03
        local occ    AS01Q14
        local rincode 3
        local acq    AS01Q18
        local titlev AS01Q15
        local routv  AS01Q39
        local gpsv   AS01Q07
        local srv    AS01Q06
    }

    di as txt _n "=================  NIGER  wave `w'  (`year')  ================="

    *==========================================================================
    * (A) PARCEL roster: tenure, acquisition, title, disposition, area
    *==========================================================================
    use "${Input}/Niger/`fold'/`roster'", clear
    egen hh_id     = concat(`hhcat'), punct("-")
    egen parcel_id = concat(`plotcat'), punct("-")

    gen byte parcel_rentedin  = (`occ'==`rincode')
    gen byte parcel_purchased = (`acq'==1)
    replace  parcel_purchased = . if `acq'==9 | mi(`acq')
    gen byte parcel_certificate = inlist(`titlev',1,2,3,4)
    replace  parcel_certificate = . if `titlev'==9 | mi(`titlev')
    gen byte parcel_rentedout = (`routv'==4)      // cultivated parcels -> 0 (reason missing)

    * area: GPS else self-reported (m^2 -> ha)
    gen gps = `gpsv' * 0.0001
    replace gps = . if `gpsv'==999999 | `gpsv'==0
    gen sr  = `srv' * 0.0001
    replace sr  = . if `srv'==999999
    gen plot_area_ha = gps
    replace plot_area_ha = sr if missing(plot_area_ha)

    collapse (max) parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased ///
             (sum) parcel_area_ha = plot_area_ha (count) n_fields = plot_area_ha, ///
             by(hh_id parcel_id)
    replace n_fields = 0 if missing(n_fields)
    tempfile parcels
    save `parcels', replace

    *==========================================================================
    * (B) weights / PSU / strata  (per-wave sources; merged on hh_id)
    *==========================================================================
    if `w'==1 {
        * 2011: housing file carries hid + hhweight + grappe + strate
        use "${Input}/Niger/`fold'/ecvmamen_p1_en.dta", clear
        egen hh_id = concat(hid), punct("-")
        rename hhweight weight
        egen ea_id = concat(grappe)
        rename strate strataid
        keep hh_id weight ea_id strataid
    }
    else {
        * 2014: weight from consumption; region (proxy stratum) + grappe from cover
        use "${Input}/Niger/`fold'/ECVMA2014_P1P2_ConsoMen.dta", clear
        egen hh_id = concat(GRAPPE MENAGE EXTENSION), punct("-")
        rename hhweight weight
        keep hh_id weight
        tempfile wtonly
        save `wtonly', replace
        use "${Input}/Niger/`fold'/ECVMA2_MS00P1.dta", clear
        egen hh_id = concat(GRAPPE MENAGE EXTENSION), punct("-")
        egen ea_id = concat(GRAPPE)
        capture confirm variable MS00Q01
        if !_rc rename MS00Q01 strataid
        else gen strataid = .
        keep hh_id ea_id strataid
        merge 1:1 hh_id using `wtonly', nogen
    }
    duplicates drop
    bys hh_id (weight): keep if _n==1
    tempfile hhattr
    save `hhattr', replace

    *==========================================================================
    * (C) assemble
    *==========================================================================
    use `parcels', clear
    merge m:1 hh_id using `hhattr', keep(master match) nogen
    gen str20 country = "Niger"
    gen int  wave = `w'
    gen int  year = `year'
    _nerfinal
    tempfile ner`w'
    save `ner`w'', replace
}

*================================================================================
* APPEND waves
*================================================================================
use `ner1', clear
append using `ner2'
label data "Niger ECVMA 2011 & 2014: PARCEL-level rental/tenure descriptives (built `c(current_date)')"
compress
* top-code implausible plot areas (data-entry outliers); threshold in MASTER
if "${area_max}"=="" global area_max 40
replace parcel_area_ha = . if parcel_area_ha > ${area_max} & !missing(parcel_area_ha)
save "${Final}/rental_NER.dta", replace

*================================================================================
* QC
*================================================================================
di as txt _n "================  NIGER QC (parcel level)  ================"
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
