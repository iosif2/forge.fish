function _forge_accept_supports_search_field
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

function _forge_accept_prepare --argument buffer
    set -l in_reader_submode 0

    if commandline --paging-mode >/dev/null; or commandline --search-mode >/dev/null
        set in_reader_submode 1
    else if _forge_accept_supports_search_field; and commandline --search-field >/dev/null
        set in_reader_submode 1
    end

    if test "$in_reader_submode" = 1
        commandline -f cancel
    end

    commandline -f suppress-autosuggestion
    commandline -C (string length -- "$buffer")
end

function _forge_accept_normalize_command --argument name
    switch $name
        case ask
            printf '%s\n' sage
        case plan
            printf '%s\n' muse
        case '*'
            printf '%s\n' "$name"
    end
end

set -g _FORGE_ACCEPT_DISPATCH_HANDLED 0
set -g _FORGE_ACCEPT_DISPATCH_NEXT 1
set -g _FORGE_ACCEPT_DISPATCH_FINISHED 2

function _forge_accept_dispatch_core --argument name text
    switch $name
        case new n
            _forge_command_new "$text"
        case info i
            _forge_command_info
        case env e
            _forge_command_env
        case dump d
            _forge_command_dump "$text"
        case compact
            _forge_command_compact
        case retry r
            _forge_command_retry
        case agent a
            _forge_command_agent "$text"
        case conversation c
            _forge_command_conversation "$text"
        case edit ed
            _forge_command_editor "$text"
            return $_FORGE_ACCEPT_DISPATCH_FINISHED
        case commit
            _forge_command_commit "$text"
        case commit-preview
            _forge_command_commit_preview "$text"
            return $_FORGE_ACCEPT_DISPATCH_FINISHED
        case suggest s
            _forge_command_suggest "$text"
            return $_FORGE_ACCEPT_DISPATCH_FINISHED
        case clone
            _forge_command_clone "$text"
        case rename rn
            _forge_command_rename "$text"
        case conversation-rename
            _forge_command_conversation_rename "$text"
        case copy
            _forge_command_copy
        case doctor
            _forge_command_doctor
        case keyboard-shortcuts kb
            _forge_command_keyboard
        case '*'
            return $_FORGE_ACCEPT_DISPATCH_NEXT
    end

    return $_FORGE_ACCEPT_DISPATCH_HANDLED
end

function _forge_accept_dispatch_config --argument name text
    switch $name
        case config-provider provider p
            _forge_command_provider "$text"
        case config-model cm
            _forge_command_model "$text"
        case model m
            _forge_command_session_model "$text"
        case config-reload cr model-reset mr
            _forge_command_config_reload
        case reasoning-effort re
            _forge_command_reasoning_effort "$text"
        case config-reasoning-effort cre
            _forge_command_config_reasoning_effort "$text"
        case config-commit-model ccm
            _forge_command_commit_model "$text"
        case config-suggest-model csm
            _forge_command_suggest_model "$text"
        case tools t
            _forge_command_tools
        case config
            _forge_command_config
        case config-edit ce
            _forge_command_config_edit
        case skill
            _forge_command_skill
        case '*'
            return $_FORGE_ACCEPT_DISPATCH_NEXT
    end

    return $_FORGE_ACCEPT_DISPATCH_HANDLED
end

function _forge_accept_dispatch_workspace --argument name text
    switch $name
        case workspace-sync sync
            _forge_command_sync "$text"
        case workspace-init sync-init
            _forge_command_sync_init "$text"
        case workspace-status sync-status
            _forge_command_sync_status "$text"
        case workspace-info sync-info
            _forge_command_sync_info "$text"
        case '*'
            return $_FORGE_ACCEPT_DISPATCH_NEXT
    end

    return $_FORGE_ACCEPT_DISPATCH_HANDLED
end

function _forge_accept_dispatch_auth --argument name text
    switch $name
        case provider-login login
            _forge_command_login "$text"
        case logout
            _forge_command_logout "$text"
        case '*'
            return $_FORGE_ACCEPT_DISPATCH_NEXT
    end

    return $_FORGE_ACCEPT_DISPATCH_HANDLED
end

function _forge_accept_dispatch_command --argument name text
    for dispatcher in \
        _forge_accept_dispatch_core \
        _forge_accept_dispatch_config \
        _forge_accept_dispatch_workspace \
        _forge_accept_dispatch_auth
        $dispatcher "$name" "$text"
        set -l dispatcher_status $status

        if test "$dispatcher_status" -ne $_FORGE_ACCEPT_DISPATCH_NEXT
            return $dispatcher_status
        end
    end

    _forge_dispatch_default "$name" "$text"
    return $_FORGE_ACCEPT_DISPATCH_HANDLED
end

function _forge_accept_queue_deferred --argument buffer
    set -g _FORGE_DEFERRED_EXEC_HISTORY "$buffer"
    set -g _FORGE_DEFERRED_EXEC_ERASE_WRAPPER 1
    set -g _FORGE_DEFERRED_EXEC_WRAPPER_COMMAND :
    printf '\033[?25l'
    commandline -r :
    commandline -f execute
end

function _forge_accept_finish --argument buffer clear_when_idle
    if test "$_FORGE_PENDING_EXEC" = 1
        _forge_accept_queue_deferred "$buffer"
        return 0
    end

    if test "$_FORGE_OUTPUT_MODE" = visible
        set --erase _FORGE_OUTPUT_MODE
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

function _forge_accept_parse_command --argument buffer
    set -l match (string match --regex '^:([a-zA-Z][a-zA-Z0-9_-]*)( (.*))?$' -- "$buffer")
    if test (count $match) -lt 2
        return 1
    end

    set -l name "$match[2]"
    set -l text ''
    if test (count $match) -ge 4
        set text "$match[4]"
    end

    printf '%s\n%s\n' "$name" "$text"
end

function _forge_accept_parse_prompt --argument buffer
    string match -q ':*' -- "$buffer"
    or return 1

    set -l text (string sub -s 2 -- "$buffer")
    if string match -q ' *' -- "$text"
        set text (string sub -s 2 -- "$text")
    end

    printf '%s' "$text"
end

function _forge_accept_run_command --argument buffer name text
    _forge_accept_prepare "$buffer"

    set name (_forge_accept_normalize_command "$name")
    _forge_accept_dispatch_command "$name" "$text"
    set -l dispatch_status $status

    if test "$dispatch_status" -eq $_FORGE_ACCEPT_DISPATCH_FINISHED
        return 0
    end

    _forge_accept_finish "$buffer" 0
end

function _forge_accept_run_prompt --argument buffer text
    if test -z "$text"
        commandline -r ""
        commandline -f repaint
        return 0
    end

    _forge_accept_prepare "$buffer"
    _forge_dispatch_default '' "$text"
    _forge_accept_finish "$buffer" 1
end

function _forge_accept
    set -l buffer (commandline)

    set -l parsed_command (_forge_accept_parse_command "$buffer")
    if test $status -eq 0
        set -l name "$parsed_command[1]"
        set -l text ''
        if test (count $parsed_command) -ge 2
            set text "$parsed_command[2]"
        end

        _forge_accept_run_command "$buffer" "$name" "$text"
        return
    end

    set -l prompt_text (_forge_accept_parse_prompt "$buffer" | string collect)
    if test $status -eq 0
        _forge_accept_run_prompt "$buffer" "$prompt_text"
        return
    end

    commandline -f execute
end
