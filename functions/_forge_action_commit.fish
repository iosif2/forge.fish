# Action handler: Directly commit changes with AI-generated message
# Port of _forge_action_commit from zsh.
# Usage: _forge_action_commit [additional_context]
# Note: This action intentionally captures the generated output and relies on
# centralized reset handling after dispatch.

function _forge_action_commit
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

