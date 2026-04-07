function _forge_action_conversation
    set -l input_text ""
    if test (count $argv) -ge 1
        set input_text $argv[1]
    end

    echo

    if test "$input_text" = -
        if test -z "$_FORGE_PREVIOUS_CONVERSATION_ID"
            set input_text ""
        else
            set -l temp "$_FORGE_CONVERSATION_ID"
            set -g _FORGE_CONVERSATION_ID "$_FORGE_PREVIOUS_CONVERSATION_ID"
            set -g _FORGE_PREVIOUS_CONVERSATION_ID "$temp"

            echo
            _forge_exec conversation show "$_FORGE_CONVERSATION_ID"

            _forge_exec conversation info "$_FORGE_CONVERSATION_ID"

            _forge_log success "Switched to conversation "(set_color --bold)"$_FORGE_CONVERSATION_ID"(set_color normal)

            return 0
        end
    end

    if test -n "$input_text"
        set -l conversation_id "$input_text"

        _forge_switch_conversation "$conversation_id"

        echo
        _forge_exec conversation show "$conversation_id"

        _forge_exec conversation info "$conversation_id"

        _forge_log success "Switched to conversation "(set_color --bold)"$conversation_id"(set_color normal)

        return 0
    end

    set -l conversations_output ($_FORGE_BIN conversation list --porcelain 2>/dev/null | string collect)

    if test -n "$conversations_output"
        set -l current_id "$_FORGE_CONVERSATION_ID"

        set -l prompt_text "Conversation ❯ "
        set -l fzf_args \
            --prompt="$prompt_text" \
            --delimiter="$_FORGE_DELIMITER" \
            --with-nth="2,3" \
            --preview="CLICOLOR_FORCE=1 $_FORGE_BIN conversation info {1}; echo; CLICOLOR_FORCE=1 $_FORGE_BIN conversation show {1}" \
            $_FORGE_PREVIEW_WINDOW

        if test -n "$current_id"
            set -l index (_forge_find_index "$conversations_output" "$current_id" 1)
            set -a fzf_args --bind="start:pos($index)"
        end

        set -l selected_conversation (echo "$conversations_output" | _forge_fzf --header-lines=1 $fzf_args)

        if test -n "$selected_conversation"
            set -l conversation_id (echo "$selected_conversation" | sed -E 's/  .*//' | tr -d '\n')

            _forge_switch_conversation "$conversation_id"

            echo
            _forge_exec conversation show "$conversation_id"

            _forge_exec conversation info "$conversation_id"

            _forge_log success "Switched to conversation "(set_color --bold)"$conversation_id"(set_color normal)
        end
    else
        _forge_log error "No conversations found"
    end
end
