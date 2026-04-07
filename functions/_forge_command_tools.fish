function _forge_command_tools
    echo
    set -l agent_id "forge"
    if test -n "$_FORGE_ACTIVE_AGENT"
        set agent_id "$_FORGE_ACTIVE_AGENT"
    end
    _forge_run list tools "$agent_id"
end
