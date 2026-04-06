# Wrapper around fzf with consistent options for a unified UX.
# Usage: _forge_fzf [additional fzf options...]
#
# Keep only the primary autoloaded function in this file. Fish autoload looks
# up functions by file name, so helper functions that are called directly from
# widgets need their own matching files under functions/.

function _forge_fzf
    env SHELL=/bin/sh fzf --reverse --exact --cycle --select-1 --height 80% --no-scrollbar --ansi --color="header:bold" $argv
end
