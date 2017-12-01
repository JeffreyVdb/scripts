#!/bin/bash
set -o errexit
set -o noclobber

BORG='/usr/bin/borg'

function initialize_borg_repo() {
    local REPO_PATH="$1"
    if ! mkdir "$REPO_PATH"; then
        return 1
    fi

    borg init --encryption=repokey "$REPO_PATH"
    echo "initialized borg repository at ${REPO_PATH}"
}

# User executing command
if [[ -n "$SUDO_USER" ]]; then
    BACKUP_USER="$SUDO_USER"
else
    BACKUP_USER="$USER"
fi

REPOSITORY_BASE="${BACKUP_BORG_REPO_PATH:-/media/${USER}/data/backup/borg}"

# Check if we need to create a repository for this hostname
HOSTNAME=$(hostname)
BACKUP_NAME="${BACKUP_BORG_NAME:-$HOSTNAME}"
REPOSITORY_PATH="${REPOSITORY_BASE}/${BACKUP_NAME}"
if [[ ! -d "${REPOSITORY_PATH}" ]]; then
    if ! initialize_borg_repo "${REPOSITORY_PATH}"; then
        echo "Could not initialize repository" >&2
        exit 1
    fi
fi

${BORG} create $REPOSITORY_PATH::'{hostname}-{now:%Y-%m-%d_%H%M}' "$@"

# Delete older backups
${BORG} prune -v --list $REPOSITORY_PATH --prefix '{hostname}-' \
    --keep-daily=7 --keep-weekly=4 --keep-monthly=6
