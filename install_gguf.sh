#!/usr/bin/env bash
#
# Installation script for AIDungeon with GGUF support
# Supports modern Python versions and CUDA for RTX 50xx series GPUs
#

set -e
cd "$(dirname "${0}")"
BASE_DIR="$(pwd)"
PACKAGES=(aria2 git unzip wget cmake build-essential)

# Python version requirements for GGUF mode
# llama-cpp-python supports Python 3.8+
MIN_PYTHON_VERS="3.8.0"
MAX_PYTHON_VERS="3.12.99"

# Legacy mode uses TensorFlow 1.15 which requires Python 3.5-3.7
LEGACY_MIN_PYTHON_VERS="3.4.0"
LEGACY_MAX_PYTHON_VERS="3.7.9"

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Install AIDungeon with either legacy TensorFlow or modern GGUF support."
    echo ""
    echo "Options:"
    echo "  --gguf     Install with GGUF support (requires Python 3.8+, supports RTX 50xx)"
    echo "  --legacy   Install with original TensorFlow 1.15 (requires Python 3.4-3.7)"
    echo "  --cuda     Enable CUDA support for GGUF mode (requires NVIDIA GPU + CUDA toolkit)"
    echo "  --help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --gguf --cuda   # Install GGUF mode with GPU acceleration (recommended)"
    echo "  $0 --gguf          # Install GGUF mode with CPU only"
    echo "  $0 --legacy        # Install original TensorFlow mode"
}

version_compare() {
    # Returns 0 if $1 >= $2, 1 otherwise
    printf '%s\n%s' "$2" "$1" | sort -V -C
}

version_check_gguf() {
    PYTHON_VER=$(python3 --version | cut -d' ' -f2)
    if ! version_compare "$PYTHON_VER" "$MIN_PYTHON_VERS"; then
        echo "Your installed Python version ($PYTHON_VER) is too old."
        echo "GGUF mode requires at least Python $MIN_PYTHON_VERS."
        exit 1
    fi
    if version_compare "$PYTHON_VER" "$MAX_PYTHON_VERS" && [ "$PYTHON_VER" != "$MAX_PYTHON_VERS" ]; then
        :  # Version is fine
    fi
    echo "Python version $PYTHON_VER is compatible with GGUF mode."
}

version_check_legacy() {
    PYTHON_VER=$(python3 --version | cut -d' ' -f2)
    MAX_VERS=$(echo -e "${PYTHON_VER}\n${LEGACY_MAX_PYTHON_VERS}\n${LEGACY_MIN_PYTHON_VERS}" | sort -V | tail -n1)
    MIN_VERS=$(echo -e "${PYTHON_VER}\n${LEGACY_MAX_PYTHON_VERS}\n${LEGACY_MIN_PYTHON_VERS}" | sort -V | head -n1)
    if [ "$MIN_VERS" != "$LEGACY_MIN_PYTHON_VERS" ]; then
        echo "Your installed Python version ($PYTHON_VER) is too old for legacy mode."
        echo "Please update to at least $LEGACY_MIN_PYTHON_VERS."
        exit 1
    elif [ "$MAX_VERS" != "$LEGACY_MAX_PYTHON_VERS" ]; then
        echo "Your installed Python version ($PYTHON_VER) is too new for legacy mode."
        echo "Legacy mode requires Python $LEGACY_MIN_PYTHON_VERS - $LEGACY_MAX_PYTHON_VERS."
        echo "Consider using --gguf mode instead, which supports modern Python."
        exit 1
    fi
}

pip_install_gguf() {
    if [ ! -d "./venv" ]; then
        if is_command 'apt-get'; then
            apt-get install -y python3-venv || true
        fi
        python3 -m venv ./venv
    fi
    source "${BASE_DIR}/venv/bin/activate"
    pip install --upgrade pip setuptools wheel
    
    if [ "$CUDA_ENABLED" = true ]; then
        echo ""
        echo "Installing llama-cpp-python with CUDA support..."
        echo "This may take several minutes to compile."
        echo ""
        CMAKE_ARGS="-DGGML_CUDA=on" pip install llama-cpp-python --force-reinstall --upgrade --no-cache-dir
    fi
    
    pip install -r "${BASE_DIR}/requirements_gguf.txt"
}

pip_install_legacy() {
    if [ ! -d "./venv" ]; then
        if is_command 'apt-get'; then
            apt-get install python3-venv || true
        fi
        python3 -m venv ./venv
    fi
    source "${BASE_DIR}/venv/bin/activate"
    pip install --upgrade pip setuptools
    pip install -r "${BASE_DIR}/requirements.txt"
}

is_command() {
    command -v "${@}" > /dev/null
}

system_package_install() {
    SUDO=''
    if (( $EUID != 0 )); then
        SUDO='sudo'
    fi
    
    if is_command 'apt-get'; then
        $SUDO apt-get update
        $SUDO apt-get install -y ${PACKAGES[@]}
    elif is_command 'brew'; then
        brew install ${PACKAGES[@]}
    elif is_command 'yum'; then
        $SUDO yum install -y ${PACKAGES[@]}
    elif is_command 'dnf'; then
        $SUDO dnf install -y ${PACKAGES[@]}
    elif is_command 'pacman'; then
        $SUDO pacman -S --noconfirm ${PACKAGES[@]}
    elif is_command 'apk'; then
        $SUDO apk --update add ${PACKAGES[@]}
    else
        echo "You do not seem to be using a supported package manager."
        echo "Please make sure ${PACKAGES[@]} are installed, then press [ENTER]"
        read NOT_USED
    fi
}

check_cuda() {
    if is_command 'nvidia-smi'; then
        echo ""
        echo "NVIDIA GPU detected:"
        nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
        echo ""
        
        if is_command 'nvcc'; then
            CUDA_VER=$(nvcc --version | grep "release" | sed 's/.*release //' | cut -d',' -f1)
            echo "CUDA toolkit version: $CUDA_VER"
            return 0
        else
            echo "WARNING: CUDA toolkit (nvcc) not found."
            echo "For GPU acceleration, please install CUDA toolkit."
            echo "Visit: https://developer.nvidia.com/cuda-downloads"
            return 1
        fi
    else
        echo "No NVIDIA GPU detected or nvidia-smi not available."
        return 1
    fi
}

install_gguf() {
    echo "============================================="
    echo "Installing AIDungeon with GGUF Support"
    echo "============================================="
    echo ""
    
    version_check_gguf
    
    if [ "$CUDA_ENABLED" = true ]; then
        echo ""
        echo "Checking CUDA setup..."
        if ! check_cuda; then
            echo ""
            echo "WARNING: CUDA not properly configured."
            echo "Continuing with CPU-only installation."
            echo "For GPU support, install CUDA toolkit and re-run with --cuda"
            echo ""
            CUDA_ENABLED=false
        fi
    fi
    
    system_package_install
    pip_install_gguf
    
    echo ""
    echo "============================================="
    echo "Installation complete!"
    echo "============================================="
    echo ""
    echo "Next steps:"
    echo "  1. Download a GGUF model: ./download_gguf_model.sh"
    echo "  2. Activate the virtual environment: source ./venv/bin/activate"
    echo "  3. Run the game: ./play.py --gguf"
    echo ""
}

install_legacy() {
    echo "============================================="
    echo "Installing AIDungeon (Legacy TensorFlow Mode)"
    echo "============================================="
    echo ""
    
    version_check_legacy
    system_package_install
    pip_install_legacy
    
    echo ""
    echo "============================================="
    echo "Installation complete!"
    echo "============================================="
    echo ""
    echo "Next steps:"
    echo "  1. Download the model: ./download_model.sh"
    echo "  2. Activate the virtual environment: source ./venv/bin/activate"
    echo "  3. Run the game: ./play.py"
    echo ""
}

# Parse arguments
INSTALL_MODE=""
CUDA_ENABLED=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --gguf)
            INSTALL_MODE="gguf"
            shift
            ;;
        --legacy)
            INSTALL_MODE="legacy"
            shift
            ;;
        --cuda)
            CUDA_ENABLED=true
            shift
            ;;
        --help|-h)
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

# If no mode specified, show selection menu
if [ -z "$INSTALL_MODE" ]; then
    echo "============================================="
    echo "AIDungeon Installation"
    echo "============================================="
    echo ""
    echo "Please select installation mode:"
    echo ""
    echo "  1) GGUF Mode (Recommended)"
    echo "     - Supports modern NVIDIA GPUs (RTX 50xx, 40xx, 30xx)"
    echo "     - Uses local GGUF format models"
    echo "     - Requires Python 3.8+"
    echo ""
    echo "  2) Legacy Mode"
    echo "     - Uses original TensorFlow 1.15"
    echo "     - Requires Python 3.4-3.7"
    echo "     - Uses original GPT-2 model"
    echo ""
    read -p "Enter choice [1/2]: " CHOICE
    
    case $CHOICE in
        1)
            INSTALL_MODE="gguf"
            read -p "Enable CUDA/GPU support? [Y/n]: " CUDA_CHOICE
            case $CUDA_CHOICE in
                [nN][oO]|[nN])
                    CUDA_ENABLED=false
                    ;;
                *)
                    CUDA_ENABLED=true
                    ;;
            esac
            ;;
        2)
            INSTALL_MODE="legacy"
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

# Run installation
case $INSTALL_MODE in
    gguf)
        install_gguf
        ;;
    legacy)
        install_legacy
        ;;
    *)
        echo "Unknown installation mode: $INSTALL_MODE"
        exit 1
        ;;
esac
