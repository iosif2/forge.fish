function _forge_complete_colons --description 'Emit completion candidates for Forge :commands'
    set -l seen_commands
    set -l static_commands \
        'new|Start new conversation' \
        'n|Alias for new' \
        'info|Print session information' \
        'i|Alias for info' \
        'env|Display environment information' \
        'e|Alias for env' \
        'dump|Save the conversation as JSON or HTML' \
        'd|Alias for dump' \
        'compact|Compact the conversation context' \
        'retry|Retry the last command' \
        'r|Alias for retry' \
        'agent|Select and switch between agents' \
        'a|Alias for agent' \
        'conversation|List or switch conversations' \
        'c|Alias for conversation' \
        'config-provider|Switch the provider' \
        'provider|Alias for config-provider' \
        'p|Alias for config-provider' \
        'config-model|Switch the global model' \
        'cm|Alias for config-model' \
        'model|Switch the current session model' \
        'm|Alias for model' \
        'model-reset|Reset the current session model override' \
        'mr|Alias for model-reset' \
        'config-commit-model|Set the commit message model' \
        'ccm|Alias for config-commit-model' \
        'config-suggest-model|Set the suggest command model' \
        'csm|Alias for config-suggest-model' \
        'tools|List available tools' \
        't|Alias for tools' \
        'config|List current configuration values' \
        'config-edit|Open the Forge config in an editor' \
        'ce|Alias for config-edit' \
        'skill|List available skills' \
        'edit|Open an external editor for the prompt' \
        'ed|Alias for edit' \
        'commit|Generate and commit an AI-written message' \
        'commit-preview|Preview an AI-written commit message' \
        'suggest|Generate shell commands without executing them' \
        's|Alias for suggest' \
        'clone|Clone and manage conversation context' \
        'rename|Rename the current conversation' \
        'rn|Alias for rename' \
        'conversation-rename|Rename a conversation by ID or interactively' \
        'copy|Copy the last assistant message to the clipboard' \
        'workspace-sync|Sync the current workspace' \
        'sync|Alias for workspace-sync' \
        'workspace-init|Initialize a workspace without syncing files' \
        'sync-init|Alias for workspace-init' \
        'workspace-status|Show workspace sync status' \
        'sync-status|Alias for workspace-status' \
        'workspace-info|Show workspace information' \
        'sync-info|Alias for workspace-info' \
        'provider-login|Login to a provider' \
        'login|Alias for provider-login' \
        'logout|Logout from a provider' \
        'doctor|Run shell diagnostics' \
        'keyboard-shortcuts|Display keyboard shortcuts' \
        'kb|Alias for keyboard-shortcuts' \
        'sage|Strategic reasoning agent' \
        'muse|Planning agent'

    function _forge_complete_colons_emit --no-scope-shadowing --argument command_name description
        contains -- "$command_name" $seen_commands
        and return 0

        set -a seen_commands "$command_name"
        printf '%s\t%s\n' "$command_name" "$description"
    end

    for row in $static_commands
        set -l parts (string split -m 1 '|' -- "$row")
        if test (count $parts) -lt 2
            continue
        end

        _forge_complete_colons_emit "$parts[1]" "$parts[2]"
    end

    set -l commands_list (_forge_commands_get | string collect)
    if test -z "$commands_list"
        return 0
    end

    for line in (string split \n -- "$commands_list")
        set -l row (string match --regex '^([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+(.+)$' -- "$line")
        if test (count $row) -lt 4
            continue
        end

        set -l command_name "$row[2]"
        set -l description "$row[4]"
        if test "$command_name" = 'COMMAND'
            continue
        end

        _forge_complete_colons_emit "$command_name" "$description"
    end

    functions --erase _forge_complete_colons_emit
end
