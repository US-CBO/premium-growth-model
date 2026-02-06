****************************************************
* Generate forecast metadata file
* Place this near the end of your forecast do-file
****************************************************
clear

* Define data vintages
args baseline_vintage

* --- 1. Capture current datetime ---
* We have global datetime from create_log_file.do, 

* --- 2. Capture Stata version ---
local stata_version = c(version)
local stata_flavor = c(flavor)
local stata_bit = c(bit)

* --- 3. Get the current git commit hash ---
capture noisily shell git rev-parse HEAD > commit_hash.txt
file open fh using commit_hash.txt, read text
file read fh line
local commit_hash = strtrim("`line'")
file close fh
erase commit_hash.txt

* --- 4. Check whether there are uncommitted changes ---
* Create temp directory and file so as to avoid making the repo dirty when creating this file
local temp_dir = c(tmpdir)
local temp_file = "`temp_dir'git_dirty.txt"

capture noisily shell git status --porcelain > "`temp_file'"
file open gh using "`temp_file'", read text
file read gh dirty_line
if ("`dirty_line'" != "") local repo_dirty = "Yes"
else local repo_dirty = "No"
file close gh
erase "`temp_file'"

* --- 5. Compute checksum of the output CSV ---
local file_output "pgm_`baseline_vintage'.csv"
local path_output_relative "\output\baseline_`baseline_vintage'\"
local path_output "$repo_path`path_output_relative'\`file_output'"
local checksum = "Not computed"


* Condition on operating system 
if "`c(os)'" == "Windows" {
    * Windows: Use PowerShell
    capture noisily {
        shell powershell "Get-FileHash -Algorithm SHA1 '`path_output'' | Select-Object -ExpandProperty Hash" > checksum.txt
        file open ch using checksum.txt, read text
        file read ch line
        local checksum = word("`line'", 1)
        file close ch
        erase checksum.txt
    }
    if _rc != 0 {
        display as text "Note: Checksum computation failed (PowerShell issue or file not found)"
    }
}
else if "`c(os)'" == "Unix" | "`c(os)'" == "MacOSX" {
    * Mac/Linux: Use shasum
    capture noisily {
        shell shasum -a 1 "`path_output'" > checksum.txt
        file open ch using checksum.txt, read text
        file read ch line
        local checksum = word("`line'", 1)
        file close ch
        erase checksum.txt
    }
    if _rc != 0 {
        display as text "Note: Checksum computation failed (shasum not available or file not found)"
    }
}
else {
    display as text "Note: Checksum not computed (unsupported operating system: `c(os)')"
}


* --- 7. Write metadata to a JSON file ---
file open meta using "$repo_path`path_output_relative'metadata.txt", write text replace
file write meta "=== PREMIUM GROWTH MODEL FORECAST METADATA ===" _n
file write meta "Forecast Information:" _n
file write meta "  Baseline Vintage: `baseline_vintage'" _n
file write meta "  Generation Date/Time: $datetime" _n _n

file write meta "System Information:" _n
file write meta "  STATA Version: `stata_version' (`stata_flavor', `stata_bit'-bit)" _n

file write meta "Version Control:" _n
file write meta "  Git Commit Hash: `commit_hash'" _n
file write meta "  Uncommitted Changes: `repo_dirty'" _n _n

file write meta "Output File Information:" _n
file write meta "  SHA1 Checksum: `checksum'" _n
file close meta

display as text "Metadata file 'metadata.txt' created successfully."
