function _forge_update_start
    $_FORGE_BIN update --no-confirm >/dev/null 2>&1 </dev/null &
    disown
end
