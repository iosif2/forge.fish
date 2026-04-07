function _forge_command_commit
    set -l additional_context ""
    if test (count $argv) -ge 1
        set additional_context $argv[1]
    end

    echo

    set -lx FORCE_COLOR true
    set -lx CLICOLOR_FORCE 1
    set -l commit_message
    if test -n "$additional_context"
        set commit_message ($_FORGE_BIN commit --max-diff "$_FORGE_MAX_COMMIT_DIFF" $additional_context | string collect)
    else
        set commit_message ($_FORGE_BIN commit --max-diff "$_FORGE_MAX_COMMIT_DIFF" | string collect)
    end
end

