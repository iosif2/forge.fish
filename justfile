test:
    fish tests/test_commands.fish
    fish tests/test_custom_commands.fish
    fish tests/test_shell_integration.fish
    fish tests/test_sync.fish

test-interactive: test
    command -v script >/dev/null 2>&1
    script -qefc "fish tests/test_interactive_smoke.fish" /dev/null
