function _forge_action_tools
    echo
    set -l agent_id "forge"
    if test -n "$_FORGE_ACTIVE_AGENT"
        set agent_id "$_FORGE_ACTIVE_AGENT"
    end
    _forge_exec list tools "$agent_id"
end
