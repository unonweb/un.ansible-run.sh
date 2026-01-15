#!/bin/bash

# BOILERPLATE
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
SCRIPT_NAME=$(basename -- "$(readlink -f "${BASH_SOURCE}")")
SCRIPT_PARENT=$(dirname "${SCRIPT_DIR}")
ESC=$(printf "\e")
BOLD="${ESC}[1m"
RESET="${ESC}[0m"
CLEAR="\e[0m"
RED="${ESC}[31m"
GREEN="${ESC}[32m"
BLUE="${ESC}[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
UNDERLINE="${ESC}[4m"

# CONFIG & DEFAULTS
PATH_CONFIG="${SCRIPT_PARENT}/config.cfg"

if [[ -r ${PATH_CONFIG} ]]; then
	source "${PATH_CONFIG}"
else
	echo "<4>WARN: No config file found at ${PATH_CONFIG}. Using defaults ..."
	# DEFAULTS
	VAULT_ALL_CREDS_LOOKUP_PATH="/home/${USER}/.credentials/ansible/vault-all-lookup.sh"
	VAULT_HOST_CREDS_LOOKUP_PATH="/home/${USER}/.credentials/ansible/vault-host-lookup.sh"
	ANSIBLE_REPO_PATH="/media/nas/ansible_repository"
	#PATH_INVENTORY="${ANSIBLE_REPO_PATH}/inventory/inventory.yml"
	#PATH_CONFIG="${ANSIBLE_REPO_PATH}/ansible.cfg"
fi

function main() { # ${host} ${tags}

	local host=${1:-""}
	local tags=${2:-""}

	local vault_host_creds
	local vault_all_creds
	
	if [[ ! -d "${ANSIBLE_REPO_PATH}" ]]; then
		echo "Path not found: ${ANSIBLE_REPO_PATH}"
		echo "Save path to ansible repo in: ${PATH_CONFIG}. Exiting ..."
		exit 1
	fi

	if [[ -z "${host}" ]]; then
		echo -e "${CYAN}Enter host name${CLEAR}"
		read -p ">> " host
	fi

	if [[ -z "${tags}" ]]; then	
		echo -e "${CYAN}Enter tags${CLEAR} (separator: comma)"
		read -p ">> " tags
	fi

	# how shall ansible prompt for vault with id corresponding to host
	if [[ "${host}" = "$(hostname)" ]]; then
		if [[ -x "${VAULT_HOST_CREDS_LOOKUP_PATH}" ]]; then
			vault_host_creds="${VAULT_HOST_CREDS_LOOKUP_PATH}"
		else
			echo "Place a lookup script at ${VAULT_HOST_CREDS_LOOKUP_PATH} to avoid asking for your own vault key everytime."
		fi
	else
		vault_host_creds="prompt"
	fi
	
	# how shall ansible prompt for vault with id 'all'
	if [[ -f "${VAULT_ALL_CREDS_LOOKUP_PATH}" ]]; then
		vault_all_creds="${VAULT_ALL_CREDS_LOOKUP_PATH}"
	else
		vault_all_creds="prompt"
	fi

	# feedback
	echo
	echo -e "${CYAN}Running ansible on host "${host}" with tags: "${tags}"${CLEAR} ..."
	local CMD="ansible-playbook \
	--vault-id=all@${vault_all_creds} \
	--vault-id=${host}@${vault_host_creds} \
	--inventory=${ANSIBLE_REPO_PATH}/inventory/inventory.yml \
	--tags "${tags}" \
	${ANSIBLE_REPO_PATH}/playbooks/${host}.yml"

	echo ${CMD}
	
	# run
	ANSIBLE_HASH_BEHAVIOUR=merge ${CMD}

	#ANSIBLE_HASH_BEHAVIOUR=merge ansible-playbook \
	#--vault-id=all@${VAULT_ALL_CREDS_LOOKUP_PATH} \
	#--vault-id=${host}@${vault_host_creds} \
	#--inventory=${ANSIBLE_REPO_PATH}/inventory/inventory.yml \
	#--tags "${tags}" \
	#${ANSIBLE_REPO_PATH}/playbooks/${host}.yml
}

main "${1:-""}" "${2:-""}"