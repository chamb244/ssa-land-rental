/*********************************************************************************
* extract_ZMB.do  -- Zambia RALS (2012, 2015, 2019)  -- FIELD-LEVEL
* Part of ssa-land-rental.  Run via MASTER.do (needs globals set).
* Paths use forward slashes (work in Stata on Mac/Windows/Linux).
*--------------------------------------------------------------------------------
* SOURCE: Rural Agricultural Livelihoods Survey (RALS), IAPRI / Indaba - a
* NON-LSMS-ISA national panel. Three rounds: RALS 2012, 2015, 2019 (folders
* "RALS 12|15|19"). The land roster is the per-field file `field.dta` in EVERY
* round; it INCLUDES rented-out and borrowed-out fields, so rented-out is observed
* at field level (unlike Mali/Niger). Variable names are UPPERCASE in 2012
* (`F01` ...), lowercase from 2015 (`f01` ...).
*
* UNIT = FIELD (single level; key cluster-hh-field). One agricultural season only
*   -> season = 1 for all of Zambia.
*
* OUTPUT (per field): parcel_rentedin parcel_rentedout parcel_certificate
*   parcel_purchased parcel_area_ha n_fields + country wave year season weight
*   strataid ea_id hh_id parcel_id
*
* CODES (verified against raw value labels per wave):
*   F01 "Land use of this field": 1 own-cultivated | 2 RENTED-IN (cash or in-kind,
*       i.e. incl. sharecropping) | 3 borrowed-in | 4 garden | 5 fallow |
*       6 RENTED-OUT | 7 borrowed-out | 8 orchard | 9 virgin | ... (2019 adds 14)
*     -> parcel_rentedin  = (F01==2)   (rented in; SHARECROP INCLUDED)
*     -> parcel_rentedout = (F01==6)
*       (borrowed in/out, codes 3/7, are NON-market and are NOT rented.)
*   F06 "How acquired": 1 Purchased | 2 inherited | 3 allocated/given |
*       4 rented/borrowed (2012 only) | 5 walked in | 6 other
*     -> parcel_purchased = (F06==1)
*   F05 "Tenure status" - CATEGORIES EXPAND from 6 (2012) to 9 (2015/2019) and the
*       code numbers do NOT line up, so the titled flag is built PER WAVE:
*       2012:      titled {1,2}            untitled {3,7}        DK/other {4,5}
*       2015/2019: titled {1,2,4,5}        untitled {3,6}        DK/other/NC {8,9,-8}
*                  + code 7 = "Chief certificate" (no 2012 analogue)
*     -> parcel_certificate = 1 (formal land title), 0 (no title), . (DK/other/NC)
*       "Chief certificate" (2015/19 code 7) is, by DEFAULT, NOT counted as a formal
*       certificate (0), to stay comparable with 2012 which has no such category.
*       Set  global zmb_chief_cert 1  in MASTER to instead count it as a certificate.
*
* AREA: `hect` (already converted to hectares; else F02 x convert). Top-coded at
*   ${area_max} ha (MASTER).  n_fields = 1 (field-level; no aggregation).
*
* DESIGN: cross-sectional weight - 2012 `weight` (merged from id.dta on cluster-hh);
*   2015 `popwgt` (population weight, on field.dta); 2019 only a single `weight`
*   (labelled "Panel Weight" - no population weight in this release, see caveats).
*   ea_id = cluster (PSU); strataid = dist (district stratum); both on field.dta.
*********************************************************************************/

if "${zmb_chief_cert}"=="" global zmb_chief_cert 0   // 0 = chief cert NOT a title (default)

capture program drop _zmbfinal
program define _zmbfinal
    label var country          "Country"
    label var wave             "RALS wave number"
    label var year             "Survey year"
    label var season           "Cropping season (Zambia: single season = 1)"
    label var weight           "Household survey weight (cross-sectional; 2019 = panel)"
    label var parcel_rentedin    "Field rented IN (cash or in-kind; 0/1)"
    label var parcel_rentedout   "Field rented OUT (0/1)"
    label var parcel_certificate "Field has a formal land title (0/1; . if DK/other)"
    label var parcel_purchased   "Field acquired through purchase (0/1)"
    label var parcel_area_ha     "Field area, ha (hect, else self-reported x conversion)"
    label var n_fields           "Number of field records aggregated (=1)"
    label var ea_id              "Enumeration cluster (survey PSU)"
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

*================================================================================
* WAVE LOOP
*================================================================================
forvalues k = 1/3 {

    if `k'==1 {            // RALS 2012  (UPPERCASE variables)
        local fold "RALS 12"
        local wv 1
        local year 2012
        local f01 F01
        local f05 F05
        local f06 F06
        local f02 F02
        local hectv hect
        local convv convert
        local wvar weight
        local wmerge 1     // weight lives in id.dta (merge on cluster-hh)
    }
    else if `k'==2 {       // RALS 2015  (lowercase variables)
        local fold "RALS 15"
        local wv 2
        local year 2015
        local f01 f01
        local f05 f05
        local f06 f06
        local f02 f02
        local hectv hect
        local convv convert
        local wvar popwgt   // population (cross-sectional) weight, on field.dta
        local wmerge 0
    }
    else if `k'==3 {       // RALS 2019  (lowercase variables)
        local fold "RALS 19"
        local wv 3
        local year 2019
        local f01 f01
        local f05 f05
        local f06 f06
        local f02 f02
        local hectv hect
        local convv convert
        local wvar weight   // single weight (panel) on field.dta - no popwgt this round
        local wmerge 0
    }

    di as txt _n "=================  ZAMBIA  RALS wave `wv'  (`year')  ================="

    use "${Input}/Zambia/`fold'/field.dta", clear
    foreach v in `f01' `f05' `f06' `f02' `hectv' `convv' cluster hh field dist {
        capture confirm variable `v'
        if _rc gen `v' = .
    }

    * identifiers
    egen hh_id     = concat(cluster hh), punct("-")
    egen parcel_id = concat(cluster hh field), punct("-")

    * tenure flags
    gen byte parcel_rentedin  = (`f01'==2)            // rented in (cash/in-kind = incl. sharecrop)
    gen byte parcel_rentedout = (`f01'==6)            // rented out
    gen byte parcel_purchased = (`f06'==1)
    replace  parcel_purchased = . if missing(`f06')

    * certificate (formal title) - per-wave category map
    gen byte parcel_certificate = .
    if `wv'==1 {                                       // 2012 scheme
        replace parcel_certificate = 1 if inlist(`f05',1,2)
        replace parcel_certificate = 0 if inlist(`f05',3,7)
    }
    else {                                             // 2015 / 2019 scheme
        replace parcel_certificate = 1 if inlist(`f05',1,2,4,5)
        replace parcel_certificate = 0 if inlist(`f05',3,6)
        replace parcel_certificate = cond("${zmb_chief_cert}"=="1",1,0) if `f05'==7
    }

    * area: hectares (else self-reported amount x conversion factor)
    gen double parcel_area_ha = `hectv'
    capture replace parcel_area_ha = `f02' * `convv' if missing(parcel_area_ha) & !missing(`f02') & !missing(`convv')
    replace parcel_area_ha = . if parcel_area_ha<=0

    gen int n_fields = 1

    * design variables (on field.dta in every round)
    egen ea_id = concat(cluster)
    capture confirm variable dist
    if _rc gen strataid = .
    else   egen strataid = group(dist)

    * weight
    if `wmerge'==1 {
        tempfile fields
        save `fields', replace
        use "${Input}/Zambia/`fold'/id.dta", clear
        keep cluster hh `wvar'
        duplicates drop
        bys cluster hh: keep if _n==1
        tempfile wt
        save `wt', replace
        use `fields', clear
        merge m:1 cluster hh using `wt', keep(master match) nogen
        rename `wvar' weight
    }
    else {
        capture confirm variable `wvar'
        if _rc gen double weight = .
        else   rename `wvar' weight
    }

    * identifiers / season
    gen str20 country = "Zambia"
    gen int  wave = `wv'
    gen int  year = `year'
    gen byte season = 1

    _zmbfinal
    tempfile zmb`k'
    save `zmb`k'', replace
}

*================================================================================
* APPEND waves
*================================================================================
use `zmb1', clear
append using `zmb2'
append using `zmb3'
label data "Zambia RALS 2012/2015/2019: FIELD-level rental/tenure descriptives (built `c(current_date)')"
compress
if "${area_max}"=="" global area_max 40
replace parcel_area_ha = . if parcel_area_ha > ${area_max} & !missing(parcel_area_ha)
save "${Final}/rental_ZMB.dta", replace

*================================================================================
* QC
*================================================================================
di as txt _n "================  ZAMBIA QC (field level)  ================"
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
capture mdesc parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased parcel_area_ha weight

exit
