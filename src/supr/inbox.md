# SuPR inbox

* Support taking the branches from .gitmodules into account
  * Sync with these
  * Create branches only when info is stated
* Add `-n` option
  * Integrate this into out.()
* Integrate logging with callback for networked output
* Replace ad-hoc naft parsing with real read/write
* Parallellize some operations
  * Only MT first level to reduce index.lock issues
* Support for ENV variables
* Support for metadata for Module naft file