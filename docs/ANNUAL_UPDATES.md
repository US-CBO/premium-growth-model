## How to Perform Annual Updates to the Premium Growth Model

CBO typically begins its annual update process for the premium growth model (PGM) in the fall and completes the update process in February of
the following year. This file describes how to make annual updates to
the raw source data, the prepped data, and the code of the PGM itself.

## "Raw" Data and "Prepped" Data

The raw data sources include some very large files, so they are
stored in a network drive and are not included in the repo. Each raw
data source has a folder within the network drive, with subfolders
organized by vintage of data release. In general, "vintage" refers to
the year (or, in the case of the CBO macroeconomic forecast, the
specific day) of the release of the data source. Some raw data sources
have README files for further information.

Prepped data are .csv files that are created from the raw data and are
stored in the repo [here](\prepped_data). The naming of the folders
containing prepped data matches the naming of the raw data folders. For
example, the raw Bureau of Labor Statistics data that were released in 2024 are stored on the
network drive under "[network location]\bls\\2024", and the
corresponding prepped data are stored within the repo under
"\prepped\_data\bls\\2024".

### Step 1: Create Folders for New Vintages of Raw Data Sources and Prepped Data

For each source of raw data, determine whether it will be updated for
the new baseline and, if so, create a new folder on the network to store
the new vintage. Follow the naming convention from the prior year.

Create new folders for each new vintage of data under the prepped_data
folder.

### Step 2: Update Raw Data and the Code to Prepare the Raw Data

For each raw data source that will be updated, update the code and
inspect the newly prepped data to ensure they were processed correctly.
Compare the most recent vintage of the prepped data with previous
vintages, and be sure to understand and be able to explain all
differences between the two.

Before executing STATA code, ensure that STATA's working directory is in
the repo.

#### Yamamoto Index

This does not need to be updated. For more information about the age-sex
adjustment, see [here](https://www.healthcostinstitute.org/images/easyblog_articles/134/Age-Curve-Study_0.pdf).

#### Current Population Survey (CPS)

Go to [this](https://cps.ipums.org/cps/) website to create an IPUMS
account with your work email. CBO analysts can register as a new user
with IPUMS USA by using their CBO email address and selecting Congressional
Budget Office from the drop-down list of institutions. That will ensure
that your account is associated with CBO and is covered by the agency's
specialized license terms.

In data sample selection, select ALL SAMPLES under the ASEC tab and add
the following variables if they are not preselected: age, sex, hcovpriv,
phinsur, hinswt, and asecwt.

Note: Use hcovpriv for years prior to 2014 and phinsur starting in 2014, as
hcovpriv (the variable used to identify whether an individual was
covered by private health insurance) is unavailable starting in
2014. Use hinswt for years prior to 2014 and asecwt (the new weight that was assigned for the 2014 health and income redesign) starting in 2014, as
hinswt is unavailable in 2014, when the health
questions were redone. After the 2014 health and income
redesign, all respondents were given the same questions for health, but
the sample was split with respect to income. Because all of the
respondents received the same questionnaire for health and demographic
information, asecwt poses no comparability problems for 2014. CBO also
found that the new weights (changed from wtsupp to asecwt for
CPS 2017) did not substantially alter the premium growth projections.

Download the IPUMS data (it will be zipped) and the STATA command file
from IPUMS. Save in the new vintage folder in the S drive you created
for the raw CPS data and unzip the .dat.gz file. That will create the .dat
file used in the program.

Create a copy of the most recent `create_age_sex_index.do` and paste it
into a new folder for the new vintage of the CPS. Update the code to use
the new CPS data, and write the output to the new prepped data folder.

#### National Health Expenditure Accounts (NHEA)

Go to this
[website](https://www.cms.gov/data-research/statistics-trends-and-reports/national-health-expenditure-data/historical)
and download the NHE Tables zipped files after scrolling to the
Downloads section. Unzip the downloaded NHEA file in the raw_NHE folder under the new
vintage folder you created. The program will use only one file from the zip: Table 21
Expenditures, Enrollment and Per Enrollee Estimates of Health
Insurance.xlsx.

Create a copy of the most recent `process_NHE.do` and paste it into a
new folder for the new vintage of the NHEA. Update the code to use the
new NHEA data, and write the output to the new prepped data folder.

#### Health Insurance Tax

This file does not need to be updated. It contains calculations of the
effects of the health insurance tax on premiums for 2014 to 2018 and is
used to remove the tax's effects from historical data.

#### Generate Premiums

Create a copy of the most recent `generate_premiums.do` and paste it
into a new folder. Label that folder according to the last year for which
historical premiums are available. Update the code to use the new NHE data
and the new age_sex_index.csv, and write the output to the new prepped
data folder.

#### Macroeconomic Forecast From CBO's Macroeconomic Analysis Division (MAD)

The PGM uses growth in per capita personal disposable income to project
premium growth using data from MAD's forecast.

Download the final calendar forecast from MAD's internal wiki. Make sure
that the label attached to the downloaded forecast is the name of the
folder you are saving the updated data to. For example,
A_MAD_VARS_b241204f.xlsx should be saved under "[network
folder]\\raw_mad\\b241204f".

Create a copy of the most recent `process_MAD.do` and paste it into a
new folder for the new vintage of the MAD forecast. Update the code to
use the new MAD forecast, and write the output to the new prepped data
folder. The name of the prepped data folder will follow the same
naming convention (for example, "\\prepped_data\\mad\\b241204f").

#### KFF Employer Health Benefits Survey (EHBS)

Get the most recent full report data from
[here](https://www.kff.org/report-section/ehbs-2024-section-1-cost-of-health-insurance/). Download Tables Section 1: PREMIUMS FOR SINGLE AND FAMILY COVERAGE from the top link on the right sidebar of the page.

Create a copy of the most recent `process_KFF.do` and paste it into a
new folder for the new vintage of the KFF data. Update the code to use
the new KFF data, and write the output to the new prepped data folder.

#### Bureau of Labor Statistics (BLS)

CBO downloads a producer price index for comprehensive medical service
plans from the BLS. For information on the
series, see [this
documentation](https://www.bls.gov/ppi/factsheets/producer-price-index-for-the-direct-health-and-medical-insurace-carriers-industry-naics-524114.htm).
Beginning with the 2025 baseline, CBO replaced the "Medical service
plans" (5241141) series with the "Group comprehensive medical service
plans" (524114101) series.

Download the [monthly
data](https://data.bls.gov/timeseries/PCU524114524114101) from 2003 on
without annual averages and save in the raw data folder.

Create a copy of the most recent `process_BLS.do` and paste it into a
new folder for the new vintage of the BLS data. Update the code to use
the new BLS data, and write the output to the new prepped data folder.

#### Merge

Create a copy of the most recent `merge.do` and paste it into a new
folder named for the baseline. Update the code to use the new prepped
data, and write the output to the new prepped data folder.

From the merge.do step onward, the names of programs and output are 
based on the year of CBO's baseline. For example, the merge.do file that
creates CBO's 2025 baseline is stored under
"programs\\prep_raw_data\\merge\\2025".

### Step 3: Create a Folder for the Output of the New PGM

Create a directory for the new baseline (for example, `\output\baseline_2026`).

### Step 4: Update the PGM

The projection is created in two stages. First, CBO projects the growth in
premiums from the last historical year of the NHE to the next year using
the BLS data and the KFF data; that is referred to as the current-year
projection. Then, using the historical NHE data and the current-year
projection, CBO uses the PGM to project growth over the rest of the
window.

Steps to update:

1.  Create a folder within `\programs\run\_model` for the new baseline,
    and copy the previous baseline's version of `pgm_current_yr.do` to
    that folder.

2.  Update the parameters of `pgm_current_yr.do` so that it uses the
    new merged data. Inspect the results and discuss with the team.

3.  Copy the previous baseline's version of `pgm.do` to the new folder.
    Update the parameters of `pgm.do` so that they use the new merged data
    and the new current-year projection. Update the variable generation
    statements so that the correct variables are generated for each
    step. Inspect the output data to ensure they were generated
    correctly, and discuss with the team.

## How to run the report 
The output from the PGM is then read into an R program to create an annual report. To run the report: 
1. Navigate to `had-himu-premium-growth-model.Rproj` in the repository and double click.
2. In the console, type `renv::restore()`. This will begin dowloading packages necessary to run the program.
3. Once that has finished, execute a `renv::status()` command and make sure the project is in a consistent state.
4. Navigate to the `render` button on the top left of the project (it's to the left of the settings icon) and click it once. This will render the report.
5. Users should need to perform actions 1, 2, and 3 only once, although it is good practice to always perform the `renv::status()` action. Thereafter, users should only need to click the `render` button.

## How to update the report 
The text in the report will need to be updated annually, and the parameters will need to be set to the new year. 
1. Navigate to the first code chunk. Under `# Parameters` update the vinatges. (For example, 2025 becomes 2026). This should be the extent of coding work necessary unless there are errors and/or technical updates that need to be made.
2. Though CBO attempted to ensure many of the text values were flexible and not hardcoded, some may have been missed. Read through the report and edit values as neccessary. Ensure the output from `pgm.do` is properly represented within the charts. Update the text as necessary. 

