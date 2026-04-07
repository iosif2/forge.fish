function _forge_action_editor
    set -l initial_text ""
    if test (count $argv) -ge 1
        set initial_text $argv[1]
    end
    echo

    set -l editor_cmd
    if test -n "$FORGE_EDITOR"
        set editor_cmd "$FORGE_EDITOR"
    else if test -n "$EDITOR"
        set editor_cmd "$EDITOR"
    else
        set editor_cmd nano
    end

    set -l editor_bin (string split ' ' -- "$editor_cmd")[1]
    if not command -q "$editor_bin"
        _forge_log error "Editor not found: $editor_cmd (set FORGE_EDITOR or EDITOR)"
        return 1
    end

    set -l forge_dir .forge
    if not test -d "$forge_dir"
        mkdir -p "$forge_dir"
        or begin
            _forge_log error "Failed to create .forge directory"
            return 1
        end
    end

    set -l temp_file "$forge_dir/FORGE_EDITMSG.md"
    touch "$temp_file"
    or begin
        _forge_log error "Failed to create temporary file"
        return 1
    end

    if test -n "$initial_text"
        echo "$initial_text" > "$temp_file"
    end

    eval "$editor_cmd '$temp_file'" </dev/tty >/dev/tty 2>&1
    set -l editor_exit_code $status

    if test $editor_exit_code -ne 0
        _forge_log error "Editor exited with error code $editor_exit_code"
        rm -f "$temp_file"
        _forge_reset
        return 1
    end

    set -l content (cat "$temp_file" | tr -d '\r' | string collect)

    rm -f "$temp_file"

    if test -z "$content"
        _forge_log info "Editor closed with no content"
        commandline -r ""
        commandline -f repaint
        return 0
    end

    commandline -r ": $content"
    commandline -f repaint
end
