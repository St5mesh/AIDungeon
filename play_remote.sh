#!/usr/bin/env bash
# Remote play script for AIDungeon 2
# This script is designed to be invoked over SSH for remote gameplay.
#
# USAGE:
#   1. On the server (host machine), ensure AIDungeon is installed and working locally.
#   2. From a remote client, connect using SSH:
#      ssh user@server-ip "/path/to/AIDungeon/play_remote.sh"
#
#   Or, to set up as a dedicated game server, add to authorized_keys:
#      command="/path/to/AIDungeon/play_remote.sh" ssh-rsa AAAAB3... user@client
#
# OPTIONS:
#   --cpu           Force CPU-only mode
#   --gguf          Use GGUF model format (recommended for modern GPUs)
#   --model PATH    Path to GGUF model file
#   --gpu-layers N  Number of layers to offload to GPU (-1 = all)
#   --ctx-size N    Context window size for GGUF models (default: 2048)
#
# EXAMPLES:
#   ssh user@server ./AIDungeon/play_remote.sh
#   ssh user@server ./AIDungeon/play_remote.sh --gguf
#   ssh user@server ./AIDungeon/play_remote.sh --gguf --cpu

set -e

# Change to the directory where the script is located
cd "$(dirname "${0}")"
BASE_DIR="$(pwd)"

# Function to display error and exit
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Check if we have a terminal (required for interactive gameplay)
if [ ! -t 0 ]; then
    error_exit "This script requires an interactive terminal. Use: ssh -t user@host '$0'"
fi

# Activate virtual environment if it exists
if [ -d "${BASE_DIR}/venv" ]; then
    source "${BASE_DIR}/venv/bin/activate"
fi

# Check if play.py exists
if [ ! -f "${BASE_DIR}/play.py" ]; then
    error_exit "play.py not found in ${BASE_DIR}. Please ensure AIDungeon is properly installed."
fi

# Display connection info
echo "========================================"
echo "  AIDungeon 2 - Remote Play Session"
echo "========================================"
echo "Connected from: ${SSH_CLIENT:-local}"
echo ""

# Pass all arguments to play.py
exec python3 "${BASE_DIR}/play.py" "$@"
