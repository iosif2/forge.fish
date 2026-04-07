function _forge_command_commit_preview_git_command --argument commit_message
    set -l escaped_message (string escape -- "$commit_message")

    if git diff --staged --quiet
        printf '%s\n' "git commit -am $escaped_message"
        return 0
    end

    printf '%s\n' "git commit -m $escaped_message"
end

function _forge_command_commit_preview
    set -l additional_context "$argv[1]"
    set -l commit_args --preview --max-diff "$_FORGE_MAX_COMMIT_DIFF"

    if test -n "$additional_context"
        set -a commit_args "$additional_context"
    end

    echo

    set -lx FORCE_COLOR true
    set -lx CLICOLOR_FORCE 1
    set -l commit_message ($_FORGE_BIN commit $commit_args | string collect)
    if test -z "$commit_message"
        _forge_reader_reset
        return 0
    end

    commandline -r (_forge_command_commit_preview_git_command "$commit_message")
    commandline -f repaint
end
