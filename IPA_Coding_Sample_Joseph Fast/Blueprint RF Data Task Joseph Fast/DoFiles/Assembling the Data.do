stop 
clear all 
eststo clear
set more off

cd "/Users/joefast/Downloads/Spring 2024 MIT Blueprint Labs Data Task/Data/schools"

global data "/Users/joefast/Downloads/Spring 2024 MIT Blueprint Labs Data Task/Data/"
*************************************
* Creating the Panel Data for schools
*************************************

* Creating a Master Panel with all the schools across all the years 
foreach x in 2010 2011 2012 2013 2014 2015 {
	import delimited "hd`x'.csv", clear 
	gen year = `x'
    save hd`x', replace
} 
use hd2010, replace 

foreach x in 2011 2012 2013 2014 2015 {
	append using hd`x'
} 

* Save to new folder with panel data
cd "${data}panel"
save hd10_15, replace

********************
* Students data set 
********************
cd "${data}students"
import delimited "sfa1015.csv", clear

cd "${data}panel"
save sfa1015,replace


*********************
* Merge the datasets 
*********************

use hd10_15, replace 
merge m:1 unitid using sfa1015, gen(merge)

***********************
* Cleanning the Dataset
***********************

keep if stabbr=="TN"
drop if merge==1

* De-cluttering all the unnesscesary student and grant values for other years  
	g scugrad=0 
	g scugffn=0 
	g scugffp=0 
	g fgrnt_p=0 
	g fgrnt_a =0
	g sgrnt_p =0
	g sgrnt_a =0

foreach x in 2010 2011 2012 2013 2014 2015 {
	replace scugrad = scugrad`x' if year==`x'
	replace scugffn = scugffn`x' if year==`x'
	replace scugffp = scugffp`x' if year==`x'
	replace fgrnt_p = fgrnt_p`x' if year==`x'
	replace fgrnt_a = fgrnt_a`x' if year==`x'
	replace sgrnt_p = sgrnt_p`x' if year==`x'
	replace sgrnt_a = sgrnt_a`x' if year==`x' 
	
	drop scugrad`x' scugffn`x' scugffp`x' fgrnt_p`x' fgrnt_a`x' sgrnt_p`x' sgrnt_a`x' 	
}

* Only including colleges with information for all years in the sample

foreach x in scugrad scugffn scugffp fgrnt_p fgrnt_a sgrnt_p sgrnt_a {
	drop if `x'==.
} 	
bysort unitid: egen sampleyears=count(year) 
drop if sampleyears != 6 
drop sampleyears
drop merge

* Keep only schools that offer undergraduate degrees or certificates 
keep if ugoffer==1

************************************
*Organizaing and cleaning variables
************************************

************************************************
* Labelling university characteristic varibles

label variable iclevel "Level of Institution"
label define LevelofInstitution 1 "4-year or higher" 2 "2-year" 3 "less than 2"
label values iclevel LevelofInstitution

label variable control "Public or Private"
label define PublicorPrivate 1 "Public" 2 "Private-Not for Profit" 3 "Private for profit"
label values control PublicorPrivate

label variable hloffer "Highest Level of Offering"
label define HighestLevel 0 "Other" 1 "Less than 1 year award" 2 "1 year award" 3 "Associates Degree" 4 "2 year award" 5 "Bachelor Degree" 6 "Postbaccalaureate certificate" 7 "Masters" 8 "Post-master's certificate" 9 "Doctor's degree" -2 "Not Applicable" -3 "Not available"
label values hloffer HighestLevel

label variable ugoffer "Offer Undergraduate Degree or Certificate"
label variable groffer "Offer graduate Degree"
label variable deggrant "Degree-Granting"
label variable instsize "Total Students"

label variable locale "Geographic Status of School"
label define Locale 11 "Large City" 13 "Small City" 12 "Medium City" 21 "Large Suburb" 22 "Medium Subarb" 23 "Small Subarb" 31 "Fringe Town" 32 "Distant Town" 33 "Remote Town" 41 "Rural Fringe" 42 "Rural Distant" 43 "Rural Remote"
label values locale Locale

label variable instcat "Institutional Category"
label define Category 1 "Graduate, no undergrad degrees" 2 "Degree granting, primarily baccalaureate" 3 "Degree granting, not primarily baccalaureate" 4 "Degree Granting, associates and certificates" 5 "Non-degree granting, above baccalaureate" 6 "Non-degree granting, sub-baccalaureate", replace
label values instcat Category


*************************************
* Labelling student and aid variables
label variable scugrad "Total Number of undegraduates"
label variable scugffn "Total number FTFT undergraduates"
label variable scugffp "FTFT as a % of all undergraduates"
label variable fgrnt_p "% of FTFT receiving federal aid"
label variable fgrnt_a "Average federal aid for FTFT undergraduates"
notes fgrnt_a: Conditional on receiving aid
label variable sgrnt_p "% of FTFT awarded aid state/local"
label variable sgrnt_a "Average state/local aid for FTFT undergraduates"
notes sgrnt_a: Conditional on receiving aid

***************************************************
* Creating the variables asked for in the exercise.
***************************************************
rename unitid ID_IPEDS
drop stabbr

*We identify any university that grants baccalaureate degrees
*this only includes university's that offer primarily baccalaureate 
*degrees and not the ones that don't primarily baccalaureate degrees
gen degree_bach=(instcat==2)
label variable degree_bach "Baccalaureate degree granting"

gen public=(control==1)
label variable public "Public Institution"

rename scugffn enroll_ftug
label variable enroll_ftug "Number of FTFT students"

gen grant_state=((enroll_ftug*sgrnt_p)/100)*sgrnt_a
label variable grant_state "Amount of state/local aid"

gen grant_federal=((enroll_ftug*fgrnt_p)/100)*fgrnt_a
label variable grant_federal "Amount of federal aid"

save Data_Main, replace

























