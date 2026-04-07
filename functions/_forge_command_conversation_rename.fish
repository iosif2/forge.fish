function _forge_command_conversation_rename_row_id --argument row
    printf '%s\n' (string split -m 1 ' ' -- (string trim -- "$row"))[1]
end

function _forge_command_conversation_rename_pick_row --argument conversations_output current_id
    set -l fzf_args \
        '--prompt=Rename Conversation ❯ ' \
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

function _forge_command_conversation_rename_apply --argument conversation_id new_name
    if test -z "$new_name"
        _forge_report error 'No name provided, rename cancelled'
        return 0
    end

    _forge_run conversation rename "$conversation_id" "$new_name"
end

function _forge_command_conversation_rename
    set -l input_text "$argv[1]"

    echo

    if test -n "$input_text"
        set -l parts (string split -m 1 ' ' -- "$input_text")
        set -l conversation_id "$parts[1]"
        set -l new_name "$parts[2]"

        if test -z "$new_name"
            _forge_report error 'Usage: :conversation-rename <id> <name>'
            return 0
        end

        _forge_run conversation rename "$conversation_id" "$new_name"
        return 0
    end

    set -l conversations_output ($_FORGE_BIN conversation list --porcelain 2>/dev/null | string collect)
    if test -z "$conversations_output"
        _forge_report error 'No conversations found'
        return 0
    end

    set -l selected_row (_forge_command_conversation_rename_pick_row "$conversations_output" "$_FORGE_CONVERSATION_ID")
    if test -z "$selected_row"
        return 0
    end

    read -P 'Enter new name: ' new_name </dev/tty
    _forge_command_conversation_rename_apply (_forge_command_conversation_rename_row_id "$selected_row") "$new_name"
end
