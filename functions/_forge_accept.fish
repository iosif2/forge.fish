function _forge_commandline_supports_search_field
    if set -q _FORGE_HAS_COMMANDLINE_SEARCH_FIELD
        test "$_FORGE_HAS_COMMANDLINE_SEARCH_FIELD" = 1
        return
    end

    if commandline --help 2>/dev/null | string match -q '*--search-field*'
        set -g _FORGE_HAS_COMMANDLINE_SEARCH_FIELD 1
        return 0
    end

    set -g _FORGE_HAS_COMMANDLINE_SEARCH_FIELD 0
    return 1
end

function _forge_prepare_dispatch_lite --argument buffer
    # Cancel reader sub-modes, but leave redraw to the caller.
    set -l _forge_cancel_modes 0
    if commandline --paging-mode >/dev/null; or commandline --search-mode >/dev/null
        set _forge_cancel_modes 1
    else if _forge_commandline_supports_search_field; and commandline --search-field >/dev/null
        set _forge_cancel_modes 1
    end

    if test "$_forge_cancel_modes" = 1
        commandline -f cancel
    end

    commandline -f suppress-autosuggestion
    commandline -C (string length -- "$buffer")
end

function _forge_normalize_action_name --argument user_action
    switch $user_action
        case ask
            echo sage
        case plan
            echo muse
        case '*'
            echo "$user_action"
    end
end

function _forge_dispatch_core_actions --argument user_action input_text
    switch $user_action
        case new n
            _forge_command_new "$input_text"
        case info i
            _forge_command_info
        case env e
            _forge_command_env
        case dump d
            _forge_command_dump "$input_text"
        case compact
            _forge_command_compact
        case retry r
            _forge_command_retry
        case agent a
            _forge_command_agent "$input_text"
        case conversation c
            _forge_command_conversation "$input_text"
        case edit ed
            _forge_command_editor "$input_text"
            return 2
        case commit
            _forge_command_commit "$input_text"
        case commit-preview
            _forge_command_commit_preview "$input_text"
            return 2
        case suggest s
            _forge_command_suggest "$input_text"
            return 2
        case clone
            _forge_command_clone "$input_text"
        case rename rn
            _forge_command_rename "$input_text"
        case conversation-rename
            _forge_command_conversation_rename "$input_text"
        case copy
            _forge_command_copy
        case doctor
            _forge_command_doctor
        case keyboard-shortcuts kb
            _forge_command_keyboard
        case '*'
            return 1
    end

    return 0
end

function _forge_dispatch_config_actions --argument user_action input_text
    switch $user_action
        case config-provider provider p
            _forge_command_provider "$input_text"
        case config-model cm
            _forge_command_model "$input_text"
        case model m
            _forge_command_session_model "$input_text"
        case config-reload cr model-reset mr
            _forge_command_config_reload
        case reasoning-effort re
            _forge_command_reasoning_effort "$input_text"
        case config-reasoning-effort cre
            _forge_command_config_reasoning_effort "$input_text"
        case config-commit-model ccm
            _forge_command_commit_model "$input_text"
        case config-suggest-model csm
            _forge_command_suggest_model "$input_text"
        case tools t
            _forge_command_tools
        case config
            _forge_command_config
        case config-edit ce
            _forge_command_config_edit
        case skill
            _forge_command_skill
        case '*'
            return 1
    end

    return 0
end

function _forge_dispatch_workspace_actions --argument user_action input_text
    switch $user_action
        case workspace-sync sync
            _forge_command_sync "$input_text"
        case workspace-init sync-init
            _forge_command_sync_init "$input_text"
        case workspace-status sync-status
            _forge_command_sync_status "$input_text"
        case workspace-info sync-info
            _forge_command_sync_info "$input_text"
        case '*'
            return 1
    end

    return 0
end

function _forge_dispatch_auth_actions --argument user_action input_text
    switch $user_action
        case provider-login login
            _forge_command_login "$input_text"
        case logout
            _forge_command_logout "$input_text"
        case '*'
            return 1
    end

    return 0
end

function _forge_dispatch_action --argument user_action input_text
    # Status 1 means "not handled here"; status 2 means "handler already finished UI flow".
    _forge_dispatch_core_actions "$user_action" "$input_text"
    set -l dispatch_status $status
    if test $dispatch_status -ne 1
        return $dispatch_status
    end

    _forge_dispatch_config_actions "$user_action" "$input_text"
    set dispatch_status $status
    if test $dispatch_status -ne 1
        return $dispatch_status
    end

    _forge_dispatch_workspace_actions "$user_action" "$input_text"
    set dispatch_status $status
    if test $dispatch_status -ne 1
        return $dispatch_status
    end

    _forge_dispatch_auth_actions "$user_action" "$input_text"
    set dispatch_status $status
    if test $dispatch_status -ne 1
        return $dispatch_status
    end

    _forge_dispatch_default "$user_action" "$input_text"
    return 0
end

function _forge_begin_deferred_dispatch --argument buffer
    # Route through ":" so Fish redraw/title behavior matches a real command execution.
    set -g _FORGE_DEFERRED_EXEC_HISTORY "$buffer"
    set -g _FORGE_DEFERRED_EXEC_ERASE_WRAPPER 1
    set -g _FORGE_DEFERRED_EXEC_WRAPPER_COMMAND :
    printf '\033[?25l'
    commandline -r :
    commandline -f execute
end

function _forge_dispatch_has_visible_output
    test "$_FORGE_OUTPUT_MODE" = visible
end

function _forge_finalize_dispatch --argument buffer clear_when_idle
    if test "$_FORGE_PENDING_EXEC" = 1
        _forge_begin_deferred_dispatch "$buffer"
        return 0
    end

    # Visible output needs execute-driven redraw; quiet paths can use _forge_reader_reset.
    if _forge_dispatch_has_visible_output
        set --erase _FORGE_OUTPUT_MODE
        set -g _FORGE_RPROMPT_ZSH_CACHE ""
        set -g _FORGE_RPROMPT_DIRTY 1
        set -g _FORGE_SKIP_BLANK_LINE 1
        commandline -r ""
        commandline -f execute
        return 0
    end

    _forge_reader_reset
    if test "$clear_when_idle" = 1
        commandline -f clear-commandline
    end
end

function _forge_parse_exact_colon_command --argument buffer
    # Match only single-line :command [args] forms.
    set -l captures (string match --regex '^:([a-zA-Z][a-zA-Z0-9_-]*)( (.*))?$' -- "$buffer")
    if test (count $captures) -lt 2
        return 1
    end

    set -l user_action "$captures[2]"
    set -l input_text ''
    if test (count $captures) -ge 4
        set input_text "$captures[4]"
    end

    printf '%s\n%s\n' "$user_action" "$input_text"
end

function _forge_parse_colon_prompt_text --argument buffer
    if not string match -q ':*' -- "$buffer"
        return 1
    end

    # Everything else starting with ":" is prompt text, not a command name.
    set -l input_text (string sub -s 2 -- "$buffer")
    if string match -q ' *' -- "$input_text"
        set input_text (string sub -s 2 -- "$input_text")
    end

    printf '%s' "$input_text"
end

function _forge_execute_colon_command --argument buffer user_action input_text
    _forge_prepare_dispatch_lite "$buffer"

    set user_action (_forge_normalize_action_name "$user_action")
    _forge_dispatch_action "$user_action" "$input_text"
    set -l dispatch_status $status
    if test $dispatch_status -eq 2
        return 0
    end

    _forge_finalize_dispatch "$buffer" 0
end

function _forge_execute_colon_prompt --argument buffer input_text
    if test -z "$input_text"
        commandline -r ""
        commandline -f repaint
        return 0
    end

    _forge_prepare_dispatch_lite "$buffer"
    _forge_dispatch_default '' "$input_text"
    _forge_finalize_dispatch "$buffer" 1
end

function _forge_accept
    set -l buf (commandline)

    set -l parsed_command (_forge_parse_exact_colon_command "$buf")
    if test (count $parsed_command) -ge 1
        set -l user_action "$parsed_command[1]"
        set -l input_text ''
        if test (count $parsed_command) -ge 2
            set input_text "$parsed_command[2]"
        end

        _forge_execute_colon_command "$buf" "$user_action" "$input_text"
        return
    end

    set -l input_text (_forge_parse_colon_prompt_text "$buf" | string collect)
    if test $status -eq 0
        _forge_execute_colon_prompt "$buf" "$input_text"
        return
    end

    commandline -f execute
end
