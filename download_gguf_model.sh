#!/usr/bin/env bash
#
# Download script for GGUF models for AIDungeon
# Supports downloading from Hugging Face
#

set -e
cd "$(dirname "${0}")"
BASE_DIR="$(pwd)"

MODELS_DIRECTORY="generator/gguf/models"

# Default model: A smaller, story-focused model suitable for the RTX 5060 Ti 16GB
# You can change these to use a different model from Hugging Face
DEFAULT_REPO="TheBloke/Mistral-7B-Instruct-v0.1-GGUF"
DEFAULT_MODEL="mistral-7b-instruct-v0.1.Q4_K_M.gguf"

# Alternative recommended models for storytelling:
# TheBloke/Llama-2-7B-Chat-GGUF - llama-2-7b-chat.Q4_K_M.gguf
# TheBloke/Llama-2-13B-Chat-GGUF - llama-2-13b-chat.Q4_K_M.gguf (requires more VRAM)
# TheBloke/Nous-Hermes-2-Mistral-7B-DPO-GGUF - nous-hermes-2-mistral-7b-dpo.Q4_K_M.gguf

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Download GGUF models for AIDungeon local inference."
    echo ""
    echo "Options:"
    echo "  -r, --repo REPO     Hugging Face repository (default: $DEFAULT_REPO)"
    echo "  -m, --model FILE    Model filename (default: $DEFAULT_MODEL)"
    echo "  -d, --dir DIR       Download directory (default: $MODELS_DIRECTORY)"
    echo "  -l, --list          List some recommended models"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Example:"
    echo "  $0  # Downloads the default model"
    echo "  $0 -r TheBloke/Llama-2-7B-Chat-GGUF -m llama-2-7b-chat.Q4_K_M.gguf"
}

list_models() {
    echo "Recommended GGUF models for AIDungeon:"
    echo ""
    echo "For 16GB VRAM (RTX 5060 Ti 16GB):"
    echo "  7B models (fastest, ~4-6GB VRAM with Q4 quantization):"
    echo "    - TheBloke/Mistral-7B-Instruct-v0.1-GGUF (mistral-7b-instruct-v0.1.Q4_K_M.gguf)"
    echo "    - TheBloke/Llama-2-7B-Chat-GGUF (llama-2-7b-chat.Q4_K_M.gguf)"
    echo "    - TheBloke/Nous-Hermes-2-Mistral-7B-DPO-GGUF (nous-hermes-2-mistral-7b-dpo.Q4_K_M.gguf)"
    echo ""
    echo "  13B models (better quality, ~8-10GB VRAM with Q4 quantization):"
    echo "    - TheBloke/Llama-2-13B-Chat-GGUF (llama-2-13b-chat.Q4_K_M.gguf)"
    echo ""
    echo "Quantization levels:"
    echo "  Q4_K_M - Good balance of quality and speed (recommended)"
    echo "  Q5_K_M - Better quality, slightly slower"
    echo "  Q6_K   - Higher quality, needs more VRAM"
    echo "  Q8_0   - Highest quality, needs most VRAM"
    echo ""
    echo "Download from Hugging Face: https://huggingface.co/TheBloke"
}

REPO="$DEFAULT_REPO"
MODEL="$DEFAULT_MODEL"
DOWNLOAD_DIR="$MODELS_DIRECTORY"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--repo)
            REPO="$2"
            shift 2
            ;;
        -m|--model)
            MODEL="$2"
            shift 2
            ;;
        -d|--dir)
            DOWNLOAD_DIR="$2"
            shift 2
            ;;
        -l|--list)
            list_models
            exit 0
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

MODEL_PATH="${DOWNLOAD_DIR}/${MODEL}"
HF_URL="https://huggingface.co/${REPO}/resolve/main/${MODEL}"

echo "============================================="
echo "AIDungeon GGUF Model Downloader"
echo "============================================="
echo ""
echo "Repository: ${REPO}"
echo "Model: ${MODEL}"
echo "Download path: ${MODEL_PATH}"
echo ""

# Create models directory
mkdir -p "${DOWNLOAD_DIR}"

# Check if model already exists
if [[ -f "${MODEL_PATH}" ]]; then
    echo "Model already exists at ${MODEL_PATH}"
    echo "Would you like to redownload? [y/N]"
    read -r ANSWER
    ANSWER=$(echo "$ANSWER" | tr '[:upper:]' '[:lower:]')
    case $ANSWER in
        [yY][eE][sS]|[yY])
            echo "Removing existing model..."
            rm -f "${MODEL_PATH}"
            ;;
        *)
            echo "Keeping existing model. Exiting."
            exit 0
            ;;
    esac
fi

echo "Downloading model from Hugging Face..."
echo "This may take a while depending on your connection speed."
echo ""

# Check for available download tools
if command -v wget > /dev/null; then
    wget -c --show-progress -O "${MODEL_PATH}" "${HF_URL}"
elif command -v curl > /dev/null; then
    curl -L -C - -o "${MODEL_PATH}" "${HF_URL}"
else
    echo "Error: Neither wget nor curl is available."
    echo "Please install one of them and try again."
    exit 1
fi

if [[ -f "${MODEL_PATH}" ]]; then
    FILE_SIZE=$(du -h "${MODEL_PATH}" | cut -f1)
    echo ""
    echo "============================================="
    echo "Download complete!"
    echo "Model: ${MODEL_PATH}"
    echo "Size: ${FILE_SIZE}"
    echo "============================================="
    echo ""
    echo "You can now run AIDungeon with the GGUF generator:"
    echo "  ./play.py --gguf"
else
    echo "Error: Download failed. Please try again."
    exit 1
fi
