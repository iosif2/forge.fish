function _forge_command_config_reload_has_overrides
    test -n "$_FORGE_SESSION_MODEL"; or test -n "$_FORGE_SESSION_PROVIDER"; or test -n "$_FORGE_SESSION_REASONING_EFFORT"
end

function _forge_command_config_reload
    echo

    if not _forge_command_config_reload_has_overrides
        _forge_report info 'No session overrides active (already using global config)'
        return 0
    end

    set -g _FORGE_SESSION_MODEL ''
    set -g _FORGE_SESSION_PROVIDER ''
    set -g _FORGE_SESSION_REASONING_EFFORT ''

    _forge_report success 'Session overrides cleared — using global config'
end
