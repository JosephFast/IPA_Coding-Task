stop 
clear all 
eststo clear
set more off

cd "${data}panel"

**************
// Question 1 
**************

* See results in Latex document

tabout year using table1.txt, c(sum degree_bach sum public mean enroll_ftug mean grant_state mean grant_federal) f(0c 0c 0c 0c 0c) clab(Bachelor_Granting_Institutions Public_Institutions Average_Enrollment Average_Total_State/Local_Aid Average_TotalFederal_Aid) sum npos(tufte) rep ptotal(none)style(tex) bt cl2(2-6) cltr2(.75em 1.5em) topf(top.tex) botf(bot.tex) topstr(10cm) botstr(Data_Main)

**************
// Question 2 
**************

* Generate a variable for the 4 types of institutions
gen group = public + 2 * degree_bach
label def group 0 "private 2-year" 1 "public 2-year" 2 "private 4-year" 3 "public 4-year"
label val group group

*Averaging across all the groups (State aid)
egen mean = mean(grant_state), by(group year)
separate mean, by(group) veryshortlabel

* (FTFT enrollment)
egen FTFT = mean(enroll_ftug), by(group year)
separate FTFT, by(group) veryshortlabel

*Graph for state/local aid
twoway connected mean? year , sort scheme(s1color) ms(Oh Dh Th Sh) mc(black blue magenta red) lc(black blue magenta red) legend(col(1) pos(3) ring(0)) xla(2010/2015) ytitle("Average school level state/local aid ($)") name(Aid)

* Graph for number of FTFT students
twoway connected FTFT? year , sort scheme(s1color) ms(Oh Dh Th Sh) mc(black blue magenta red) lc(black blue magenta red) legend(col(1) pos(3) ring(0)) xla(2010/2015) ytitle("Average Number of FTFT undergraduate students") name(student)

* Combine and export graphs
graph combine Aid student, graphregion(color(white)) title(Tennessee Institutions 2010-2015)
graph export "Question2.pdf", replace

**************
// Question 3 
**************

* For Difference-in-Differences model
* 2-year private is the control and 2-year public is the treated 
gen treated=(group==1)
gen post =(year==2015)

*For IV regression model
gen program =(treated*post==1)

* Since distribution of FTFT students is very right skewed, we can use 
* the log of FTFT students to approxiate a normal distribution
histogram enroll_ftug
gen ln_enroll = log(enroll_ftug)
hist ln_enroll

* IV estimation grant_state sgrnt_a as instruments
ivregress 2sls ln_enroll (program=grant_state sgrnt_a) grant_federal i.locale scugffp if group==1  , robust first

* Difference-in-Differences estimation
eststo DandD: reg ln_enroll post##treated i.locale i.instsize grant_federal  if group==1|group==0, robust first cluster(locale)

************************
** Tests for Valididty
************************

********************
* Weak instruments? 

* First stage regression

eststo stage1: reg program grant_federal i.locale i.instsize scugffp grant_state sgrnt_a  if group==1, robust
testparm grant_state sgrnt_a

* Value of F-Test 44.34 

********************************************
* Over-Identification Test. Is the IV valid? 

eststo stage2 :ivregress 2sls ln_enroll (program=grant_state sgrnt_a)  grant_federal i.locale i.instsize scugffp  if group==1, robust 
estat overid

***************************
* Output of the Regressions 
esttab stage2, se nogaps
esttab DandD, se nogaps 
esttab stage1, se nogaps

save Data_Analysis, replace
