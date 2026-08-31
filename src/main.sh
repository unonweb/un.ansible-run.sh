#!/bin/bash

# REQUIRES
# --------
# - ANSIBLE_REPO_PATH

# RECOMMENDS
# ----------
# - VAULT_MAP
# - VAULT_DEFAULT_IDS

# BOILERPLATE
# -----------
export SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
export SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
export SCRIPT_NAME=$(basename -- "$(readlink -f "${BASH_SOURCE}")")
export SCRIPT_PARENT=$(dirname "${SCRIPT_DIR}")
export ESC=$(printf "\e")
export BOLD="${ESC}[1m"
export RESET="${ESC}[0m"
export CLEAR="\e[0m"
export RED="${ESC}[31m"
export GREEN="${ESC}[32m"
export BLUE="${ESC}[34m"
export MAGENTA="\e[35m"
export GREY="\033[38;5;248m"
export CYAN="\e[36m"
export UNDERLINE="${ESC}[4m"
export BLINKING="\033[5m"

# CONFIG & DEFAULTS
# -----------------
export PATH_CONFIG="${SCRIPT_PARENT}/config.cfg"
export PATH_DEFAULTS="${SCRIPT_DIR}/defaults.cfg"
export PATH_DATA="${SCRIPT_PARENT}/data"
export PATH_DATA_LAST_HOST="${PATH_DATA}/last_host"
export PATH_DATA_LAST_TAGS="${PATH_DATA}/last_tags"
export VERSION=2
export DEBUG=1
export LOG=0

if [[ -r ${PATH_CONFIG} ]]; then
	source "${PATH_CONFIG}"
else
	echo "<4>WARN: No config file found at ${PATH_CONFIG}. Using defaults ..."
	source "${PATH_DEFAULTS}"
fi

# IMPORTS
# -------
source ${SCRIPT_DIR}/lib/save_tag_list.sh
source ${SCRIPT_DIR}/lib/set_tags.sh
source ${SCRIPT_DIR}/lib/set_host.sh
source ${SCRIPT_DIR}/lib/set_playbook_path.sh
source ${SCRIPT_DIR}/lib/log.sh
source ${SCRIPT_DIR}/lib/debug.sh
source ${SCRIPT_DIR}/lib/set_inventory_path.sh
source ${SCRIPT_DIR}/lib/add_vault.sh
source ${SCRIPT_DIR}/lib/add_vault_flag.sh
source ${SCRIPT_DIR}/lib/get_possible_vaults.sh

function main {

	ANSIBLE_HOST=""
	ANSIBLE_TAGS=""
	ANSIBLE_EXEC_PATH=$(which ansible)
	ANSIBLE_PLAYBOOK_EXEC_PATH=$(which ansible-playbook)
	
	ANSIBLE_CONFIG_PATH="${ANSIBLE_REPO_PATH}/ansible.cfg"
	VAULT_FLAGS=()

	# PRINT version
	echo -ne "${GREY}"
	echo -e "Version: ${VERSION}"
	echo -ne "${CLEAR}"

	# CHECK exec path
	if [[ -z "${ANSIBLE_PLAYBOOK_EXEC_PATH}" ]]; then
		if [[ -f "/home/${USER}/.local/bin/ansible-playbook" ]]; then
			ANSIBLE_PLAYBOOK_EXEC_PATH="/home/${USER}/.local/bin/ansible-playbook"
		else
			echo "${MAGENTA}ansible-playbook executable not found. Tried:"
			echo "/home/${USER}/.local/bin/ansible-playbook${CLEAR}"
			exit 1
		fi
	fi
	
	# CHECK exec path
	if [[ -z "${ANSIBLE_EXEC_PATH}" ]]; then
		if [[ -f "/home/${USER}/.local/bin/ansible" ]]; then
			ANSIBLE_EXEC_PATH="/home/${USER}/.local/bin/ansible"
		else
			echo "${MAGENTA}ansible executable not found. Tried:"
			echo -e "/home/${USER}/.local/bin/ansible${CLEAR}"
			exit 1
		fi
	fi

	# MKDIR data
	if [[ ! -d "${PATH_DATA}" ]]; then
		mkdir "${PATH_DATA}"
	fi
	
	# CHECK repo path
	if [[ ! -d "${ANSIBLE_REPO_PATH}" ]]; then
		echo "ANSIBLE_REPO_PATH not found: ${ANSIBLE_REPO_PATH}"
		echo "Adjust config file at: ${PATH_CONFIG}. Exiting ..."
		exit 1
	fi

	# INIT inventory path
	set_inventory_path

	# INIT possible vaults
	get_possible_vaults

	# INIT host
	if [[ -f "${PATH_DATA_LAST_HOST}" ]]; then
		ANSIBLE_HOST=$(< "${PATH_DATA_LAST_HOST}")
	else
		set_host
	fi

	# INIT tags
	if [[ -f "${PATH_DATA_LAST_HOST}" ]]; then
		ANSIBLE_TAGS=$(< "${PATH_DATA_LAST_TAGS}")
	else
		set_tags
	fi

	# INIT playbook path
	set_playbook_path

	# INIT vault flags
	add_vault_flag "${ANSIBLE_HOST}"
	for id in ${VAULT_DEFAULT_IDS}; do
		add_vault_flag "${id}"
	done

	# Main Menu
	while true; do

		local options=(
			"Host"
			"Tags"
			"Vaults"
			"Run Ansible"
			"Run Ansible (verbose)"
			"Exit"
		)

		# SET cmd
		local cmd="${ANSIBLE_PLAYBOOK_EXEC_PATH}"
		cmd+=" --inventory=${ANSIBLE_INVENTORY_PATH}"
		cmd+=" --tags "${ANSIBLE_TAGS}" "
		cmd+="${VAULT_FLAGS[@]}"
		cmd+=" ${ANSIBLE_PLAYBOOK_PATH}"
		# SET env
		if [[ -f "${ANSIBLE_CONFIG_PATH}" ]]; then
			cmd="ANSIBLE_CONFIG='${ANSIBLE_CONFIG_PATH}' ${cmd}"
		else
			echo "Ansible config not found at ${ANSIBLE_CONFIG_PATH}"
		fi

		echo
		echo "-------------------------------"
		echo -e "Host:      ${GREEN}${ANSIBLE_HOST}${CLEAR}"
		echo -e "Playbook:  ${GREEN}${ANSIBLE_PLAYBOOK_PATH}${CLEAR}"
		echo -e "Inventory: ${GREEN}${ANSIBLE_INVENTORY_PATH}${CLEAR}"
		echo -e "Vaults:    ${GREEN}${VAULT_FLAGS[@]}${CLEAR}"
		echo -e "Tags:      ${GREEN}${ANSIBLE_TAGS}${CLEAR}"
		echo "-------------------------------"
		echo

		echo -e "${CYAN}Main Menu:${CLEAR}"
		PS3=">> "
		select opt in "${options[@]}"; do
			case "${opt}" in
			
				"Host")
					echo
					set_host
					set_playbook_path
					# reset vaults
					VAULT_FLAGS=()
					for id in ${VAULT_DEFAULT_IDS}; do
						add_vault_flag "${id}"
					done
					add_vault_flag "${ANSIBLE_HOST}"
					break
					;;

				"Tags")
					echo
					echo -e "${CYAN}Edit Tags:${CLEAR}"
					select opt in "Set" "Refresh List" "Return"; do
						case "${opt}" in
							"Set")
								set_tags
								break
								;;
							"Refresh List")
								save_tag_list
								break
								;;
							"Return")
								break
								;;
						esac
					done
					break
					;;
				"Vaults")
					echo
					echo -e "${CYAN}Edit Vaults:${CLEAR}"
					if [[ -n "${VAULT_FLAGS}" ]]; then echo -e "${GREY}${VAULT_FLAGS[@]}${CLEAR}"; fi
					select opt in "Add host vault" "Add group vault" "Reset vaults" "Return"; do
						case "${opt}" in
							"Add host vault")
								add_vault host
								break
								;;

							"Add group vault")
								add_vault group
								break
								;;
							
							"Reset vaults")
								VAULT_FLAGS=()
								break
								;;
								
							"Return")
								break
								;;
						esac
					done
					break
					;;

				"Run Ansible")
					# PRINT
					echo
					echo -e "${CYAN}Running ansible on host "${ANSIBLE_HOST}" with tags${CLEAR}: ${BOLD}${ANSIBLE_TAGS}${CLEAR} ..."
					echo -en "${GREY}"
					echo "${cmd}"
					echo
					echo -en "${CLEAR}"
					
					# RUN cmd
					eval "${cmd}"
					
					if [[ ${?} -ne 0 ]]; then
						echo -e "${MAGENTA}Script returned error code: ${exit_code}${RESET}"
						echo
					fi
					
					break
					;;
				
				"Run Ansible (verbose)")
					eval "${cmd} -v"
					break
					;;
				
				"Run Ansible (very verbose)")
					eval "${cmd} -vv"
					break
					;;
				
				"Exit")
					exit 0
					;;
				
				*)
					echo "Bad option: ${REPLY}"
					break
					;;

			esac
		done
	done
}

main