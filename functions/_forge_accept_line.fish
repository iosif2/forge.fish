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

function _forge_is_builtin_colon_command --argument user_action
    switch $user_action
        case ask plan \
            new n \
            info i \
            env e \
            dump d \
            compact \
            retry r \
            agent a \
            conversation c \
            config-provider provider p \
            config-model cm \
            model m \
            config-reload cr model-reset mr \
            reasoning-effort re \
            config-reasoning-effort cre \
            config-commit-model ccm \
            config-suggest-model csm \
            tools t \
            config \
            config-edit ce \
            skill \
            edit ed \
            commit \
            commit-preview \
            suggest s \
            clone \
            rename rn \
            conversation-rename \
            copy \
            workspace-sync sync \
            workspace-init sync-init \
            workspace-status sync-status \
            workspace-info sync-info \
            provider-login login \
            logout \
            doctor \
            keyboard-shortcuts kb
            return 0
    end

    return 1
end

function _forge_is_dispatchable_colon_command --argument user_action
    if _forge_is_builtin_colon_command "$user_action"
        return 0
    end

    set -l commands_list (_forge_get_commands | string collect)
    if test -z "$commands_list"
        return 1
    end

    string match -rq -- '^'(string escape --style=regex -- "$user_action")'[[:space:]]' \
        (string split \n -- "$commands_list")
end

function _forge_accept_line
    set -l buf (commandline)

    # --- Pattern 1: exact single-line :command [args] ---
    set -l captures (string match --regex '^:([a-zA-Z][a-zA-Z0-9_-]*)( (.*))?$' -- "$buf")
    if test (count $captures) -ge 2
        set -l user_action $captures[2]
        if _forge_is_dispatchable_colon_command "$user_action"
            set -l input_text ''
            if test (count $captures) -ge 4
                set input_text $captures[4]
            end

            # Use lite prep (no clear-commandline) so that if the action sets
            # _FORGE_PENDING_EXEC we can still write _forge_deferred_exec into the
            # buffer before queueing execute.
            _forge_prepare_dispatch_lite "$buf"

            switch $user_action
                case ask
                    set user_action sage
                case plan
                    set user_action muse
            end

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
                case edit ed
                    _forge_action_editor "$input_text"
                    return
                case commit
                    _forge_action_commit "$input_text"
                case commit-preview
                    _forge_action_commit_preview "$input_text"
                    return
                case suggest s
                    _forge_action_suggest "$input_text"
                    return
                case clone
                    _forge_action_clone "$input_text"
                case rename rn
                    _forge_action_rename "$input_text"
                case conversation-rename
                    _forge_action_conversation_rename "$input_text"
                case copy
                    _forge_action_copy
                case workspace-sync sync
                    _forge_action_sync "$input_text"
                case workspace-init sync-init
                    _forge_action_sync_init "$input_text"
                case workspace-status sync-status
                    _forge_action_sync_status "$input_text"
                case workspace-info sync-info
                    _forge_action_sync_info "$input_text"
                case provider-login login
                    _forge_action_login "$input_text"
                case logout
                    _forge_action_logout "$input_text"
                case doctor
                    _forge_action_doctor
                case keyboard-shortcuts kb
                    _forge_action_keyboard
                case '*'
                    _forge_action_default "$user_action" "$input_text"
            end

            if test "$_FORGE_PENDING_EXEC" = 1
                # Hand off through the public : wrapper so Fish/tmux titles show
                # : instead of the private _forge_deferred_exec helper while still
                # running the deferred exec path in normal command execution.
                # NOTE: do NOT queue clear-commandline before this — it would wipe
                # the buffer we set here before execute fires.
                # Preserve the original typed command so deferred execution can
                # repair Fish history after the wrapper command runs.
                set -g _FORGE_DEFERRED_EXEC_HISTORY "$buf"
                set -g _FORGE_DEFERRED_EXEC_ERASE_WRAPPER 1
                set -g _FORGE_DEFERRED_EXEC_WRAPPER_COMMAND :
                # Hide cursor so the : text Fish echoes before running the
                # command is not perceived as a flash.
                printf '\033[?25l'
                commandline -r :
                commandline -f execute
                return
            end

            if test "$_FORGE_SKIP_RESET" = 1
                set --erase _FORGE_SKIP_RESET
                set --erase _FORGE_POST_INTERACTIVE_NEWLINE
                set --erase _FORGE_POST_OUTPUT_PADDING
                commandline -r ""
                return
            end

            # Non-pending path.
            # When visible output was produced, use commandline -f execute with an
            # empty buffer. execute causes Fish to draw a new prompt from the
            # CURRENT cursor position (below the output) rather than scrolling back
            # to the original prompt position the way repaint/clear-commandline do.
            # When no output was produced, _forge_reset handles the repaint.
            set -l _forge_had_output 0
            if test "$_FORGE_POST_OUTPUT_PADDING" = 1; or test "$_FORGE_POST_INTERACTIVE_NEWLINE" = 1
                set _forge_had_output 1
            end
            if test "$_forge_had_output" = 1
                set --erase _FORGE_POST_OUTPUT_PADDING
                set --erase _FORGE_POST_INTERACTIVE_NEWLINE
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
                return
            end
            _forge_reset
            return
        end
    end

    if string match -q ':*' -- "$buf"
        # Treat every other :buffer as raw prompt text, preserving punctuation,
        # whitespace, and embedded newlines. A single optional space after : is
        # stripped for convenience so both ":hello" and ": hello" work.
        set -l input_text (string sub -s 2 -- "$buf")
        if string match -q ' *' -- "$input_text"
            set input_text (string sub -s 2 -- "$input_text")
        end

        if test -z "$input_text"
            commandline -r ""
            commandline -f repaint
            return 0
        end

        # Use lite prep (no clear-commandline) for the same reason as Pattern 1.
        _forge_prepare_dispatch_lite "$buf"
        _forge_action_default '' "$input_text"
        if test "$_FORGE_PENDING_EXEC" = 1
            # Preserve the raw :prompt buffer verbatim in history and bypass the
            # shell parser so characters such as parentheses or embedded newlines
            # are not reinterpreted before Forge receives the prompt text.
            set -g _FORGE_DEFERRED_EXEC_HISTORY "$buf"
            set -g _FORGE_DEFERRED_EXEC_ERASE_WRAPPER 1
            set -g _FORGE_DEFERRED_EXEC_WRAPPER_COMMAND :
            printf '\033[?25l'
            commandline -r :
            commandline -f execute
            return
        end

        if test "$_FORGE_SKIP_RESET" = 1
            set --erase _FORGE_SKIP_RESET
            set --erase _FORGE_POST_INTERACTIVE_NEWLINE
            set --erase _FORGE_POST_OUTPUT_PADDING
            commandline -r ""
            return
        end

        # Non-pending path: same logic as Pattern 1.
        set -l _forge_had_output 0
        if test "$_FORGE_POST_OUTPUT_PADDING" = 1; or test "$_FORGE_POST_INTERACTIVE_NEWLINE" = 1
            set _forge_had_output 1
        end
        _forge_reset
        if test "$_forge_had_output" = 0
            commandline -f clear-commandline
        end
        return
    end

    commandline -f execute
end
