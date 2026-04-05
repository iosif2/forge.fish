#!/usr/bin/env fish

set -l test_dir (path dirname (status filename))
source "$test_dir/fixtures/extension.fish"

forge_test_bootstrap
forge_test_setup_tmpdir

function test_custom_creates_conversation_once
    forge_test_reset

    _forge_action_default new "hello world"
    forge_test_assert_eq "cid-stub-001" "$_FORGE_CONVERSATION_ID" "first custom call should persist the generated conversation id"
    or return 1
    forge_test_assert_log_python 'len(entries) == 3 and entries[1]["argv"] == ["conversation", "new"] and entries[2]["argv"] == ["cmd", "execute", "--cid", "cid-stub-001", "new", "hello world"]' "first custom execution should create a cid before running cmd execute"
    or return 1
end

function test_custom_reuses_existing_conversation
    forge_test_reset
    set -g _FORGE_CONVERSATION_ID "cid-existing"

    _forge_action_default new "follow up"
    forge_test_assert_eq "cid-existing" "$_FORGE_CONVERSATION_ID" "existing conversation id should be reused"
    or return 1
    forge_test_assert_log_python 'len(entries) == 2 and entries[0]["argv"] == ["list", "commands", "--porcelain"] and entries[1]["argv"] == ["cmd", "execute", "--cid", "cid-existing", "new", "follow up"]' "custom execution should skip conversation new when cid already exists"
    or return 1
end

test_custom_creates_conversation_once
or begin
    forge_test_cleanup
    exit 1
end

test_custom_reuses_existing_conversation
or begin
    forge_test_cleanup
    exit 1
end

forge_test_cleanup
printf 'test_custom_commands: ok\n'
