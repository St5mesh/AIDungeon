# AIDungeon2

Read more about AIDungeon2 and how it was built [here](https://pcc.cs.byu.edu/2019/11/21/ai-dungeon-2-creating-infinitely-generated-text-adventures-with-deep-learning-language-models/).

Play the mobile app version of the game by following the links [here](https://aidungeon.io)

Play the game online by following this link [here](https://play.aidungeon.io)

Play the game in Colab [here](https://colab.research.google.com/github/AIDungeon/AIDungeon/blob/master/AIDungeon_2.ipynb).

## Local Installation

### GGUF Mode (Recommended for Modern GPUs)

GGUF mode uses local LLM models in GGUF format via [llama-cpp-python](https://github.com/abetlen/llama-cpp-python). This is the recommended approach for modern NVIDIA GPUs including the RTX 50xx, 40xx, and 30xx series.

**Requirements:**
- Python 3.8 or higher
- NVIDIA GPU with 12GB+ VRAM (e.g., RTX 5060 Ti 16GB)
- CUDA toolkit installed (for GPU acceleration)

**Installation:**
```bash
git clone https://github.com/AIDungeon/AIDungeon/
cd AIDungeon

# Install with CUDA/GPU support (recommended)
./install_gguf.sh --gguf --cuda

# Download a GGUF model (Mistral 7B by default)
./download_gguf_model.sh

# Activate virtual environment and play
source ./venv/bin/activate
./play.py --gguf
```

**Command line options for GGUF mode:**
```bash
./play.py --gguf                          # Use GGUF mode with default settings
./play.py --gguf --cpu                    # Force CPU-only inference
./play.py --gguf --model path/to/model.gguf  # Use a specific model file
./play.py --gguf --gpu-layers 20          # Offload only 20 layers to GPU
./play.py --gguf --ctx-size 4096          # Larger context window
```

**Downloading different models:**
```bash
# List recommended models
./download_gguf_model.sh --list

# Download a specific model from Hugging Face
./download_gguf_model.sh -r TheBloke/Llama-2-13B-Chat-GGUF -m llama-2-13b-chat.Q4_K_M.gguf
```

### Legacy Mode (TensorFlow 1.15)

The original implementation using TensorFlow 1.15 and GPT-2. Requires Python 3.4-3.7.

```bash
git clone --branch master https://github.com/AIDungeon/AIDungeon/
cd AIDungeon
./install.sh # Installs system packages and creates python3 virtual environment
./download_model.sh
source ./venv/bin/activate
./play.py
```

## Remote Play (via SSH)

You can play AIDungeon from another computer on your network by connecting via SSH to a machine that has AIDungeon installed.

**Basic usage:**
```bash
# Connect from a remote machine and play
ssh -t user@server-ip "/path/to/AIDungeon/play_remote.sh"

# With GGUF mode
ssh -t user@server-ip "/path/to/AIDungeon/play_remote.sh --gguf"

# Force CPU-only mode
ssh -t user@server-ip "/path/to/AIDungeon/play_remote.sh --cpu"
```

**Note:** The `-t` flag is required to allocate a TTY for the interactive game session.

**Setting up a dedicated game server:**

You can configure SSH to automatically launch AIDungeon when a user connects with a specific SSH key. Add the following to your `~/.ssh/authorized_keys` on the server:

```
command="/path/to/AIDungeon/play_remote.sh --gguf" ssh-rsa AAAAB3... user@client
```

This restricts that SSH key to only running the game, which is useful for setting up a dedicated game machine.

**Options:**
The `play_remote.sh` script accepts all the same options as `play.py`:
- `--cpu` - Force CPU-only mode
- `--gguf` - Use GGUF model format
- `--model PATH` - Path to GGUF model file
- `--gpu-layers N` - Number of layers to offload to GPU
- `--ctx-size N` - Context window size for GGUF models

## Finetune the model yourself

Formatting the data. After scraping the data I formatted text adventures into a json dict structure that looked like the following:
```
{   
    "tree_id": <someid>
    "story_start": <start text of the story>
    "action_results": [
    {"action":<action1>, "result":<result1>, "action_results": <A Dict that looks like above action results>},
    {"action":<action2>, "result":<result2>, "action_results": <A Dict that looks like above action results>}]
}
```
Essentially it's a tree that captures all the action result nodes. 
Then I used [this](https://github.com/AIDungeon/AIDungeon/blob/develop/data/build_training_data.py) to transform that data into one giant txt file. The txt file looks something like:
```
<|startoftext|>
You are a survivor living in some place...
> You search for food
You search for food but are unable to find any
> Do another thing
You do another thing...
<|endoftext|>
(above repeated many times)
```

Then once you have that you can use the [finetuning script](https://github.com/AIDungeon/AIDungeon/blob/develop/generator/simple/finetune.py) to fine tune the model provided you have the hardware.

Fine tuning the largest GPT-2 model is difficult due to the immense hardware required. I no longer have access to the same hardware so there are two ways I would suggest doing it. I originally fine tuned the model on 8 32GB V100 GPUs (an Nvidia DGX1). This allowed me to use a batch size of 32 which I found to be helpful in improving quality. The only cloud resource I could find that matches those specs is an aws p3dn.24xlarge instance so you'd want to spin that up on EC2 and fine tune it there. (might have to also request higher limits). Another way you could do it is to use a sagemaker notebook (similar to a colab notebook) and select the p3.24xlarge instance type. This is equivalent to 8 16 GB V100 GPUs. Because each GPU has only 16GB memory you probably need to reduce the batch size to around 8.


Community
------------------------

AIDungeon is an open source project. Questions, discussion, and
contributions are welcome. Contributions can be anything from new
packages to bugfixes, documentation, or even new core features.

Resources:

* **Website**: [aidungeon.io](http://www.aidungeon.io/)
* **Email**: aidungeon.io@gmail.com
* **Twitter**: [creator @nickwalton00](https://twitter.com/nickwalton00), [dev @benjbay](https://twitter.com/benjbay)
* **Reddit**: [r/AIDungeon](https://www.reddit.com/r/AIDungeon/)
* **Discord**: [aidungeon discord](https://discord.gg/Dg8Vcz6)


Contributing
------------------------
Contributing to AIDungeon is easy! Just send us a
[pull request](https://help.github.com/articles/using-pull-requests/)
from your fork. Before you send it, summarize your change in the
[Unreleased] section of [the CHANGELOG](CHANGELOG.md) and make sure
``develop`` is the destination branch.

AIDungeon uses a rough approximation of the
[Git Flow](http://nvie.com/posts/a-successful-git-branching-model/)
branching model.  The ``develop`` branch contains the latest
contributions, and ``master`` is always tagged and points to the latest
stable release.

If you're a contributor, make sure you're testing and playing on `develop`.
That's where all the magic is happening (and where we hope bugs stop).
