# Render cached Forge prompt status for the right prompt.
# The renderer lazily refreshes stale cache entries before printing.
# Usage: _forge_prompt_info

function _forge_prompt_info
    if functions -q __forge_status_prompt
        __forge_status_prompt
    end
end
