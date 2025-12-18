This folder contains the outputs of automated repo and Bandit checks.
Files:
- current_bandit.txt: .bandit contents
- dir_structure_grep.txt: ls -la filtered for archive/venv
- bandit_results.json: raw Bandit output (mixed stdout/stderr captured)
- results_count.txt: number of Bandit results or INVALID_JSON
- bandit_verbose.txt: verbose Bandit output
- excludes.txt: grep for excluded/skip lines from verbose output
- archive_dirs.txt: find results for archive/venv directories
- git_status.txt: git status --short
- files_to_scan.txt: .py files referenced in Bandit verbose output
