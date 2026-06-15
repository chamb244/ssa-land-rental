egen _psu   = group(wave ea_id)
egen _strat = group(wave strataid)
svyset _psu [pw=weight], strata(_strat) singleunit(centered)
svy: mean parcel_rentedin parcel_rentedout parcel_certificate parcel_purchased, over(year)

