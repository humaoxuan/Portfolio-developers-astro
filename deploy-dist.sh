#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [-h host] [-u user] [-p remote_path] [-b] [-n]

Options:
  -h host         Remote host (default: oa.maoxuan.name)
  -u user         Remote SSH user (default: current user)
  -p remote_path  Remote target path (default: /home/ubuntu/oa/profilio/dist)
  -b              Run 'pnpm build' before deploying
  -n              No remote backup (don't rename existing remote dir)

Example:
  ./deploy-dist.sh -b
  ./deploy-dist.sh -h oa.maoxuan.name -u deploy -p /home/ubuntu/oa/profilio/dist
EOF
}

HOST="oa.maoxuan.name"
USER="ubuntu"
REMOTE_PATH="/home/ubuntu/oa/aaron/profilio/dist"
DO_BUILD=0
NO_BACKUP=0

while getopts "h:u:p:bn" opt; do
  case "$opt" in
    h) HOST="$OPTARG" ;; 
    u) USER="$OPTARG" ;; 
    p) REMOTE_PATH="$OPTARG" ;; 
    b) DO_BUILD=1 ;; 
    n) NO_BACKUP=1 ;; 
    *) usage; exit 1 ;; 
  esac
done

if [ "$DO_BUILD" -eq 1 ]; then
  if command -v pnpm >/dev/null 2>&1; then
    echo "Running pnpm build..."
    pnpm build
  else
    echo "pnpm not found in PATH. Install pnpm or run build manually." >&2
    exit 1
  fi
fi

if [ ! -d "dist" ]; then
  echo "dist/ not found. Run build first or use -b to build." >&2
  exit 1
fi

SSH_CMD="ssh ${USER}@${HOST}"

if [ "$NO_BACKUP" -eq 0 ]; then
  TIMESTAMP=$(date +%Y%m%d%H%M%S)
  echo "Backing up remote directory (if exists) to ${REMOTE_PATH}.bak.${TIMESTAMP}"
  ${SSH_CMD} "if [ -d '${REMOTE_PATH}' ]; then mv '${REMOTE_PATH}' '${REMOTE_PATH}.bak.${TIMESTAMP}'; fi; mkdir -p '${REMOTE_PATH}'"
else
  echo "Ensuring remote path exists: ${REMOTE_PATH}"
  ${SSH_CMD} "mkdir -p '${REMOTE_PATH}'"
fi

echo "Syncing dist/ -> ${USER}@${HOST}:${REMOTE_PATH}"
rsync -avz --delete dist/ ${USER}@${HOST}:${REMOTE_PATH}/

echo "Deployment complete: ${USER}@${HOST}:${REMOTE_PATH}"
