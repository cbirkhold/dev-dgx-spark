# NVIDIA DGX Spark System Reference

## Overview

The DGX Spark is NVIDIA's compact AI workstation powered by the **GB10 Grace Blackwell Superchip**.

---

## Hardware Specifications

### Processor & GPU

| Component           | Specification                                                                     |
| ------------------- | --------------------------------------------------------------------------------- |
| Architecture        | NVIDIA Grace Blackwell (GB10 Superchip)                                           |
| GPU                 | Blackwell Architecture with 5th Gen Tensor Cores (FP16/FP8/FP4), 4th Gen RT Cores |
| CUDA Cores          | 6,144                                                                             |
| CPU                 | 20-core Arm (10× Cortex-X925 + 10× Cortex-A725)                                   |
| CPU P-Core Max Freq | 4 GHz                                                                             |
| CPU E-Core Max Freq | 2.8 GHz                                                                           |
| Copy Engines        | 2 (simultaneous data transfers to/from GPU memory)                                |

### AI Performance

| Metric         | Value                                                  |
| -------------- | ------------------------------------------------------ |
| AI Compute     | Up to 1,000 TOPS / 1 PFLOP at FP4 with sparsity        |
| Model Capacity | Up to 200B parameters (single unit), 405B (dual Spark) |

### Memory

| Specification    | Value                         |
| ---------------- | ----------------------------- |
| System Memory    | 128 GB LPDDR5x unified memory |
| Memory Interface | 256-bit (16 channels)         |
| Memory Speed     | 8533 MT/s                     |
| Memory Bandwidth | 273 GB/s                      |

### Storage

| Specification    | Value                       |
| ---------------- | --------------------------- |
| Type             | NVMe M.2 SSD                |
| Capacity Options | 1 TB or 4 TB                |
| Features         | Self-encrypting drive (SED) |

---

## Software Stack

### Operating System

| Component    | Version                                     |
| ------------ | ------------------------------------------- |
| Base OS      | Ubuntu 24.04 (server with desktop packages) |
| Kernel       | Linux 6.14 HWE (Hardware Enablement)        |
| GPU Driver   | 580.95.05 (OpenRM kernel module)            |
| CUDA Toolkit | CUDA 13.0                                   |

### Pre-installed NVIDIA AI Stack

**Core Libraries:**

- cuDNN (CUDA Deep Neural Network library)
- TensorRT and TensorRT-LLM
- NCCL (NVIDIA Collective Communications Library)
- All supported NVIDIA math libraries

**Development Tools:**

- Nsight Systems, Nsight Compute, Nsight Graphics
- Nsight Deep Learning Designer
- CUDA GDB
- JupyterLab (pre-configured with CUDA 13.0 and PyTorch)

**System Tools:**

- DGX Dashboard (monitoring and management GUI)
- NVIDIA Sync (remote access and configuration)
- NGC CLI (access to NVIDIA GPU Cloud)
- Docker with NVIDIA Container Runtime

---

## Inference Engines

### TensorRT-LLM

Optimized LLM inference with kernel-level optimizations, efficient memory layouts, and advanced quantization. Provides OpenAI-compatible API on ports 8355 (LLM) and 8356 (VLM).

**Supported Models (pre-quantized checkpoints available):**

| Model                          | Quantization | HF Handle                                   |
| ------------------------------ | ------------ | ------------------------------------------- |
| GPT-OSS-20B                    | MXFP4        | `openai/gpt-oss-20b`                        |
| GPT-OSS-120B                   | MXFP4        | `openai/gpt-oss-120b`                       |
| Llama-3.1-8B-Instruct          | FP8 / NVFP4  | `nvidia/Llama-3.1-8B-Instruct-FP8`          |
| Llama-3.3-70B-Instruct         | NVFP4        | `nvidia/Llama-3.3-70B-Instruct-FP4`         |
| Qwen3-8B                       | FP8 / NVFP4  | `nvidia/Qwen3-8B-FP8`                       |
| Qwen3-14B                      | FP8 / NVFP4  | `nvidia/Qwen3-14B-FP8`                      |
| Qwen3-32B                      | NVFP4        | `nvidia/Qwen3-32B-FP4`                      |
| Qwen3-30B-A3B                  | NVFP4        | `nvidia/Qwen3-30B-A3B-FP4`                  |
| Phi-4-multimodal-instruct      | FP8 / NVFP4  | `nvidia/Phi-4-multimodal-instruct-FP8`      |
| Phi-4-reasoning-plus           | FP8 / NVFP4  | `nvidia/Phi-4-reasoning-plus-FP8`           |
| Llama-4-Scout-17B-16E-Instruct | NVFP4        | `nvidia/Llama-4-Scout-17B-16E-Instruct-FP4` |
| Qwen3-235B-A22B (dual Spark)   | NVFP4        | `nvidia/Qwen3-235B-A22B-FP4`                |

### Other Inference Options

| Engine         | Description                                                                               |
| -------------- | ----------------------------------------------------------------------------------------- |
| **vLLM**       | High-throughput serving with PagedAttention for memory efficiency and continuous batching |
| **SGLang**     | Fast inference with structured generation support                                         |
| **Ollama**     | Simple model management with Open WebUI integration                                       |
| **NVIDIA NIM** | Containerized microservices for production deployment                                     |
| **llama.cpp**  | Lightweight inference, ~35% performance uplift with NVIDIA optimizations                  |

### Speculative Decoding

Draft-Target approach available via TensorRT-LLM for accelerated inference while maintaining output quality.

---

## NVFP4 Quantization

NVFP4 is a 4-bit floating-point format native to Blackwell Tensor Cores that maintains model accuracy while reducing memory and bandwidth requirements.

**Key characteristics:**

- Floating-point semantics with shared exponent and compact mantissa
- Higher dynamic range than uniform INT4 quantization
- Native mixed-precision execution (FP16, FP8, FP4) with FP16 accumulation
- ~2× model size reduction with ~40% memory savings vs FP8
- Custom model quantization via TensorRT Model Optimizer

**Use case:** Quantize your own models to NVFP4 for memory/throughput benefits even for models not published by NVIDIA.

---

## Fine-Tuning Frameworks

### Supported Approaches

| Framework          | Capabilities                                                                   |
| ------------------ | ------------------------------------------------------------------------------ |
| **PyTorch**        | PEFT, SFT for models 1-70B parameters                                          |
| **NeMo AutoModel** | GPU-accelerated training, FP8 precision, distributed training, ARM64 optimized |
| **LLaMA Factory**  | LoRA, QLoRA, full fine-tuning with hardware-specific optimizations             |
| **Unsloth**        | Optimized fine-tuning with reduced memory footprint                            |

### Vision-Language Model Fine-Tuning

- **Image VLM:** Qwen2.5-VL-7B with GRPO (Generalized Reward Preference Optimization)
- **Video VLM:** InternVL3 8B for video understanding tasks
- Supports LoRA fine-tuning, preference optimization, and structured reasoning

### Image Model Fine-Tuning

**FLUX.1 Dreambooth LoRA:**

- Fine-tune FLUX.1-dev 12B model for custom image generation
- Multi-concept training with multiple models in memory (Diffusion Transformer, CLIP, T5, Autoencoder)
- Output LoRA weights integrate directly with ComfyUI workflows
- Supports training and generation at 1024px and higher resolutions

---

## Image Generation & Rendering

### ComfyUI

Node-based workflow interface for diffusion models (SDXL, FLUX, etc.). Leverage unified memory for large models with all inference running locally.

### Multi-Modal Inference with TensorRT

GPU-accelerated inference for Flux.1 and SDXL diffusion models with optimized performance across FP16, FP8, and FP4 precision formats.

**Requirements:** 48GB+ available for FP16 Flux.1 Schnell operations.

### Isaac Sim & Isaac Lab

GPU-accelerated robotics simulation platform built on NVIDIA Omniverse:

- Photorealistic, physically accurate simulations
- Faster-than-real-time physics simulation
- Isaac Lab provides pre-built RL environments for locomotion, manipulation, navigation
- Build from source on DGX Spark for ARM64/Blackwell optimization

---

## Data Science (CUDA-X / RAPIDS)

Zero-code-change GPU acceleration for Python data science workflows:

| Library                 | Accelerates                                              |
| ----------------------- | -------------------------------------------------------- |
| **cuDF**                | pandas operations, string processing                     |
| **cuML**                | scikit-learn algorithms (LinearSVC, UMAP, HDBSCAN, etc.) |
| **cuGraph**             | Graph analytics                                          |
| **XGBoost**             | Gradient boosting                                        |
| **Apache Spark RAPIDS** | Enterprise data pipelines                                |

### JAX Support

Optimized JAX installation available for DGX Spark with Blackwell architecture.

---

## Multi-Agent & RAG Workflows

### Multi-Agent Chatbot System

Full-stack deployment with:

- Supervisor agent (gpt-oss-120B, ~63GB)
- Specialized agents for coding, RAG, image understanding
- MCP (Model Context Protocol) server integration
- llama.cpp and TensorRT-LLM serving in parallel

**Memory usage:** ~120GB of 128GB by default; use gpt-oss-20B for lighter footprint.

### RAG Applications

- AI Workbench integration for reproducible RAG applications
- Text-to-Knowledge Graph workflows with LLM inference and graph visualization
- Video Search and Summarization (VSS) Agent blueprint

---

## Development Environment

### Remote Access Options

| Method          | Description                               |
| --------------- | ----------------------------------------- |
| **NVIDIA Sync** | Managed SSH tunneling (recommended)       |
| **Tailscale**   | VPN access from anywhere on home network  |
| **VS Code**     | Local or remote development with SSH      |
| **JupyterLab**  | Browser-based notebooks via DGX Dashboard |

### Coding Assistance

**Vibe Coding:** Use DGX Spark as local coding assistant with Ollama + Continue extension in VS Code.

### Live VLM WebUI

Real-time Vision Language Model interaction with webcam streaming for multimodal prototyping.

---

## Key Workflow Notes

### For Rendering Projects

- 4th Gen RT Cores for ray tracing workloads
- NVENC/NVDEC for video encode/decode
- Omniverse/Isaac Sim for photorealistic simulation
- ComfyUI with FLUX/SDXL at 1024px+ resolution
- OpenGL/Vulkan desktop acceleration

### For Machine Learning Projects

- TensorRT-LLM for optimized inference (significant speedup vs PyTorch)
- NVFP4 quantization for memory/throughput gains
- Unified Memory Architecture allows CPU/GPU memory sharing
- Multiple inference engines can run in parallel

### Memory Reporting Note

Third-party tools may report memory differently due to the Unified Memory Architecture; use `nvidia-smi` or DGX Dashboard for accurate reporting.

---

## Resources

| Resource                  | URL                                                                        |
| ------------------------- | -------------------------------------------------------------------------- |
| **Playbooks & Tutorials** | https://build.nvidia.com/spark                                             |
| **User Guide**            | https://docs.nvidia.com/dgx/dgx-spark/index.html                           |
| **GitHub Playbooks**      | https://github.com/NVIDIA/dgx-spark-playbooks                              |
| **Developer Forums**      | https://forums.developer.nvidia.com/c/accelerated-computing/dgx-spark-gb10 |
| **Support**               | https://www.nvidia.com/en-us/support/dgx-spark/                            |

---

_Document Version: 1.0 | Last Updated: January 2026_
_Source: Official NVIDIA DGX Spark Documentation (docs.nvidia.com) and build.nvidia.com/spark, January 2026_
