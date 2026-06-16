/*********************************************************************************
* extract_UGA.do  -- Uganda (UNPS 2009,2010,2011,2013,2015,2018,2019) -- PARCEL-LEVEL
* Part of ssa-land-rental.  Run via MASTER.do (needs globals set).
* Paths use forward slashes (work in Stata on Mac/Windows/Linux).
*--------------------------------------------------------------------------------
* SOURCE: 7 UNPS rounds. Land roster is split into TWO modules per round:
*   AGSEC2A = parcels OWNED / held with use-rights by the household
*   AGSEC2B = parcels ACCESSED for use but NOT owned (rented / borrowed in)
* These are DISJOINT parcel sets, so we STACK (append) them into one parcel frame,
* tagging origin in the parcel_id (-A- owned, -B- accessed).
*
* UNIT = PARCEL. Output (per parcel x season): parcel_rentedin parcel_rentedout
*   parcel_certificate parcel_purchased parcel_area_ha n_fields + country wave year
*   season weight strataid ea_id hh_id parcel_id
*
* SEASONS: the parcel roster (tenure, certificate, purchase, area) is ANNUAL and
* identical across the two cropping seasons; ONLY rented-out is season-specific
* (it is read from the per-season "primary use of parcel" item, code 3). We expand
* each parcel to season==1 and season==2 rows that are identical EXCEPT
* parcel_rentedout. The paper reports season 1; tabular_check filters season==1.
*   *** SEASON ORDER IS SWAPPED in 2015, 2018, 2019: there the "...b" primary-use
*       variable is the 1ST season and "...a" is the 2ND. Handled per wave below.
*
* CODES (verified against raw value labels, per wave; names drift across rounds):
*   Acquisition (AGSEC2A): 1=Purchased 2=Inherited/gift 3=Leased-in 4=Walked-in
*       5=DK 6=Other (2018/19 add 7=given-by-gov 8=agreement 9=no-agreement 96=other)
*     -> parcel_purchased = (acq==1)
*     -> parcel_rentedin  = (acq==3)  among OWNED parcels (a longer-term lease-in)
*   Certificate/title (AGSEC2A): 1=Cert of title 2=Cert of customary ownership
*       3=Cert of occupancy 4=No document
*     -> parcel_certificate = inlist(.,1,2,3); ==4 -> 0; missing -> .
*       (AGSEC2B accessed parcels are NOT asked -> set 0: household holds no title)
*   Rent PAID to owner (AGSEC2B): shillings  -> parcel_rentedin = (rent_paid>0)
*   Primary use of parcel, per season: code 3 = "Rented-out" (2A) /
*       "Sub-contracted out" (2B)  -> parcel_rentedout (season-specific)
*
* AREA: GPS where measured, else self-reported. Both are in ACRES -> ha x 0.404686.
*   (Deterministic: no pmm imputation, unlike the full harmonisation pipeline.)
*
* DESIGN: cross-sectional household weight + EA + stratum from each round's GSEC1
*   cover. EA (comm/ea) absent in 2018/2019 -> ea_id left blank there; point
*   estimates use weights. strataid = stratum (09/10) / sub-region (11/13/15) /
*   region (18/19).
*********************************************************************************/

capture program drop _ugafinal
program define _ugafinal
    label var country          "Country"
    label var wave             "UNPS wave number"
    label var year             "Survey year (start of agricultural year)"
    label var season           "Cropping season (1 reported in paper; 2 also computed)"
    label var weight           "Household cross-sectional survey weight"
    label var parcel_rentedin    "Parcel rented/leased IN (0/1)"
    label var parcel_rentedout   "Parcel rented/sub-contracted OUT this season (0/1)"
    label var parcel_certificate "Parcel has a title/certificate (0/1; 0 for accessed parcels)"
    label var parcel_purchased   "Parcel acquired through purchase (0/1)"
    label var parcel_area_ha     "Parcel area, ha (GPS, else self-reported)"
    label var n_fields           "Number of parcel records aggregated (=1)"
    label var ea_id              "Enumeration area (survey PSU; blank 2018/2019)"
    label var strataid           "Survey design stratum"
    * harmonise id types to string so country files append cleanly into the pool
    capture confirm string variable parcel_id
    if _rc tostring parcel_id, replace force
    capture confirm string variable hh_id
    if _rc tostring hh_id, replace force
    keep country wave year season weight strataid ea_id hh_id parcel_id parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased parcel_area_ha n_fields
    order country wave year season weight strataid ea_id hh_id parcel_id ///
          parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased ///
          parcel_area_ha n_fields
end

*================================================================================
* WAVE LOOP  (k = position; wv = canonical UNPS wave number)
*================================================================================
forvalues k = 1/7 {

    if `k'==1 {        // 2009  (UNPS 09)
        local fold "UNPS 09"
        local wv 1
        local year 2009
        local Af "2009_AGSEC2A.dta"
        local Bf "2009_AGSEC2B.dta"
        local Cf "2009_GSEC1.dta"
        local hhA Hhid
        local pidA A2aq2
        local aG A2aq4
        local aS A2aq5
        local acq A2aq8
        local cert A2aq25
        local uA1 A2aq13a
        local uA2 A2aq13b
        local hhB Hhid
        local pidB A2bq2
        local bG A2bq4
        local bS A2bq5
        local rpaid A2bq9
        local uB1 A2bq15a
        local uB2 A2bq15b
        local chh HHID
        local cea comm
        local cstr stratum
        local cwt wgt09
    }
    else if `k'==2 {   // 2010  (UNPS 10)
        local fold "UNPS 10"
        local wv 2
        local year 2010
        local Af "AGSEC2A.dta"
        local Bf "AGSEC2B.dta"
        local Cf "GSEC1.dta"
        local hhA HHID
        local pidA prcid
        local aG a2aq4
        local aS a2aq5
        local acq a2aq8
        local cert a2aq25
        local uA1 a2aq13a
        local uA2 a2aq13b
        local hhB HHID
        local pidB prcid
        local bG a2bq4
        local bS a2bq5
        local rpaid a2bq9
        local uB1 a2bq15a
        local uB2 a2bq15b
        local chh HHID
        local cea comm
        local cstr stratum
        local cwt wgt10
    }
    else if `k'==3 {   // 2011  (UNPS 11)
        local fold "UNPS 11"
        local wv 3
        local year 2011
        local Af "AGSEC2A.dta"
        local Bf "AGSEC2B.dta"
        local Cf "GSEC1.dta"
        local hhA HHID
        local pidA parcelID
        local aG a2aq4
        local aS a2aq5
        local acq a2aq8
        local cert a2aq23
        local uA1 a2aq11a
        local uA2 a2aq11b
        local hhB HHID
        local pidB parcelID
        local bG a2bq4
        local bS a2bq5
        local rpaid a2bq9
        local uB1 a2bq12a
        local uB2 a2bq12b
        local chh HHID
        local cea comm
        local cstr sregion
        local cwt mult
    }
    else if `k'==4 {   // 2013  (UNPS 13)
        local fold "UNPS 13"
        local wv 4
        local year 2013
        local Af "AGSEC2A.dta"
        local Bf "AGSEC2B.dta"
        local Cf "GSEC1.dta"
        local hhA hh
        local pidA parcelID
        local aG a2aq4
        local aS a2aq5
        local acq a2aq8
        local cert a2aq23
        local uA1 a2aq11a
        local uA2 a2aq11b
        local hhB hh
        local pidB parcelID
        local bG a2bq4
        local bS a2bq5
        local rpaid a2bq9
        local uB1 a2bq12a
        local uB2 a2bq12b
        local chh hhid
        local cea ea
        local cstr sregion
        local cwt wgt_X
    }
    else if `k'==5 {   // 2015  (UNPS 15)  *** season order SWAPPED ***
        local fold "UNPS 15"
        local wv 5
        local year 2015
        local Af "AGSEC2A.dta"
        local Bf "AGSEC2B.dta"
        local Cf "gsec1.dta"
        local hhA hhid
        local pidA parcelID
        local aG a2aq4
        local aS a2aq5
        local acq a2aq8
        local cert a2aq23
        local uA1 a2aq11b
        local uA2 a2aq11a
        local hhB hhid
        local pidB parcelID
        local bG a2bq4
        local bS a2bq5
        local rpaid a2bq9
        local uB1 a2bq12b
        local uB2 a2bq12a
        local chh hhid
        local cea ea
        local cstr sregion
        local cwt h_xwgt_W5
    }
    else if `k'==6 {   // 2018  (UNPS 18)  *** season order SWAPPED ***
        local fold "UNPS 18"
        local wv 7
        local year 2018
        local Af "AGSEC2A.dta"
        local Bf "AGSEC2B.dta"
        local Cf "GSEC1.dta"
        local hhA hhid
        local pidA parcelID
        local aG s2aq4
        local aS s2aq5
        local acq s2aq8
        local cert s2aq23
        local uA1 s2aq11b
        local uA2 s2aq11a
        local hhB hhid
        local pidB parcelID
        local bG s2aq04
        local bS s2aq05
        local rpaid a2bq09
        local uB1 a2bq12b
        local uB2 a2bq12a
        local chh hhid
        local cea ""
        local cstr region
        local cwt wgt
    }
    else if `k'==7 {   // 2019  (UNPS 19)  *** season order SWAPPED ; lowercase files ***
        local fold "UNPS 19"
        local wv 8
        local year 2019
        local Af "agsec2a.dta"
        local Bf "agsec2b.dta"
        local Cf "gsec1.dta"
        local hhA hhid
        local pidA parcelID
        local aG s2aq4
        local aS s2aq5
        local acq s2aq8
        local cert s2aq23
        local uA1 s2aq11b
        local uA2 s2aq11a
        local hhB hhid
        local pidB parcelID
        local bG s2aq04
        local bS s2aq05
        local rpaid a2bq09
        local uB1 a2bq12b
        local uB2 a2bq12a
        local chh hhid
        local cea ""
        local cstr region
        local cwt wgt
    }

    di as txt _n "=================  UGANDA  UNPS wave `wv'  (`year')  ================="

    *==========================================================================
    * (A) OWNED parcels  (AGSEC2A)
    *==========================================================================
    use "${Input}/Uganda/`fold'/`Af'", clear
    foreach v in `pidA' `aG' `aS' `acq' `cert' `uA1' `uA2' {
        capture confirm variable `v'
        if _rc gen `v' = .
    }
    capture confirm string variable `hhA'
    if _rc tostring `hhA', gen(hh_id) format("%17.0f")
    else gen hh_id = `hhA'
    egen _pid  = concat(`pidA')
    gen parcel_id = hh_id + "-A-" + _pid
    gen double gps = `aG' * 0.404686
    gen double sr  = `aS' * 0.404686
    replace gps = . if gps<=0
    replace sr  = . if sr <=0
    gen double parcel_area_ha = gps
    replace parcel_area_ha = sr if missing(parcel_area_ha)
    gen byte parcel_purchased   = (`acq'==1)
    replace  parcel_purchased   = . if missing(`acq')
    gen byte parcel_rentedin    = (`acq'==3)          // owned roster: leased-in
    gen byte parcel_certificate = inlist(`cert',1,2,3)
    replace  parcel_certificate = . if missing(`cert')
    gen byte rout_s1 = (`uA1'==3)                     // "Rented-out"
    gen byte rout_s2 = (`uA2'==3)
    keep hh_id parcel_id parcel_area_ha parcel_purchased parcel_rentedin ///
         parcel_certificate rout_s1 rout_s2
    tempfile owned
    save `owned', replace

    *==========================================================================
    * (B) ACCESSED parcels  (AGSEC2B)  -- rented / borrowed in
    *==========================================================================
    use "${Input}/Uganda/`fold'/`Bf'", clear
    foreach v in `pidB' `bG' `bS' `rpaid' `uB1' `uB2' {
        capture confirm variable `v'
        if _rc gen `v' = .
    }
    capture confirm string variable `hhB'
    if _rc tostring `hhB', gen(hh_id) format("%17.0f")
    else gen hh_id = `hhB'
    egen _pid  = concat(`pidB')
    gen parcel_id = hh_id + "-B-" + _pid
    gen double gps = `bG' * 0.404686
    gen double sr  = `bS' * 0.404686
    replace gps = . if gps<=0
    replace sr  = . if sr <=0
    gen double parcel_area_ha = gps
    replace parcel_area_ha = sr if missing(parcel_area_ha)
    gen byte parcel_purchased   = 0
    gen byte parcel_certificate = 0                   // not owned -> no HH title
    gen byte parcel_rentedin    = (`rpaid'>0 & !missing(`rpaid'))
    gen byte rout_s1 = (`uB1'==3)                     // "Sub-contracted out"
    gen byte rout_s2 = (`uB2'==3)
    keep hh_id parcel_id parcel_area_ha parcel_purchased parcel_rentedin ///
         parcel_certificate rout_s1 rout_s2

    *==========================================================================
    * (C) stack owned + accessed
    *==========================================================================
    append using `owned'

    *==========================================================================
    * (D) household design attributes from the cover (GSEC1)
    *==========================================================================
    preserve
        use "${Input}/Uganda/`fold'/`Cf'", clear
        capture confirm string variable `chh'
        if _rc tostring `chh', gen(hh_id) format("%17.0f")
        else gen hh_id = `chh'
        capture confirm variable `cwt'
        if _rc gen double weight = .
        else   gen double weight = `cwt'
        if "`cea'"=="" gen ea_id = ""
        else egen ea_id = concat(`cea')
        capture confirm variable `cstr'
        if _rc gen strataid = .
        else   egen strataid = group(`cstr')
        keep hh_id weight ea_id strataid
        duplicates drop
        bys hh_id (weight): keep if _n==1
        tempfile cover
        save `cover', replace
    restore
    merge m:1 hh_id using `cover', keep(master match) nogen

    *==========================================================================
    * (E) identifiers, season expansion, finalise
    *==========================================================================
    gen str20 country = "Uganda"
    gen int  wave = `wv'
    gen int  year = `year'
    gen int  n_fields = 1

    * 2018 (UNPS7): the owned-parcel acquisition item (s2aq8) was not recorded,
    * so purchase is missing by design that round (do NOT read as 0% purchased).
    if `wv'==7 replace parcel_purchased = .

    * one row per parcel-season; only rented-out differs across seasons
    gen byte season = 1
    expand 2, gen(_dup)
    replace season = 2 if _dup==1
    gen byte parcel_rentedout = rout_s1
    replace  parcel_rentedout = rout_s2 if season==2
    drop _dup rout_s1 rout_s2

    _ugafinal
    tempfile uga`k'
    save `uga`k'', replace
}

*================================================================================
* APPEND waves
*================================================================================
use `uga1', clear
forvalues k = 2/7 {
    append using `uga`k''
}
label data "Uganda UNPS (7 rounds): PARCEL x season rental/tenure descriptives (built `c(current_date)')"
compress
* top-code implausible parcel areas (data-entry outliers); threshold in MASTER
if "${area_max}"=="" global area_max 40
replace parcel_area_ha = . if parcel_area_ha > ${area_max} & !missing(parcel_area_ha)
save "${Final}/rental_UGA.dta", replace

*================================================================================
* QC  (season 1 = reported; season 2 also shown for rented-out)
*================================================================================
di as txt _n "================  UGANDA QC (parcel level)  ================"
tab year season
egen _psu   = group(wave ea_id)
egen _strat = group(wave strataid)
svyset _psu [pw=weight], strata(_strat) singleunit(centered)

di as txt _n "-- season 1 (reported): weighted participation rates by year --"
foreach v in parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased {
    di as txt _n ">> `v'"
    capture svy, subpop(if season==1): mean `v', over(year)
    if _rc di as error "   (not estimable)"
}
di as txt _n "-- rented-out: season 1 vs season 2 (unweighted means by year) --"
table year season, stat(mean parcel_rentedout) nformat(%6.3f)
di as txt _n "-- parcel area (ha), season 1 --"
table year if season==1, stat(mean parcel_area_ha) stat(p50 parcel_area_ha) ///
    stat(count parcel_area_ha) nformat(%7.3f)
capture mdesc parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased parcel_area_ha weight if season==1

exit
