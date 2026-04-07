function _forge_command_conversation_list
    $_FORGE_BIN conversation list --porcelain 2>/dev/null | string collect
end

function _forge_command_conversation_row_id --argument row
    printf '%s\n' (string split -m 1 ' ' -- (string trim -- "$row"))[1]
end

function _forge_command_conversation_show_details --argument conversation_id
    echo
    _forge_run conversation show "$conversation_id"
    _forge_run conversation info "$conversation_id"
end

function _forge_command_conversation_activate --argument conversation_id
    _forge_conversation_switch "$conversation_id"
    _forge_command_conversation_show_details "$conversation_id"
    _forge_report success "Switched to conversation "(set_color --bold)"$conversation_id"(set_color normal)
end

function _forge_command_conversation_toggle_previous
    if test -z "$_FORGE_PREVIOUS_CONVERSATION_ID"
        return 1
    end

    set -l previous_id "$_FORGE_PREVIOUS_CONVERSATION_ID"
    set -g _FORGE_PREVIOUS_CONVERSATION_ID "$_FORGE_CONVERSATION_ID"
    set -g _FORGE_CONVERSATION_ID "$previous_id"

    _forge_command_conversation_show_details "$previous_id"
    _forge_report success "Switched to conversation "(set_color --bold)"$previous_id"(set_color normal)
    return 0
end

function _forge_command_conversation_pick_row --argument conversations_output current_id
    set -l fzf_args \
        '--prompt=Conversation ❯ ' \
        --delimiter="$_FORGE_DELIMITER" \
        --with-nth='2,3' \
        --preview="CLICOLOR_FORCE=1 $_FORGE_BIN conversation info {1}; echo; CLICOLOR_FORCE=1 $_FORGE_BIN conversation show {1}" \
        $_FORGE_PREVIEW_WINDOW

    if test -n "$current_id"
        set -l index (_forge_porcelain_find_index "$conversations_output" "$current_id" 1)
        set -a fzf_args --bind="start:pos($index)"
    end

    printf '%s\n' "$conversations_output" | _forge_fzf --header-lines=1 $fzf_args
end

function _forge_command_conversation
    set -l query "$argv[1]"

    echo

    if test "$query" = '-'
        if _forge_command_conversation_toggle_previous
            return 0
        end
        set query ''
    end

    if test -n "$query"
        _forge_command_conversation_activate "$query"
        return 0
    end

    set -l conversations_output (_forge_command_conversation_list)
    if test -z "$conversations_output"
        _forge_report error 'No conversations found'
        return 0
    end

    set -l selected_row (_forge_command_conversation_pick_row "$conversations_output" "$_FORGE_CONVERSATION_ID")
    if test -z "$selected_row"
        return 0
    end

    _forge_command_conversation_activate (_forge_command_conversation_row_id "$selected_row")
end
