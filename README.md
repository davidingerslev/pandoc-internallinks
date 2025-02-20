# pandoc-internallinks
A lua filter to replace markdown internal links to headers with working links in the document.

It handles both `[[#internal links]]` and `[[#internal links|links with aliases]]`.

## Installation
Clone the repository or download [internal-links.lua](https://github.com/davidingerslev/pandoc-internallinks/blob/main/internal-links.lua) 
and move it into the filters subdirectory of your pandoc data directory.

* On linux/mac, this is usually either `~/.config/pandoc/filters` or `~/.pandoc/filters`
* On Windows, this is usually `%AppData%\pandoc\filters`
* You can check the location of the pandoc data directory by running `pandoc --version`

Create the pandoc data directory and filters subdirectory if they don't already exist.

Then enable the filter by adding the argument `--lua-filter=internal-links.lua` to your call to pandoc.

For example, in Obsidian, install the fantastic [Pandoc](https://github.com/OliverBalfour/obsidian-pandoc)
plugin and in the plugin settings add this argument into the `Extra Pandoc arguments` box. Note: internal
links are only included in the markdown if the option `Export files from HTML or markdown?` is set to
`Markdown`.
