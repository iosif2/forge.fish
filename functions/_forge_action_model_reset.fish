# Compatibility wrapper: Zsh routes :model-reset through config reload.
# Keep this helper as an alias for any direct callers.
# Usage: _forge_action_model_reset

function _forge_action_model_reset
    _forge_action_config_reload
end

