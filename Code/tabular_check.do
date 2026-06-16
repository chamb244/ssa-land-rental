/*********************************************************************************
* tabular_check.do  -- QC / descriptive tables for the pooled rental dataset
* Run AFTER MASTER.do (it uses ${Final}); or set ${Final} / edit the path and run
* standalone.
*--------------------------------------------------------------------------------
* Reports design-weighted tenure participation rates BY COUNTRY and survey year,
* plus cultivated parcel area and a missingness check.
*********************************************************************************/

use "${Final}/rental_tenure_ALL.dta", clear

*--------------------------------------------------------------------------------
* Survey design. PSU (ea_id) and stratum (strataid) codes repeat across countries
* and waves, so make them unique by country x wave before svyset.
*--------------------------------------------------------------------------------
egen _psu   = group(country wave ea_id)
egen _strat = group(country wave strataid)
svyset _psu [pw=weight], strata(_strat) singleunit(centered)

*--------------------------------------------------------------------------------
* Sample sizes
*--------------------------------------------------------------------------------
tab country wave

*--------------------------------------------------------------------------------
* Design-weighted participation rates, BY COUNTRY, one variable per call.
* One-variable-per-call is deliberate: a joint svy:mean uses casewise deletion and
* would silently drop country-waves where a variable is unmeasured (e.g. purchase
* in Ethiopia 2012-14 and Malawi 2019, certificate in Ethiopia w1 / Malawi w1,w4).
*--------------------------------------------------------------------------------
levelsof country, local(countries)

foreach c of local countries {
    di as txt _n "{hline 64}"
    di as txt "  `c'  --  design-weighted participation rates by survey year"
    di as txt "{hline 64}"
    foreach v in parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased {
        di as txt _n ">> `v'"
        capture svy, subpop(if country=="`c'"): mean `v', over(year)
        if _rc di as error "   (not estimable for `c' - all missing)"
    }
}

*--------------------------------------------------------------------------------
* Cultivated parcel area (ha), by country x wave
*--------------------------------------------------------------------------------
di as txt _n "================  parcel area (ha)  ================"
table country wave, stat(mean parcel_area_ha) stat(p50 parcel_area_ha) ///
    stat(count parcel_area_ha) nformat(%7.3f)

*--------------------------------------------------------------------------------
* Missingness, by country
*--------------------------------------------------------------------------------
foreach c of local countries {
    di as txt _n "-- missingness: `c' --"
    capture mdesc parcel_rentedin parcel_rentedout parcel_certificate ///
        parcel_purchased parcel_area_ha weight if country=="`c'"
}

*--------------------------------------------------------------------------------
* COMPACT country x year means table (weighted point estimates = svy means),
* easy to scan for plausibility. Also written to CSV.
*--------------------------------------------------------------------------------
preserve
    gen byte _n1 = 1
    collapse (mean) parcel_rentedin parcel_rentedout parcel_certificate ///
        parcel_purchased parcel_area_ha (rawsum) n_parcels = _n1 [aw=weight], ///
        by(country year)
    format parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased %6.3f
    format parcel_area_ha %7.3f
    list country year n_parcels parcel_rentedin parcel_rentedout ///
        parcel_certificate parcel_purchased parcel_area_ha, sepby(country) noobs abbrev(16)
    export delimited country year n_parcels parcel_rentedin parcel_rentedout ///
        parcel_certificate parcel_purchased parcel_area_ha ///
        using "${Final}/qc_means_by_country_year.csv", replace
restore

di as txt _n "{hline 78}"
di as txt "NOTES (see Reference/variable_provenance.md):"
di as txt "Structural missings ('.' = question not asked that round; exclude, do NOT treat as 0):"
di as txt "  Ethiopia parcel_purchased   : 2012, 2014  (no 'purchased' category until 2016)"
di as txt "  Malawi   parcel_certificate : 2010, 2019  (no title/document question those rounds)"
di as txt "  Malawi   parcel_purchased   : 2019        ('how acquired' question dropped in 2019)"
di as txt "  Mali     parcel_rentedout   : 2014, 2017  (rented-out land out of EACI's operated frame)"
di as txt "  Nigeria  parcel_certificate : 2011        (no certificate question in GHS wave 1)"
di as txt "parcel_area_ha is TOP-CODED at ${area_max} ha: data-entry outliers set missing (means"
di as txt "  affected, medians not). Rented-out also undercounts for Mali/Niger/Nigeria-w1."
di as txt "{hline 78}"

exit   // stop cleanly at end-of-file; ignore anything after this line
