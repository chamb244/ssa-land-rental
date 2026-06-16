/*********************************************************************************
* tables_graphs.do  -- descriptive TABLES + TREND GRAPHS for the ARRE paper
* Run AFTER MASTER.do (uses ${Final}/rental_tenure_ALL.dta). Standalone: set the
* paths below and run.
*--------------------------------------------------------------------------------
* Produces, design-weighted, BY COUNTRY x SURVEY YEAR (season 1), for the four
* indicators (rented-in, rented-out, purchased, has-certificate):
*   (1) share of HOUSEHOLDS with >=1 plot of that type   [svy: mean on a HH collapse]
*   (2) share of PLOTS of that type                       [svy: mean, plot level]
*   (3) share of farm AREA (ha) of that type              [svy: ratio of area totals]
* and a faceted-by-country trend graph (plot level) with 95% CIs.
*
* Structural missings (e.g. ETH purchase 2012/14) stay BLANK - one variable per
* cell, so they are never silently treated as 0.
*
* Design: svyset _psu [pw=weight], strata(_strat), with _psu/_strat unique by
* country x wave; singleunit(centered) so single-PSU strata contribute 0 variance.
*********************************************************************************/

cap log close _all
clear all
set more off

* ---- paths (reuse MASTER globals if present; else set here) --------------------
if "${Final}"=="" {
    global root "/Users/jchamberlin/Library/CloudStorage/Dropbox/SSA-pooled-survey-data"
    capture confirm file "${root}/ssa-land-rental/Code/MASTER.do"
    if _rc global root "/Users/jchamberlin/Library/CloudStorage/Dropbox/LSMS-ISA-harmonised-dataset-on-agricultural-productivity-and-welfare"
    global Final "${root}/ssa-land-rental/Output/Final"
}
global Tables  "`=subinstr("${Final}","/Final","/Tables",1)'"
global Figures "`=subinstr("${Final}","/Final","/Figures",1)'"
cap mkdir "${Tables}"
cap mkdir "${Figures}"

local INDS   parcel_rentedin parcel_rentedout parcel_purchased parcel_certificate
local NICE   `""Rented-in" "Rented-out" "Purchased" "Has certificate""'

*================================================================================
* Load, restrict to reported season, set the survey design
*================================================================================
use "${Final}/rental_tenure_ALL.dta", clear
keep if season==1
egen _psu   = group(country wave ea_id)
egen _strat = group(country wave strataid)
egen ccode  = group(country)
svyset _psu [pw=weight], strata(_strat) singleunit(centered)

tempfile PLOT
save `PLOT', replace

* household collapse: 1 row per country-wave-hh; indicator = max over its season-1 plots
use `PLOT', clear
collapse (max) `INDS' (firstnm) weight _psu _strat year ccode, by(country wave hh_id)
svyset _psu [pw=weight], strata(_strat) singleunit(centered)
tempfile HH
save `HH', replace

*================================================================================
* Collect estimates (est, lo, hi) into one long file via postfile
*================================================================================
tempname P
postfile `P' str9 level str20 country year str20 indicator double est lo hi ///
    using "${Tables}/_est_long.dta", replace

* helper values for area-share numerator/denominator (per indicator) built inline
foreach lvl in plot hh area {
    if "`lvl'"=="hh" use `HH', clear
    else             use `PLOT', clear

    levelsof ccode, local(cs)
    foreach c of local cs {
        levelsof country if ccode==`c', local(_cn) clean
        local cname `_cn'
        levelsof year if ccode==`c', local(ys)
        foreach y of local ys {
            foreach v of local INDS {
                local est = .
                local lo = .
                local hi = .
                if "`lvl'"=="area" {
                    * area share = sum(w*area*1{v}) / sum(w*area), design-based ratio
                    capture drop _num _den
                    gen double _num = parcel_area_ha*`v'
                    gen double _den = parcel_area_ha if !missing(`v')
                    capture svy, subpop(if ccode==`c' & year==`y'): ratio _num/_den
                }
                else {
                    capture svy, subpop(if ccode==`c' & year==`y'): mean `v'
                }
                if !_rc {
                    matrix _t = r(table)
                    local est = _t[1,1]
                    local lo  = _t[5,1]
                    local hi  = _t[6,1]
                }
                post `P' ("`lvl'") ("`cname'") (`y') ("`v'") (`est') (`lo') (`hi')
            }
        }
    }
}
postclose `P'

*================================================================================
* Wide tables (rows country-year, cols 4 indicators) -> CSV + Excel
*================================================================================
use "${Tables}/_est_long.dta", clear
gen ind = .
replace ind = 1 if indicator=="parcel_rentedin"
replace ind = 2 if indicator=="parcel_rentedout"
replace ind = 3 if indicator=="parcel_purchased"
replace ind = 4 if indicator=="parcel_certificate"
label define IND 1 "Rented-in" 2 "Rented-out" 3 "Purchased" 4 "Has certificate"
label values ind IND

foreach lvl in hh plot area {
    preserve
        keep if level=="`lvl'"
        keep country year ind est
        reshape wide est, i(country year) j(ind)
        rename (est1 est2 est3 est4) (rentedin rentedout purchased certificate)
        label var rentedin "Rented-in"
        label var rentedout "Rented-out"
        label var purchased "Purchased"
        label var certificate "Has certificate"
        sort country year
        export delimited using "${Tables}/table_`lvl'_share.csv", replace
        export excel using "${Tables}/tenure_share_tables.xlsx", ///
            sheet("`lvl'_share") sheetreplace firstrow(variables)
    restore
}

*================================================================================
* Faceted-by-country trend graph (PLOT level) with 95% CI bands
*================================================================================
use "${Tables}/_est_long.dta", clear
keep if level=="plot"
encode country, gen(cn)
levelsof cn, local(cns)
local glist
foreach c of local cns {
    local cname : label (cn) `c'
    local g g_`c'
    twoway ///
        (rarea lo hi year if cn==`c' & indicator=="parcel_rentedin",    color(blue%15) lwidth(none)) ///
        (rarea lo hi year if cn==`c' & indicator=="parcel_rentedout",   color(red%15) lwidth(none)) ///
        (rarea lo hi year if cn==`c' & indicator=="parcel_purchased",   color(green%15) lwidth(none)) ///
        (rarea lo hi year if cn==`c' & indicator=="parcel_certificate", color(purple%15) lwidth(none)) ///
        (connected est year if cn==`c' & indicator=="parcel_rentedin",    color(blue)   msize(small)) ///
        (connected est year if cn==`c' & indicator=="parcel_rentedout",   color(red)    msize(small)) ///
        (connected est year if cn==`c' & indicator=="parcel_purchased",   color(green)  msize(small)) ///
        (connected est year if cn==`c' & indicator=="parcel_certificate", color(purple) msize(small)), ///
        title("`cname'", size(medsmall)) legend(off) ylabel(, angle(0)) ///
        xtitle("") ytitle("share of plots") name(`g', replace) nodraw
    local glist `glist' `g'
}
graph combine `glist', cols(4) ycommon ///
    title("Plot-level tenure & rental shares over time, by country (95% CI)") ///
    note("rented-in (blue), rented-out (red), purchased (green), has-certificate (purple). Waves may not be strictly comparable.")
graph export "${Figures}/trends_by_country_plot.png", replace width(2400)

di as txt _n "Done: tables in ${Tables}, figure in ${Figures}."
exit
