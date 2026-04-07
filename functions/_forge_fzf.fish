function _forge_fzf
    set -l fzf_args \
        --reverse \
        --exact \
        --cycle \
        --select-1 \
        --height 80% \
        --no-scrollbar \
        --ansi \
        '--color=header:bold'

    env SHELL=/bin/sh fzf $fzf_args $argv
end
