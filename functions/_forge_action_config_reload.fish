# Action handler: Reload config by resetting all session-scoped overrides.
# Port of _forge_action_config_reload from zsh.
# Clears _FORGE_SESSION_MODEL, _FORGE_SESSION_PROVIDER, and
# _FORGE_SESSION_REASONING_EFFORT so subsequent forge invocations fall back to
# the permanent global configuration.
# Usage: _forge_action_config_reload

function _forge_action_config_reload
    echo

    if test -z "$_FORGE_SESSION_MODEL"; and test -z "$_FORGE_SESSION_PROVIDER"; and test -z "$_FORGE_SESSION_REASONING_EFFORT"
        _forge_log info "No session overrides active (already using global config)"
        return 0
    end

    set -g _FORGE_SESSION_MODEL ""
    set -g _FORGE_SESSION_PROVIDER ""
    set -g _FORGE_SESSION_REASONING_EFFORT ""

    _forge_log success "Session overrides cleared — using global config"
end
