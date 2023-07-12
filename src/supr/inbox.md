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
* Add consistent filtering on branch
  * Listen to `supr_branch` env var as well
* Improve help
  * Indicate clearly what options are taken into account
* Add ffwd
  * Check that a ffwd is possible between origin/branch and branch
* Support sandboxing
  * Retrieve data from specified folder back to localhost
* Perform a fetch when syncing etc
* Catch Errno::EPIPE
* Integrate watchdog
  * When client goes in suspend, and VPN is lost, connection is stuck and requires a restart of the server
* Detect at client side when submods are not checked-out
  * If difficult, check that the githash is different from the parents
* Provide feedback when the server is applying the state
* After apply, check that the collected state matches with the wantend state
* Send version from server to client
  * Check for version compatibility
* Support commands, like 'stop', without applying state
* Support discarding changes in repo
* Support running in a different folder