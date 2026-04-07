function _forge_update_start
    set -l command $_FORGE_BIN update --no-confirm
    $command >/dev/null 2>&1 </dev/null &
    disown
end
