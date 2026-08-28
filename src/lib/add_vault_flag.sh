# NOTES
# -----
# Looks up a vault-id in the configured VAULT_MAP to get the decryption method

# REQUIRES
# --------
# - VAULT_MAP

# SETS
# ----
# - VAULT_FLAGS

function add_vault_flag {
	
    local vault_id="${1}"
    local method

    # Check if vault_id exists as a key in the associative array
    if [[ -n "${VAULT_MAP[${vault_id}]+x}" ]]; then
        method="${VAULT_MAP[${vault_id}]}"
    else
        # Default fallback
        method="prompt"
    fi

    # Return the formatted vault flag
	# echo "Adding vault flag: --vault-id=${vault_id}@${method}"
    VAULT_FLAGS+=("--vault-id=${vault_id}@${method}")
}