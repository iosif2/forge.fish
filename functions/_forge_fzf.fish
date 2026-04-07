function _forge_fzf
    env SHELL=/bin/sh fzf --reverse --exact --cycle --select-1 --height 80% --no-scrollbar --ansi --color="header:bold" $argv
end
