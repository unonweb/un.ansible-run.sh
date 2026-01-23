#!/bin/bash

ESC=$(printf "\e")
BOLD="${ESC}[1m"
RESET="${ESC}[0m"
SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
EXEC_PATH="${SCRIPT_DIR}/src/main.sh"

echo -e "Use ${BOLD}ctrl + c${RESET} to exit."
while true; do
	echo "---"
	source ${EXEC_PATH}
	if [[ ${?} -ne 0 ]]; then
		echo "Script returned error code ${?}"
		echo
		read -p "Press Enter to exit ..."
	fi
done