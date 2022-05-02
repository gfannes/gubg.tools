# Package development

* Youtube [videos](https://www.youtube.com/watch?v=4i1zuQN5uZU&list=PLGfKZJVuHW91zln4ADyZA3sxGEmq32Wse&index=2)
* PackageDev provides useful utils to develop a package

# Package load order

* `*.sublime-package` in the installation folder
  * For all users
* `*.sublime-package` in the local user config under `Installed Packages`
* Folders/files in the local user config under `Packages`
  * Reloads automatically when changed

# Debug tools

* `Ctrl-<backtick>` to open console
* `Tools->Developer->New plugin`
* `Ctrl-Shift-P -> View Plugin Files` to show a list of plugin files

# Loading

* Startup code should go into `plugin_loaded()` at plugin level and not direct function invocations: this guarantees the API is available

# Concepts

## sublime.Window

* Hosts file catalog, panes, ...
* `window.new_file()`

## sublime.Sheet

* Contains content, an image or HTML content

## sublime.View

* View into a textual buffer (Buffer)
  * Multiple Views into the same Buffer is possible
  * Each View has its own selection state etc
* Find field in the Find dialog
* Command palette
* Something that allows text input
* `view.file_name()`

## Buffer

* Memory area

## sublime.Settings

* Can be per View
* `view.settings().get('syntax')`

## Point

`uint` offset point into the Buffer

## sublime.Region

* Span of 2 Point, region into a Buffer
* `r = sublime.Region(0,10)`
* `view.substr(r)`

## sublime.Selection

* Selection and Cursor is the same.
* Cursor can be left or right in the Selection
  * This is indicated with the order of the selection region endpoints
* Multiple Selections are possible
* `view.sel()[0]`

## sublime.Edit

* Sublime's way to control edits and keep track of undo
* Cannot be created directly, ST gives an edit object via a `sublime_plugin.TextCommand`

## Panel

* `window.create_output_panel('MyPanel')`
* Panel switcher is in the bottom-left
* QuickPanel is what Ctrl-P uses
* InputPanel is an input field
  * `window.show_input_panel('asb')`
* MiniHTML is popular in Popups and Phantoms

## sublime.Phantom

* Build system output in MiniHTML

## Commands

* TextCommands operate on Views
  * Only way to create an Edit object
* WindowCommands operate on Windows
* ApplicationCommands are global sublime commands
* Command name is snake-case without trailing Command, if present
