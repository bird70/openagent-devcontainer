# PROJECT KNOWLEDGE BASE

**Generated:** 2026-05-09  
**Commit:** 0d3fb54  
**Branch:** main

---

## OVERVIEW

**Oh My OpenAgent Secure Dev Container** - A security-hardened, container-first development environment for building with `oh-my-openagent` (AI agent framework). Isolates workspace via Docker volumes, disables telemetry, drops Linux capabilities, and bridges GitHub Copilot auth for Claude 3.5 Sonnet/Opus model access.

Primary workload: **Llama 3.2 3B cybersecurity fine-tuning** using Unsloth for ultra-low-resource GPU training (4GB VRAM minimum).

---

## STRUCTURE

```
.
├── .devcontainer/              # VS Code Dev Container config + Dockerfile
├── .opencode/                  # GitHub Copilot + OpenCode agent config
├── scripts/                    # Environment bootstrap and Git credential setup
├── finetune-gpt-oss-cybersecurity/  # Main workload: Python ML fine-tuning
│   ├── fine_tune_gpt_oss_cybersecurity.py  [entry point]
│   ├── llama_finetuning.py
│   ├── config.yaml
│   └── *.ipynb                 # Jupyter notebooks for experimentation
├── geoparquet_duckdb_datasharing/  [placeholder]
├── project_drafts/             [placeholder]
├── venv/                       # Python virtual environment (auto-created)
└── README.md                   # Security posture + usage guide
```

---

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| **Fine-tune Llama for cybersecurity** | `finetune-gpt-oss-cybersecurity/` | Entry: `fine_tune_gpt_oss_cybersecurity.py` |
| **Configure agent behavior** | `.devcontainer/oh-my-openagent.json` | Model selection, tool permissions, constraints |
| **Set up environment** | `scripts/bootstrap-oh-my-openagent.sh` | Installs OpenCode, configures Copilot auth |
| **Fix container issues** | `.devcontainer/Dockerfile` | Bun, uv, OpenCode binary versions |
| **Git credentials** | `scripts/post-create.sh` | Custom credential helper using `GITHUB_TOKEN` |

---

## CONVENTIONS

### Security Posture (Non-Negotiable)

- **NO Docker socket mount**, NO privileged mode, NO host home bind
- Config/cache → Docker named volumes (`omo-dev-config`, `omo-dev-cache`)
- Telemetry explicitly disabled: `OMO_DISABLE_POSTHOG=1`, `OMO_SEND_ANONYMOUS_TELEMETRY=0`
- Container runs with `no-new-privileges`, PID limit 512

### Toolchain

- **Python**: `uv` for venv mgmt + pip package install
- **Node/CLI**: `Bun` (symlinked as `node`) for `oh-my-opencode` CLI
- **Auth**: GitHub Copilot OAuth (requires `gh auth login`), NOT personal access tokens

### Fine-Tuning Patterns

- **Framework**: Unsloth + LoRA (4-bit quantization) for memory efficiency
- **Dataset**: Hugging Face datasets (Trendyol, OptikalLLM, Cybersec-Reasoning)
- **Config**: YAML-based (generated via `--create-sample-config`)
- **Output**: LoRA adapter + tokenizer in `./llama-3.2-3b-cybersecurity-lora/`

---

## ANTI-PATTERNS (THIS PROJECT)

### Forbidden Practices

1. **Security Violations**
   - ❌ Mount Docker socket or run privileged
   - ❌ Modify host system from container
   - ❌ Load models without `use_safetensors=True` where possible

2. **CLI Gotchas**
   - ❌ `bunx oh-my-openagent ...` (WRONG)
   - ✅ `bunx oh-my-opencode ...` (CORRECT)
   - ❌ Manual Bun install if `bunx` missing → use `bash scripts/bootstrap-oh-my-openagent.sh`

3. **Fine-Tuning Constraints**
   - ❌ High `batch_size` on low-memory GPU → reduce instead
   - ❌ `load_best_model_at_end=True` (causes strategy mismatch error)
   - ❌ Large `max_length` on consumer GPU → use 512-1024 instead
   - ✅ Prefer `load_in_4bit` over `load_in_8bit` for tight VRAM

---

## UNIQUE STYLES & PATTERNS

| Pattern | Why | Where |
|---------|-----|-------|
| **Bun as Node symlink** | Run Node scripts without Node.js install | `.devcontainer/Dockerfile` |
| **Manual binary extraction** | Build reproducibility + security (shasum-ready) | Dockerfile: Bun, uv, OpenCode install |
| **Dynamic Git credential helper** | Act on behalf of repo owner (`bird70`) via `GITHUB_TOKEN` | `scripts/post-create.sh` |
| **Copilot-only auth** | Bootstrap explicitly disables OpenAI/Gemini, enables Copilot only | `scripts/bootstrap-oh-my-openagent.sh` |
| **Strict capability dropping** | Defense-in-depth: container can't escape | `.devcontainer/devcontainer.json` |

---

## COMMANDS

### Environment Setup
```bash
# First boot (automatic via post-create hook)
bash scripts/post-create.sh

# Manual bootstrap (if needed)
bash scripts/bootstrap-oh-my-openagent.sh

# Verify agent health
bunx oh-my-opencode doctor

# Configure model/tools
bunx oh-my-opencode config --interactive
```

### Fine-Tuning Workflow
```bash
# Generate sample config
python finetune-gpt-oss-cybersecurity/fine_tune_gpt_oss_cybersecurity.py --create-sample-config

# Train on Trendyol dataset
python finetune-gpt-oss-cybersecurity/fine_tune_gpt_oss_cybersecurity.py \
  --config finetune-gpt-oss-cybersecurity/config.yaml \
  --dataset "Trendyol/Trendyol-Cybersecurity-Instruction-Tuning-Dataset"

# Inference with trained model
python finetune-gpt-oss-cybersecurity/fine_tune_gpt_oss_cybersecurity.py \
  --inference ./llama-3.2-3b-cybersecurity-lora \
  --prompt "What are the signs of a phishing attack?"
```

### Verification
```bash
# Check Python vulnerabilities
pip-audit

# Verify Copilot auth status
gh auth status
```

---

## NOTES & GOTCHAS

1. **Copilot Auth Required**: `gh auth login` must be run first time. Standard PATs insufficient—requires OAuth device flow.

2. **CUDA Setup**: Fine-tuning requires CUDA 11.8+ + compatible PyTorch. See `finetune-gpt-oss-cybersecurity/README.md` for installation.

3. **Memory Constraints**: 
   - Minimum 4GB GPU VRAM (Unsloth optimized)
   - Recommended 8GB+
   - Fallback to CPU is "extremely slow"

4. **Git Credential Hijacking**: The container auto-installs a custom Git credential helper that uses `GITHUB_TOKEN` if present. This ensures `git push/pull` use the configured account regardless of `gh` CLI state.

5. **No Existing AGENTS.md**: This is the first AGENTS.md generated for the project.

6. **Placeholder Directories**: `geoparquet_duckdb_datasharing/` and `project_drafts/` are empty—likely for future sub-projects.

---

## RESOURCES

- **oh-my-openagent**: https://github.com/code-yeongyu/oh-my-openagent
- **Unsloth**: Memory-efficient LLM fine-tuning library
- **Llama 3.2 3B**: Meta's ultra-small instruction-tuned model
- **Cybersecurity Datasets**:
  - Trendyol: https://huggingface.co/datasets/Trendyol/Trendyol-Cybersecurity-Instruction-Tuning-Dataset
  - OptikalLLM: https://huggingface.co/datasets/OptikalLLM/CyberSecurity-Instruction-Dataset
  - Cybersec-Reasoning: https://huggingface.co/datasets/Llama-Factory/Cybersecurity-Reasoning
