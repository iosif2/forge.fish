function _forge_start_background_update
    $_FORGE_BIN update --no-confirm >/dev/null 2>&1 </dev/null &
    disown
end
