********************************************************************************
* Find the repository root directory and then set the present working directory
* to the repository root directory.
* 
* Note: Called from main.do and creates global macro var "repo_path"
********************************************************************************
local curr_dir "`c(pwd)'"

while fileexists("`curr_dir'\README.md") == 0 {
    local last_backslash_pos = strrpos("`curr_dir'", "\")

    * If the last backslash is at or near the drive root (e.g. "C:\"), stop
    if `last_backslash_pos' <= 3 {
        display as error "ERROR: Could not locate the README.md in any parent folder."
        exit 198
    }

    * Strip off the trailing folder
    local curr_dir = substr("`curr_dir'", 1, `last_backslash_pos' - 1)
 }

global repo_path "`curr_dir'"

cd "$repo_path/programs"
display "Present Working Directory set to: " c(pwd)