#!/usr/bin/env bash
set -e
ANSIBLE_DIR="$(readlink -f $(dirname ${BASH_SOURCE[0]}))"

export ANSIBLE_CONFIG="${ANSIBLE_DIR}/ansible.cfg"
export ANSIBLE_PRIVATE_KEY_FILE="$(cd ${ANSIBLE_DIR}/../terraform/ && terraform output ansible_sa_private_key_file)"
export ANSIBLE_REMOTE_USER="$(cd ${ANSIBLE_DIR}/../terraform/ && terraform output ansible_sa_username)"

ansible-galaxy install -r "${ANSIBLE_DIR}/requirements.yml"
#ansible-playbook -i "${ANSIBLE_DIR}/inventory" "${ANSIBLE_DIR}/provision.yml"