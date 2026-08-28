# REQUIRES
# --------
# - ANSIBLE_REPO_PATH

# SETS
# ----
# - ANSIBLE_INVENTORY_PATH

function set_inventory_path {
	# SET inventory path
	if [[ -f "${ANSIBLE_REPO_PATH}/inventory/inventory.yml" ]]; then
		ANSIBLE_INVENTORY_PATH="${ANSIBLE_REPO_PATH}/inventory/inventory.yml"
	else
		echo "ERROR: Path to inventory not found. Tried:"
		echo "${ANSIBLE_REPO_PATH}/inventory/inventory.yml"
		exit 1
	fi
}