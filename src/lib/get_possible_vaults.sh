# REQUIRES
# --------
# - ANSIBLE_REPO_PATH

# SETS
# ----
# - HOST_VAR_DIRS
# - GROUP_VAR_DIRS

function get_possible_vaults {

	# GET host var dirs
	HOST_VAR_DIRS=()
	mapfile -t host_vars_found < <(find "${ANSIBLE_REPO_PATH}" -maxdepth 2 -type d -name "host_vars")
	if [[ ${#host_vars_found[@]} -eq 1 ]]; then
		for dir in "${host_vars_found[0]}"/*; do
			if [ -d "${dir}" ]; then
				local dir_name=$(basename "${dir}")
				HOST_VAR_DIRS+=("${dir_name}")
			fi
		done
	else
		echo "No 'host_vars' directory found at ${ANSIBLE_REPO_PATH}"
	fi

	# GET group var dirs
	GROUP_VAR_DIRS=()
	mapfile -t group_vars_found < <(find "${ANSIBLE_REPO_PATH}" -maxdepth 2 -type d -name "group_vars")
	if [[ ${#group_vars_found[@]} -eq 1 ]]; then
		for dir in "${group_vars_found[0]}"/*; do
			if [ -d "${dir}" ]; then
				local dir_name=$(basename "${dir}")
				GROUP_VAR_DIRS+=("${dir_name}")
			fi
		done
	else
		echo "No 'group_vars' directory found at ${ANSIBLE_REPO_PATH}"
	fi

	if [[ ${#HOST_VAR_DIRS[@]} -gt 0 && ${#GROUP_VAR_DIRS[@]} -gt 0 ]]; then
		# echo "Found ${#HOST_VAR_DIRS[@]} host_var directories"
		# echo "Found ${#GROUP_VAR_DIRS[@]} group_var directories"
		return 0
	else
		echo "Could not find any host_var or group_var directories"
		return 1
	fi
}