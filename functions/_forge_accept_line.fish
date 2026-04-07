# Core dispatcher for forge :commands
# Port of forge-accept-line ZLE widget from shell-plugin/lib/dispatcher.zsh
#
# Patterns:
#   :command [args]  - dispatch to the appropriate action handler
#   : <text>         - default action (send text to active agent)
#   anything else    - normal shell command execution

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
    # Lightweight version of _forge_prepare_dispatch.
    # Does NOT queue clear-commandline (would wipe deferred-exec buffer before
    # execute fires) and does NOT queue repaint (repaint fires after the binding
    # returns, AFTER stdout output has been printed — queuing repaint here causes
    # Fish to scroll back to the original prompt position and overwrite that
    # output). Each code path in _forge_accept_line handles its own repaint or
    # clear-commandline at the appropriate time.
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
            _forge_action_new "$input_text"
        case info i
            _forge_action_info
        case env e
            _forge_action_env
        case dump d
            _forge_action_dump "$input_text"
        case compact
            _forge_action_compact
        case retry r
            _forge_action_retry
        case agent a
            _forge_action_agent "$input_text"
        case conversation c
            _forge_action_conversation "$input_text"
        case edit ed
            _forge_action_editor "$input_text"
            return 2
        case commit
            _forge_action_commit "$input_text"
        case commit-preview
            _forge_action_commit_preview "$input_text"
            return 2
        case suggest s
            _forge_action_suggest "$input_text"
            return 2
        case clone
            _forge_action_clone "$input_text"
        case rename rn
            _forge_action_rename "$input_text"
        case conversation-rename
            _forge_action_conversation_rename "$input_text"
        case copy
            _forge_action_copy
        case doctor
            _forge_action_doctor
        case keyboard-shortcuts kb
            _forge_action_keyboard
        case '*'
            return 1
    end

    return 0
end

function _forge_dispatch_config_actions --argument user_action input_text
    switch $user_action
        case config-provider provider p
            _forge_action_provider "$input_text"
        case config-model cm
            _forge_action_model "$input_text"
        case model m
            _forge_action_session_model "$input_text"
        case config-reload cr model-reset mr
            _forge_action_config_reload
        case reasoning-effort re
            _forge_action_reasoning_effort "$input_text"
        case config-reasoning-effort cre
            _forge_action_config_reasoning_effort "$input_text"
        case config-commit-model ccm
            _forge_action_commit_model "$input_text"
        case config-suggest-model csm
            _forge_action_suggest_model "$input_text"
        case tools t
            _forge_action_tools
        case config
            _forge_action_config
        case config-edit ce
            _forge_action_config_edit
        case skill
            _forge_action_skill
        case '*'
            return 1
    end

    return 0
end

function _forge_dispatch_workspace_actions --argument user_action input_text
    switch $user_action
        case workspace-sync sync
            _forge_action_sync "$input_text"
        case workspace-init sync-init
            _forge_action_sync_init "$input_text"
        case workspace-status sync-status
            _forge_action_sync_status "$input_text"
        case workspace-info sync-info
            _forge_action_sync_info "$input_text"
        case '*'
            return 1
    end

    return 0
end

function _forge_dispatch_auth_actions --argument user_action input_text
    switch $user_action
        case provider-login login
            _forge_action_login "$input_text"
        case logout
            _forge_action_logout "$input_text"
        case '*'
            return 1
    end

    return 0
end

function _forge_dispatch_action --argument user_action input_text
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

    _forge_action_default "$user_action" "$input_text"
    return 0
end

function _forge_begin_deferred_dispatch --argument buffer
    # Hand off through the public : wrapper so Fish/tmux titles show
    # : instead of the private _forge_deferred_exec helper while still
    # running the deferred exec path in normal command execution.
    # NOTE: do NOT queue clear-commandline before this — it would wipe
    # the buffer we set here before execute fires.
    # Preserve the original typed command so deferred execution can
    # repair Fish history after the wrapper command runs.
    set -g _FORGE_DEFERRED_EXEC_HISTORY "$buffer"
    set -g _FORGE_DEFERRED_EXEC_ERASE_WRAPPER 1
    set -g _FORGE_DEFERRED_EXEC_WRAPPER_COMMAND :
    # Hide cursor so the : text Fish echoes before running the
    # command is not perceived as a flash.
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

    # When visible output was produced, use commandline -f execute with an
    # empty buffer. execute causes Fish to draw a new prompt from the
    # CURRENT cursor position (below the output) rather than scrolling back
    # to the original prompt position the way repaint/clear-commandline do.
    # When no output was produced, _forge_reset handles the repaint.
    if _forge_dispatch_has_visible_output
        set --erase _FORGE_OUTPUT_MODE
        # Clear rprompt cache so any intermediate render (from
        # suppress-autosuggestion or execute processing) shows nothing
        # rather than a floating rprompt at the wrong position.
        set -g _FORGE_RPROMPT_ZSH_CACHE ""
        set -g _FORGE_RPROMPT_DIRTY 1
        # execute adds a blank newline before drawing the new prompt.
        # Signal _forge_skip_blank_line so the fish_prompt event handler
        # can erase it before the prompt renders.
        set -g _FORGE_SKIP_BLANK_LINE 1
        commandline -r ""
        commandline -f execute
        return 0
    end

    _forge_reset
    if test "$clear_when_idle" = 1
        commandline -f clear-commandline
    end
end

function _forge_parse_exact_colon_command --argument buffer
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

    # Treat every other :buffer as raw prompt text, preserving punctuation,
    # whitespace, and embedded newlines. A single optional space after : is
    # stripped for convenience so both ":hello" and ": hello" work.
    set -l input_text (string sub -s 2 -- "$buffer")
    if string match -q ' *' -- "$input_text"
        set input_text (string sub -s 2 -- "$input_text")
    end

    printf '%s' "$input_text"
end

function _forge_execute_colon_command --argument buffer user_action input_text
    # Use lite prep (no clear-commandline) so that if the action sets
    # _FORGE_PENDING_EXEC we can still write _forge_deferred_exec into the
    # buffer before queueing execute.
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

    # Use lite prep (no clear-commandline) for the same reason as exact
    # :command dispatch.
    _forge_prepare_dispatch_lite "$buffer"
    _forge_action_default '' "$input_text"
    _forge_finalize_dispatch "$buffer" 1
end

function _forge_accept_line
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
