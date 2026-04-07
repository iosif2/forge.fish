function _forge_command_editor_editor
    if test -n "$FORGE_EDITOR"
        printf '%s\n' "$FORGE_EDITOR"
        return 0
    end
    if test -n "$EDITOR"
        printf '%s\n' "$EDITOR"
        return 0
    end
    printf '%s\n' nano
end

function _forge_command_editor
    set -l initial_text "$argv[1]"

    echo

    set -l editor_cmd (_forge_command_editor_editor)
    set -l editor_bin (string split ' ' -- "$editor_cmd")[1]
    if not command -q "$editor_bin"
        _forge_report error "Editor not found: $editor_cmd (set FORGE_EDITOR or EDITOR)"
        return 1
    end

    set -l forge_dir .forge
    set -l temp_file "$forge_dir/FORGE_EDITMSG.md"

    mkdir -p "$forge_dir"
    or begin
        _forge_report error 'Failed to create .forge directory'
        return 1
    end

    touch "$temp_file"
    or begin
        _forge_report error 'Failed to create temporary file'
        return 1
    end

    if test -n "$initial_text"
        printf '%s\n' "$initial_text" > "$temp_file"
    end

    eval "$editor_cmd '$temp_file'" </dev/tty >/dev/tty 2>&1
    set -l exit_code $status
    if test $exit_code -ne 0
        _forge_report error "Editor exited with error code $exit_code"
        rm -f "$temp_file"
        _forge_reader_reset
        return 1
    end

    set -l content (tr -d '\r' < "$temp_file" | string collect)
    rm -f "$temp_file"

    if test -z "$content"
        _forge_report info 'Editor closed with no content'
        commandline -r ''
        commandline -f repaint
        return 0
    end

    commandline -r ": $content"
    commandline -f repaint
end
