*! version 1.0
* By Kerry Du, 29 Oct 2019  
capture program drop sbmeff
program define sbmeff, rclass
    version 16
	
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
	qui mata mata mlib index
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
	//qui mata mata mlib index
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
////////////////


version 16
cap mata mata drop lpres()
cap mata mata drop sbmu_vrs()
cap mata mata drop sbmu_crs()
cap mata mata drop sbmu()
cap mata mata drop sbm_vrs()
cap mata mata drop sbm_crs()
cap mata mata drop sbm()
cap mata mata drop relflag()


mata:
mata clear 

//////////////////////////////////////////////////////////////////
	struct lpres   { real scalar    fval 
					 real matrix    coeff
					 real scalar    converged
					 real scalar    returncode
					  }

///////////////////////////////////////////////////////////////////
   function sbmu_vrs(  real rowvector    X, ///
					   real rowvector    Y,  ///
					   real rowvector    B, ///
					   real matrix    Xref, ///
					   real matrix    Yref, ///
					   real matrix    Bref, ///
					   real scalar    maxiter, ///
					   real scalar    tol)
	{
	
	    class LinearProgram scalar q
		
		nx=length(X)
		ny=length(Y)
		nb=length(B)

		c=(1,-1:/(nx*X),J(1,ny+nb+rows(Xref),0))
		lowerbd=J(1,length(c),0)
		upperbd=J(1,length(c),.)		
		q = LinearProgram()
		if(maxiter!=-1){
		  q.setMaxiter(maxiter)
		}
		if (tol!=-1){
		  q.setTol(tol)
		}
		q.setCoefficients(c)
		q.setBounds(lowerbd, upperbd)
		 beq=1 \ J(nx+ny+nb,1,0) \ 1
		 Aeq1=1,J(1,nx,0),1:/((ny+nb)*Y),1:/((ny+nb)*B),J(1,rows(Xref),0)
		 Aeq2=-X',I(nx),J(nx,ny+nb,0),Xref'
		 Aeq3=-Y',J(ny,nx,0),-I(ny),J(ny,nb,0),Yref'		 
		 Aeq4=-B',J(nb,nx+ny,0),I(nb),Bref'
		 Aeq5=J(1,1+nx+ny+nb,0),J(1,rows(Xref),1)
		 q.setEquality(Aeq1 \ Aeq2 \ Aeq3 \ Aeq4 \Aeq5, beq)
	     q.setMaxOrMin("min")
		 beta=q.optimize()
		 struct lpres scalar retres
		 retres.fval=q.value()
		 retres.coeff=q.parameters()
         retres.converged=q.converged()
		 retres.returncode=q.returncode()
		 //q.converged()
		 return(retres)
		
		

}

////////////////////////////////////////////////////////////////////////

   function sbmu_crs(  real rowvector    X, ///
					   real rowvector    Y,  ///
					   real rowvector    B, ///
					   real matrix    Xref, ///
					   real matrix    Yref, ///
					   real matrix    Bref, ///
					   real scalar    maxiter, ///
					   real scalar    tol)
	{
	
	    class LinearProgram scalar q
		
		nx=length(X)
		ny=length(Y)
		nb=length(B)

		c=(1,-1:/(nx*X),J(1,ny+nb+rows(Xref),0))
		lowerbd=J(1,length(c),0)
		upperbd=J(1,length(c),.)		
		q = LinearProgram()
		
		if(maxiter!=-1){
		  q.setMaxiter(maxiter)
		}
		if (tol!=-1){
		  q.setTol(tol)
		}		
		
		q.setCoefficients(c)
		q.setBounds(lowerbd, upperbd)
		 beq=1 \ J(nx+ny+nb,1,0)
		 Aeq1=1,J(1,nx,0),1:/((ny+nb)*Y),1:/((ny+nb)*B),J(1,rows(Xref),0)
		 Aeq2=-X',I(nx),J(nx,ny+nb,0),Xref'
		 Aeq3=-Y',J(ny,nx,0),-I(ny),J(ny,nb,0),Yref'		 
		 Aeq4=-B',J(nb,nx+ny,0),I(nb),Bref'
		 
		 q.setEquality(Aeq1 \ Aeq2 \ Aeq3 \ Aeq4, beq)
	     q.setMaxOrMin("min")
		 beta=q.optimize()
		 struct lpres scalar retres
		 retres.fval=q.value()
		 retres.coeff=q.parameters()
         retres.converged=q.converged()
		 retres.returncode=q.returncode()
		 //q.converged()
		 return(retres)
		
		

}

/////////////////////////////////////////////////////////////////////

       void function sbmu(      string scalar       Xvar,  ///
						        string scalar       Yvar,  ///
						        string scalar       Bvar,  ///
								string scalar       idvar, ///
								string scalar       tvar,  ///
								real scalar         rstype, ///
								string scalar       rel,    ///
								string scalar       vScore, ///
								string scalar       vSlacks, ///
								real scalar         maxiter, ///
					            real scalar         tol)
	{


	struct lpres scalar sbmres
	
	X=st_data(.,Xvar)
	Y=st_data(.,Yvar)
	B=st_data(.,Bvar)
	id=st_data(.,idvar)
	t=st_data(.,tvar)
	
	nv=cols(X)+cols(Y)+cols(B)
    id2= uniqrows(id)
	t2 = uniqrows(t)
	k  = 1
	rho=J(rows(X),1,.)
	slacks=J(rows(X),nv,.)
	for(i=1;i<=length(id2);i++){
		for(j=1;j<=length(t2);j++){
		   //(id:==id2[i]):&(t:==t2[j])
		   flag=(id:==id2[i])+(t:==t2[j])
		   XX   = select(X,flag:==2)
		   YY   = select(Y,flag:==2)
		   BB   = select(B,flag:==2)
		   flag=relflag(rel,t, t2[j])
		   Xref = select(X,flag)
		   Yref = select(Y,flag)
		   Bref = select(B,flag)
		   if(rstype==1){
		     sbmres=sbmu_crs(XX,YY,BB,Xref,Yref,Bref,maxiter,tol)
		   }
		   else{
		     sbmres=sbmu_vrs(XX,YY,BB,Xref,Yref,Bref,maxiter,tol)	
		   }
		   
		   if(sbmres.converged==1){
			   rho[k]=sbmres.fval	
			   slacks[k,.]=sbmres.coeff[1,2..(nv+1)]/sbmres.coeff[1,1]		   
		   }

		   k=k+1
		}
	
	}
	
	st_view(Score=.,.,vScore)
	Score[.,.]=rho
	st_view(SSlacks=.,.,vSlacks)
	SSlacks[.,.]=slacks
	

}

////////////////////////////////////////////////////////
   function sbm_vrs(   real rowvector    X, ///
					   real rowvector    Y,  ///
					   real matrix    Xref, ///
					   real matrix    Yref, ///
					   real scalar    maxiter, ///
					   real scalar    tol)
	{
	
	    class LinearProgram scalar q
		
		nx=length(X)
		ny=length(Y)

		c=(1,-1:/(nx*X),J(1,ny+rows(Xref),0))
		lowerbd=J(1,length(c),0)
		upperbd=J(1,length(c),.)		
		q = LinearProgram()
		
		if(maxiter!=-1){
		  q.setMaxiter(maxiter)
		}
		if (tol!=-1){
		  q.setTol(tol)
		}		
		q.setCoefficients(c)
		q.setBounds(lowerbd, upperbd)
		 beq=1 \ J(nx+ny,1,0) \ 1
		 Aeq1=1,J(1,nx,0),1:/(ny*Y),J(1,rows(Xref),0)
		 Aeq2=-X',I(nx),J(nx,ny,0),Xref'
		 Aeq3=-Y',J(ny,nx,0),-I(ny),Yref'		 
		 Aeq4=J(1,1+nx+ny,0),J(1,rows(Xref),1)
		 q.setEquality(Aeq1 \ Aeq2 \ Aeq3 \ Aeq4, beq)
	     q.setMaxOrMin("min")
		 beta=q.optimize()
		 struct lpres scalar retres
		 retres.fval=q.value()
		 retres.coeff=q.parameters()
         retres.converged=q.converged()
		 retres.returncode=q.returncode()
		 //q.converged()
		 return(retres)
		
		

}

////////////////////////////////////////////////////////////////

   function sbm_crs(   real rowvector    X, ///
					   real rowvector    Y,  ///
					   real matrix    Xref, ///
					   real matrix    Yref, ///
					   real scalar    maxiter, ///
					   real scalar    tol)
	{
	
	    class LinearProgram scalar q
		
		nx=length(X)
		ny=length(Y)

		c=(1,-1:/(nx*X),J(1,ny+rows(Xref),0))
		lowerbd=J(1,length(c),0)
		upperbd=J(1,length(c),.)		
		q = LinearProgram()
		if(maxiter!=-1){
		  q.setMaxiter(maxiter)
		}
		if (tol!=-1){
		  q.setTol(tol)
		}		
		
		q.setCoefficients(c)
		q.setBounds(lowerbd, upperbd)
		 beq=1 \ J(nx+ny,1,0) 
		 Aeq1=1,J(1,nx,0),1:/(ny*Y),J(1,rows(Xref),0)
		 Aeq2=-X',I(nx),J(nx,ny,0),Xref'
		 Aeq3=-Y',J(ny,nx,0),-I(ny),Yref'		 
		 q.setEquality(Aeq1 \ Aeq2 \ Aeq3, beq)
	     q.setMaxOrMin("min")
		 beta=q.optimize()
		 struct lpres scalar retres
		 retres.fval=q.value()
		 retres.coeff=q.parameters()
         retres.converged=q.converged()
		 retres.returncode=q.returncode()
		 //q.converged()
		 return(retres)
		
		

}

///////////////////////////////////////////////////////////////////////

       void function sbm(       string scalar       Xvar,  ///
						        string scalar       Yvar,  ///
								string scalar       idvar, ///
								string scalar       tvar,  ///
								real scalar         rstype, ///
								string scalar       rel,    ///
								string scalar       vScore, ///
								string scalar       vSlacks, ///
								real scalar         maxiter, ///
					            real scalar         tol)
	{


	struct lpres scalar sbmres
	
	X=st_data(.,Xvar)
	Y=st_data(.,Yvar)
	id=st_data(.,idvar)
	t=st_data(.,tvar)
	
	nv=cols(X)+cols(Y)
    id2= uniqrows(id)
	t2 = uniqrows(t)
	k  = 1
	rho=J(rows(X),1,.)
	slacks=J(rows(X),nv,.)
	for(i=1;i<=length(id2);i++){
		for(j=1;j<=length(t2);j++){
		   //(id:==id2[i]):&(t:==t2[j])
		   flag=(id:==id2[i])+(t:==t2[j])
		   XX   = select(X,flag:==2)
		   YY   = select(Y,flag:==2)
		   flag=relflag(rel,t, t2[j])
		   Xref = select(X,flag)
		   Yref = select(Y,flag)
		   if(rstype==1){
		     sbmres=sbm_crs(XX,YY,Xref,Yref,maxiter,tol)
		   }
		   else{
		     sbmres=sbm_vrs(XX,YY,Xref,Yref,maxiter,tol)	
		   }
		   
		   if(sbmres.converged==1){
			   rho[k]=sbmres.fval	
			   slacks[k,.]=sbmres.coeff[1,2..(nv+1)]/sbmres.coeff[1,1]		   
		   }

		   k=k+1
		}
	
	}
	
	st_view(Score=.,.,vScore)
	Score[.,.]=rho
	st_view(SSlacks=.,.,vSlacks)
	SSlacks[.,.]=slacks
	

}


/////////////////////////////////////

real matrix function relflag(string scalar rel, real colvector x, real scalar y)

{
   if(rel=="<="){
      flag=(x:<=y)
   }
   else{
      flag=(x:==y)
   }
   return(flag)

}


///////////////////////////////////


end
