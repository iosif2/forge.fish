function _forge_command_tools
    set -l agent_id "$_FORGE_ACTIVE_AGENT"
    if test -z "$agent_id"
        set agent_id forge
    end

    echo
    _forge_run list tools "$agent_id"
end
