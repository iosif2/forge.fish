function _forge_command_config_reload
    echo

    if test -z "$_FORGE_SESSION_MODEL"; and test -z "$_FORGE_SESSION_PROVIDER"; and test -z "$_FORGE_SESSION_REASONING_EFFORT"
        _forge_report info "No session overrides active (already using global config)"
        return 0
    end

    set -g _FORGE_SESSION_MODEL ""
    set -g _FORGE_SESSION_PROVIDER ""
    set -g _FORGE_SESSION_REASONING_EFFORT ""

    _forge_report success "Session overrides cleared — using global config"
end
