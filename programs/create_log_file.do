********************************************************************************
* Set up the log file for main.do
*
* Note: Called from main.do
********************************************************************************

* Get current date and convert to ISO-8601 date format
local iso_date = string(date(c(current_date), "DMY"), "%tdCCYY-NN-DD")  

* Get time and extract their components
local hh = substr(c(current_time), 1, 2)
local mm = substr(c(current_time), 4, 2)
local ss = substr(c(current_time), 7, 2)

* Combine date and time components
global datetime "`iso_date'T`hh'`mm'`ss'"

log using "$repo_path/logs/main_${datetime}.log", replace
