#!/usr/bin/env fish

set -l test_dir (path dirname (status filename))
source "$test_dir/fixtures/extension.fish"

forge_test_bootstrap
forge_test_setup_tmpdir

function test_commands_cache
    forge_test_reset

    set -l commands (_forge_commands_get | string collect)
    forge_test_assert_contains "COMMAND    TYPE    DESCRIPTION" "$commands" "commands header should be present"
    or return 1
    forge_test_assert_contains "sage    AGENT" "$commands" "sage agent row should be present"
    or return 1
    forge_test_assert_contains "new    CUSTOM" "$commands" "new custom row should be present"
    or return 1

    set -l cached (_forge_commands_get | string collect)
    forge_test_assert_eq "$commands" "$cached" "cached commands output should remain stable"
    or return 1
    forge_test_assert_log_python 'len(entries) == 1 and entries[0]["argv"] == ["list", "commands", "--porcelain"]' "commands should be fetched only once per reset"
    or return 1
end

function test_agent_branch
    forge_test_reset

    _forge_dispatch_default sage ""
    forge_test_assert_eq "sage" "$_FORGE_ACTIVE_AGENT" "agent branch should activate sage"
    or return 1
    forge_test_assert_log_python 'len(entries) == 1 and entries[0]["argv"] == ["list", "commands", "--porcelain"]' "agent selection should only consult list commands"
    or return 1
end

function test_custom_preprocessing
    forge_test_reset

    _forge_dispatch_default new ""
    forge_test_assert_eq "cid-stub-001" "$_FORGE_CONVERSATION_ID" "custom branch should create a conversation id"
    or return 1
    forge_test_assert_log_python 'len(entries) == 3 and entries[1]["argv"] == ["conversation", "new"] and entries[2]["argv"] == ["cmd", "execute", "--cid", "cid-stub-001", "new"]' "custom branch should create a cid and execute the command"
    or return 1
end

test_commands_cache
or begin
    forge_test_cleanup
    exit 1
end

test_agent_branch
or begin
    forge_test_cleanup
    exit 1
end

test_custom_preprocessing
or begin
    forge_test_cleanup
    exit 1
end

forge_test_cleanup
printf 'test_commands: ok\n'
