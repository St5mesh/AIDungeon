"""
GGUF-based generator for AIDungeon using llama-cpp-python.

This module provides local LLM inference using GGUF format models
with CUDA support for modern NVIDIA GPUs including RTX 50xx series.
"""

import os
import warnings

from story.utils import cut_trailing_sentence, remove_profanity

warnings.filterwarnings("ignore")


class GGUFGenerator:
    """
    Generator class for running local LLM models in GGUF format.
    
    Uses llama-cpp-python with CUDA support for GPU acceleration.
    Optimized for NVIDIA GPUs with 12GB+ VRAM (e.g., RTX 5060 Ti 16GB).
    """
    
    def __init__(
        self,
        model_path=None,
        generate_num=60,
        temperature=0.7,
        top_k=40,
        top_p=0.9,
        censor=True,
        force_cpu=False,
        n_gpu_layers=-1,
        n_ctx=2048,
        n_batch=512
    ):
        """
        Initialize the GGUF generator.
        
        Args:
            model_path: Path to the GGUF model file. If None, uses default location.
            generate_num: Maximum number of tokens to generate per response.
            temperature: Sampling temperature (0.0-2.0). Higher = more creative.
            top_k: Top-k sampling parameter.
            top_p: Top-p (nucleus) sampling parameter.
            censor: Whether to filter profanity from outputs.
            force_cpu: Force CPU-only inference (no GPU).
            n_gpu_layers: Number of layers to offload to GPU. -1 = all layers.
            n_ctx: Context window size (max tokens model can see at once).
            n_batch: Batch size for prompt processing.
        """
        try:
            from llama_cpp import Llama
        except ImportError:
            raise ImportError(
                "llama-cpp-python is not installed. Please install it with CUDA support:\n"
                "CMAKE_ARGS=\"-DGGML_CUDA=on\" pip install llama-cpp-python --force-reinstall --upgrade --no-cache-dir"
            )
        
        self.generate_num = generate_num
        self.temp = temperature
        self.top_k = top_k
        self.top_p = top_p
        self.censor = censor
        
        # Default model path
        if model_path is None:
            model_dir = "generator/gguf/models"
            # Look for any .gguf file in the models directory
            if os.path.exists(model_dir):
                gguf_files = [f for f in os.listdir(model_dir) if f.endswith('.gguf')]
                if gguf_files:
                    model_path = os.path.join(model_dir, gguf_files[0])
                else:
                    raise FileNotFoundError(
                        f"No GGUF model files found in {model_dir}. "
                        "Please download a model using download_gguf_model.sh"
                    )
            else:
                raise FileNotFoundError(
                    f"Model directory {model_dir} not found. "
                    "Please run download_gguf_model.sh to download a model."
                )
        
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file not found: {model_path}")
        
        self.model_path = model_path
        
        # Configure GPU layers
        if force_cpu:
            n_gpu_layers = 0
        
        print(f"Loading GGUF model from: {model_path}")
        print(f"GPU layers: {n_gpu_layers if n_gpu_layers >= 0 else 'all'}")
        print(f"Context size: {n_ctx}")
        
        # Initialize the Llama model
        self.llm = Llama(
            model_path=model_path,
            n_gpu_layers=n_gpu_layers,
            n_ctx=n_ctx,
            n_batch=n_batch,
            verbose=False
        )
        
        print("GGUF model loaded successfully!")
    
    def prompt_replace(self, prompt):
        """Clean up the prompt before sending to the model."""
        if len(prompt) > 0 and prompt[-1] == " ":
            prompt = prompt[:-1]
        return prompt
    
    def result_replace(self, result):
        """Clean up the generated result."""
        result = cut_trailing_sentence(result)
        if len(result) == 0:
            return ""
        
        first_letter_capitalized = result[0].isupper()
        result = result.replace('."', '".')
        result = result.replace("#", "")
        result = result.replace("*", "")
        result = result.replace("\n\n", "\n")
        
        if self.censor:
            result = remove_profanity(result)
        
        if not first_letter_capitalized:
            result = result[0].lower() + result[1:]
        
        return result
    
    def generate_raw(self, prompt):
        """Generate raw text from the model."""
        output = self.llm(
            prompt,
            max_tokens=self.generate_num,
            temperature=self.temp,
            top_k=self.top_k,
            top_p=self.top_p,
            stop=["<|endoftext|>", "\n>", "\n\n\n"],
            echo=False
        )
        
        if output and "choices" in output and len(output["choices"]) > 0:
            return output["choices"][0]["text"]
        return ""
    
    def generate(self, prompt, options=None, seed=1):
        """
        Generate a response based on the prompt.
        
        Args:
            prompt: The input prompt/context.
            options: Optional generation parameters (unused, for API compatibility).
            seed: Random seed (unused, for API compatibility).
            
        Returns:
            Generated text response.
        """
        debug_print = False
        prompt = self.prompt_replace(prompt)
        
        if debug_print:
            print("******DEBUG******")
            print("Prompt is: ", repr(prompt))
        
        text = self.generate_raw(prompt)
        
        if debug_print:
            print("Generated result is: ", repr(text))
            print("******END DEBUG******")
        
        result = self.result_replace(text)
        
        # Retry if result is empty
        if len(result) == 0:
            return self.generate(prompt)
        
        return result
