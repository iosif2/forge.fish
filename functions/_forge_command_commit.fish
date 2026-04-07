function _forge_command_commit
    set -l additional_context "$argv[1]"
    set -l commit_args --max-diff "$_FORGE_MAX_COMMIT_DIFF"

    if test -n "$additional_context"
        set -a commit_args "$additional_context"
    end

    echo

    set -lx FORCE_COLOR true
    set -lx CLICOLOR_FORCE 1
    set -l _commit_message ($_FORGE_BIN commit $commit_args | string collect)
end
