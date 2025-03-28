# CBO's Private Health Insurance Premium Growth Model

The Congressional Budget Office uses its premium growth model (PGM) to generate inflation factors that are used in CBO's health insurance simulation model (HISIM2). The PGM's output is used to project growth in premiums for employment-based health insurance, employer contributions to health reimbursement accounts (HRAs) and health savings accounts (HSAs), and nongroup premiums. The PGM is also used to project plan characteristics such as maximum out-of-pocket limits for employment-based plans, as well as deductibles for nongroup plans.

This file describes how to clone the repository containing the PGM, run the PGM, and replicate CBO's results. This file is intended to be used along with other sources of documentation:

- The purpose and technical specifications of the PGM are described in detail in a [report](https://us-cbo.github.io/premium-growth-model/report/baseline_2025/report.html).
- The [ANNUAL_UPDATES.md](/docs/ANNUAL_UPDATES.md) file describes how to update and process raw source data as part of CBO's annual baseline update.
- Two visual flowcharts, one [high-level](Flowchart_highlevel.png) and one [detailed](Flowchart_detailed.png), illustrate the processing of data.
- The [Abbreviations.md](/docs/Abbreviations.md) file defines the abbreviations used in the model and report. 

## How to install the premium growth model

Follow these steps to install CBO's PGM.

1. **Install necessary software**

   The model was developed and tested on a Windows operating system using Stata/IC 14.2 for Windows (64-bit x86-64), but it should be compatible with other versions of Stata. More information about Stata can be found at [stata.com](https://www.stata.com/).

   The report is rendered in [RStudio](https://posit.co/download/rstudio-desktop/) using R version 4.1.3 and using Quarto version 1.4.555.

2.  **Download the repository ("repo") from GitHub**  
There are several options for how to get the code and prepped data from GitHub to your computer:

    * If you have `git` installed on your computer and you have a GitHub account, please first "fork" a copy of this repo to your own GitHub account. Then clone your fork to your computer with the following command in the terminal of your choice:
`git clone https://github.com/<your-GitHub-account-name>/premium-growth-model.git`
or using the Git graphical user interface (GUI) of your choice.

    * If you have `git` installed on your computer but you do not have a GitHub account, you can clone a copy of the repo to your computer. This is done by entering the following command in the terminal of your choice:
`git clone https://github.com/us-cbo/premium-growth-model.git`
or using the Git GUI of your choice. (Please note: You will not be able to make any pull requests to this repo without first creating your own GitHub account and making any such requests from your forked version of this repo.)

    * If you do not have `git` installed on your computer, you can download a [zipped file](https://github.com/us-cbo/premium-growth-model/archive/refs/heads/main.zip) containing the entire repo and then unzip it.

## How to run the model
1. Navigate to the location where you cloned or downloaded the PGM repo, then to the `/programs/` subdirectory.

2. Open Stata by double-clicking on the `main.do` file. This starts Stata in the appropriate working directory.

3. From within the Stata do-file editor, edit the `main.do` file so that sections that you want to run are uncommented out. The `create_age_sex_index.do` script takes the longest to run. If you are only running `pgm.do`, the model should run quickly (in less than a minute.) During execution of `pgm.do`, text output will be written to the results window and to a `.log` file.

## What to expect for output 
The model produces two comma-separated value (`*.csv`) files that contain numeric output and are written to the `/output/baseline_[YYYY]` directory.

   * A `pgm_[YYYY].csv` contains a header row and 16 rows of data, with calendar years on the columns (`cy[YYYY]`). The series that are named beginning with "pchange_" represent the percentage change in private health expenditures per capita from the previous year, and the series that are named beginning with "prem_" reflect the dollar value of private health expenditures per capita in that year. The series with names that include "demo_" incorporate adjustments for demographic changes among the privately insured. The first pair of rows represent projections from CBO's 2024 baseline, with subsequent rows cumulatively adding updates to the raw data and the projection methodology.
   * A `pgm_[YYYY]_long_format.csv` file contains the same information, plus several additional fields, pivoted into a long format so that years are on the rows rather than columns. The `step` column indicates the data series, with naming conventions similar to those used in `pgm_[YYYY].csv`. This file facilitates the creation of diagnostic figures in R.

## How to run the report
1. Navigate to `premium-growth-model.Rproj` in the repository and double-click. This should open the project in RStudio.
2. In the console, type `renv::restore()`. This will begin dowloading and installing packages necessary to run the program. This may take some time.
3. Once that has finished, execute a `renv::status()` command to confirm that the project is in a consistent state.
4. Open the `/docs/report/baseline_2025/report.qmd` file.
5. Navigate to the `render` button on the top left of the project (to the left of the Settings icon) and click it once. This will render the report.
6. Users should need to perform actions 1, 2, and 3 only once, although it is good practice to always perform the `renv::status()` action. Thereafter, users should only need to click the `render` button. 


## Acknowledgments

The PGM was developed and maintained by CBO analysts **Ben Hopkins**, **Julianna Mack**, and **Robert Lindsay** (formerly of CBO). **Caroline Hanson** and **Eamon Molloy** contributed to the word review of the model, and **Christine Browne** and **Lora Engdahl** prepared materials for publication. **Kevin Perese**, **Claire Hou** and **Rajan Topiwala** reviewed the code for this project. **Christine Ostrowski** assisted in CBO's data analysis. **Katherine Feinerman** (formerly of CBO) maintained the previous PGM. **Alexandra Minicozzi** and **Chapin White** supervised the most recent model development.

## Contact

For questions regarding the data, model, or documentation, contact CBO's Office of Communications at:

`📧 communications@cbo.gov`

CBO will respond to inquiries as its workload permits.
