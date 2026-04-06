# Custom completion handler for forge fish plugin
# Port of forge-completion ZLE widget from zsh.
# Handles @file completion, :command completion, and normal fish completion.
# Bound to Tab in conf.d/forge.fish.
# Usage: bound via `bind \t _forge_completion`

function _forge_completion
    # Get the full buffer and cursor position
    set -l buf (commandline)
    set -l cursor_pos (commandline -C)

    # Get text before cursor
    set -l lbuffer (string sub -l $cursor_pos -- "$buf")

    # Get current word (last space-separated token before cursor)
    set -l current_word (string match -r '[^ ]*$' -- "$lbuffer")

    # Handle @ completion (files and directories)
    if string match -rq '^@' -- "$current_word"
        set -l filter_text (string sub -s 2 -- "$current_word")
        set -l fzf_args \
            --preview="if [ -d {} ]; then ls -la {} 2>/dev/null; else $_FORGE_CAT_CMD {}; fi" \
            $_FORGE_PREVIEW_WINDOW

        set -l file_list_path (mktemp)
        or return 1

        $_FORGE_FD_CMD --type f --type d --hidden --exclude .git > "$file_list_path"
        or begin
            rm -f "$file_list_path"
            return 1
        end

        set -g _FORGE_FZF_SELECTION ""
        if test -n "$filter_text"
            _forge_fzf_from_stdin --input-file "$file_list_path" --query "$filter_text" $fzf_args
        else
            _forge_fzf_from_stdin --input-file "$file_list_path" $fzf_args
        end
        rm -f "$file_list_path"
        set -l selected "$_FORGE_FZF_SELECTION"

        if test -n "$selected"
            set selected "@[$selected]"
            # Replace current_word in lbuffer with the selection
            set -l prefix (string sub -l (math $cursor_pos - (string length -- "$current_word")) -- "$buf")
            set -l rbuffer (string sub -s (math $cursor_pos + 1) -- "$buf")
            set -l new_buf "$prefix$selected$rbuffer"
            commandline -r "$new_buf"
            commandline -C (math (string length -- "$prefix") + (string length -- "$selected"))
        end

        commandline -f repaint
        return 0
    end

    # Handle :command completion using the same porcelain rows and fzf layout
    # as the zsh plugin.
    if string match -rq '^:([a-zA-Z][a-zA-Z0-9_-]*)?$' -- "$lbuffer"
        set -l filter_text (string sub -s 2 -- "$lbuffer")
        set -l commands_list (_forge_get_commands | string collect)
        if test -n "$commands_list"
            set -l candidates_file (mktemp)
            or return 1
            printf '%s\n' "$commands_list" > "$candidates_file"

            set -l fzf_args \
                --header-lines=1 \
                --delimiter="$_FORGE_DELIMITER" \
                --nth=1 \
                '--prompt=Command ❯ '

            if test -n "$filter_text"
                set fzf_args $fzf_args --query="$filter_text"
            end

            set -g _FORGE_FZF_SELECTION ""
            _forge_fzf_from_stdin --input-file "$candidates_file" $fzf_args
            rm -f "$candidates_file"
            set -l selected "$_FORGE_FZF_SELECTION"

            if test -n "$selected"
                set -l command_match (string match -r '^([^[:space:]]+)' -- (string trim -- "$selected"))
                if test (count $command_match) -ge 2
                    set -l command_name "$command_match[2]"
                    set -l rbuffer (string sub -s (math $cursor_pos + 1) -- "$buf")
                    commandline -r ":$command_name $rbuffer"
                    commandline -C (math 2 + (string length -- "$command_name"))
                end
            end
        end

        commandline -f repaint
        return 0
    end

    # Fall back to default fish completion
    commandline -f complete
end
