*! version 1.0
* By Kerry Du, 29 Oct 2019  
capture program drop sbmeff
program define sbmeff, rclass
    version 16
	qui mata mata mlib index
    if strpos(`"`0'"',":")==0{  // Tone(2001) SBM without undesriable outputs
	   sbmeffnu `0'
	   exit
	   
	}	

    gettoken word 0 : 0, parse(" =:,")
    while `"`word'"' != ":" & `"`word'"' != "=" {
        if `"`word'"' == "," | `"`word'"'=="" {
                error 198
        }
		local invars `invars' `word'
		gettoken word 0 : 0, parse("=:,")
    }
    unab invars : `invars'

	gettoken word 0 : 0, parse(" =:,")
    while `"`word'"' != ":" & `"`word'"' != "=" {
        if `"`word'"' == "," | `"`word'"'=="" {
                error 198
        }
		local gopvars `gopvars' `word'
		gettoken word 0 : 0, parse(" =:,")
    }
    unab gopvars : `gopvars'
	
	
    syntax varlist [if] [in], dmu(varname) [Time(varname) SEQuential  VRS  SAVing(string) maxiter(numlist integer >0 max=1) tol(numlist max=1)]
	
	if "`maxiter'"==""{
		local maxiter=-1
	}
	if "`tol'"==""{
		local tol=-1
	}	
	
	if "`sequential'"!=""{
		if "`time'"==""{
		   disp as error "For sequential SBM model, time() should be specified."
		   error 498
		}
		else{
		   local techflag "<="
		}
	
	}
	
	preserve
	marksample touse 
	markout `touse' `invars' `gopvars' 

	local bopvars `varlist'
	
	local invars: list uniq invars
	local gopvars: list uniq gopvars
	local bopvars: list uniq bopvars
	
	confirm numeric var `invars' `gopvars' `bopvars'
	
	local comvars: list invars & gopvars 
	if !(`"`comvars'"'==""){
		disp as error "`comvars' should not be specified as input and desriable output simultaneously."
		error 498
	}
	
	local comvars: list invars & bopvars
	if !(`"`comvars'"'==""){
		disp as error "`comvars' should not be specified as input and undesriable output simultaneously."
		error 498
	}	
	
	local comvars: list gopvars & bopvars
	if !(`"`comvars'"'==""){
		disp as error "`comvars' should not be specified as desriable and undesriable outputs simultaneously."
		error 498
	}	
		
	
	local ninp: word count `invars'
    local ngo: word count `gopvars'
    local nbo: word count `bopvars'
	
	local rstype=1
	if "`vrs'"!=""{
	   local rstype=0
	}
	

	
	qui keep   `invars' `gopvars' `bopvars' `dmu' `time' `touse'
	qui gen _Row=_n
	label var _Row "Row #"
	qui keep if `touse'	
	qui gen double TE=.
	label var TE "Technical Efficiency"
	
	foreach v in `invars' `gopvars' `bopvars'{
	   qui gen double S_`v'=.
	   label var S_`v' `"Slack:`v'"'
	   local slackvars `slackvars' S_`v'
	
	}
	
	
    tempvar tvar dmu2

	
	if  `"`time'"'!="" {
	    qui egen `tvar'=group(`time')
		qui egen `dmu2'=group(`dmu')
	}
	else{
	    qui gen `tvar'=1
		qui gen `dmu2'=_n
	}
	
	sort `dmu2' `tvar' _Row
	/*
    if "`super'"!=""{
	  local sup "sup"
	}
	*/
	mata: sbmu(`"`invars'"',`"`gopvars'"',`"`bopvars'"',"`dmu2'","`tvar'",`rstype',"`techflag'","TE",`"`slackvars'"',`maxiter',`tol')
	
	
	
	order _Row `dmu' `time' TE `slackvars'
	keep _Row `dmu' `time' TE `slackvars'
	
	disp _n(2) " SBM Efficiency Results:"
	disp "    (_Row: Row # in the original data; TE: Efficiency Score;  S_X: Slack of X)"
	//disp "      S_X : Slack of X"
	list _Row `dmu' `time' TE `slackvars', sep(0) 

	//disp _n
	if `"`saving'"'!=""{
	  save `saving'
	  gettoken filenames saving:saving, parse(",")
	  local filenames `filenames'.dta
	  disp _n `"Estimated Results are saved in `filenames'."'
	}
	//tempname resmat
	//mkmat _Row `dmu' `time' TE `slackvars', mat(`resmat')
	//matrix list `resmat', noblank nohalf  noheader f(%9.6g)
	//return mat results=`resmat'
	return local file `filenames'
	restore 
	
	end
	
//////////////////////////////////////////////////////////////
capture program drop sbmeffnu
program define sbmeffnu, rclass
    version 16

    // disp "`0'"
    // get and check invarnames
	gettoken word 0 : 0, parse("=,")
    while ~("`word'" == ":" | "`word'" == "=") {
        if "`word'" == "," | "`word'" == "" {
                error 198
        }
        local invars `invars' `word'
        gettoken word 0 : 0, parse("=,")
        //disp "`word'"
    }
    unab invars : `invars'
	
    syntax varlist [if] [in], dmu(varname) [Time(varname) SEQuential VRS SAVing(string) maxiter(numlist integer >0 max=1) tol(numlist max=1)]

	if "`maxiter'"==""{
		local maxiter=-1
	}
	if "`tol'"==""{
		local tol=-1
	}	
	if "`sequential'"!=""{
		if "`time'"==""{
		   disp as error "For sequential SBM model, time() should be specified."
		   error 498
		}
		else{
		   local techflag "<="
		}
	
	}		
	
	preserve
	marksample touse 
	markout `touse' `invars' 
    //count if `touse'
	local opvars `varlist'
	
	local invars: list uniq invars
	local opvars: list uniq opvars
	
	
	confirm numeric var `invars' `opvars' 
	
	local comvars: list invars & opvars 
	if !(`"`comvars'"'==""){
		disp as error "`comvars' should not be specified as input and output simultaneously."
		error 498
	}
	
	
	local rstype=1
	if "`vrs'"!=""{
	   local rstype=0
	}
	
	

	qui keep   `invars' `opvars' `dmu' `time' `touse'
	qui gen _Row=_n
	label var _Row "Row #"
	qui keep if `touse'
	qui gen double TE=.
	label var TE "Technical Efficiency"
	
	foreach v in `invars' `opvars'{
	   qui gen double S_`v'=.
	   label var S_`v' `"Slack:`v'"'
	   local slackvars `slackvars' S_`v'
	
	}
	
	
    tempvar tvar dmu2

	
	if  `"`time'"'!="" {
	    qui egen `tvar'=group(`time')
		qui egen `dmu2'=group(`dmu')
	}
	else{
	    qui gen `tvar'=1
		qui gen `dmu2'=_n
	}
	
	sort `dmu2' `tvar' _Row
	/*
    if "`super'"!=""{
	  local sup "sup"
	}
	*/
	mata: sbm(`"`invars'"',`"`opvars'"',"`dmu2'","`tvar'",`rstype',"`techflag'","TE",`"`slackvars'"', `maxiter',`tol')
	
	
	
	order _Row `dmu' `time' TE `slackvars'
	keep _Row `dmu' `time' TE `slackvars'
	
	disp _n(2) " SBM Efficiency Results:"
    disp "    (_Row: Row # in the original data; TE: Efficiency Score;  S_X: Slack of X)"
	//disp "      S_X : Slack of X"
	list _Row `dmu' `time' TE `slackvars', sep(0) 

	//disp _n
	if `"`saving'"'!=""{
	  save `saving'
	  gettoken filenames saving:saving, parse(",")
	  local filenames `filenames'.dta
	  disp _n `"Estimated Results are saved in `filenames'."'
	}
	//tempname resmat
	//mkmat _Row `dmu' `time' TE `slackvars', mat(`resmat')
	//matrix list `resmat', noblank nohalf  noheader f(%9.6g)
	//return mat results=`resmat'
	return local file `filenames'
	restore 
	
	end	
	
	
/*	
make sbmeff, replace toc pkg title( Slacks-based Measure of Efficiency in Stata) ///
             version(1.0) author(Kerry Du) affiliation(Xiamen University) ///
			 email(kerrydu@xmu.edu.cn) install("sbmeff.ado;sbmeff.sthlp;lsbmeff.mlib")
*/
