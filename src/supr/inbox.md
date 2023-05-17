# SuPR inbox

* Support taking the branches from .gitmodules into account
  * Sync with these
  * Create branches only when info is stated
* Rework repo structure
  * Load structure from .gitmodules file
    * path, url, branch
  * Extend with sha from git repos
* Add `-n` option
  * Integrate this into out.()
* Integrate logging with callback for networked output
* Remove dependency on ruby-git
* Parallellize some operations
* Rework supr/git
  * Move commands to its own TU
  * Split State/Repo from its Operations
    * Inject options into Operations
