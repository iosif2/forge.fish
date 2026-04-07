function _forge_command_dump
    switch "$argv[1]"
        case html
            _forge_conversation_run_subcommand dump --html
        case '*'
            _forge_conversation_run_subcommand dump
    end
end
