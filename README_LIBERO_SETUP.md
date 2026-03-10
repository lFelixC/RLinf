# RLinf Libero One-Click Environment Setup

This README only covers environment setup for Libero (no training or evaluation steps).

## Prerequisites

- Linux with NVIDIA GPU driver installed
- `git`
- Internet access for dependency download
- RLinf repository checked out locally

## One-Click Setup (uv, non-Docker)

Run from the RLinf repo root:

```bash
cd /data/RLinf
pip install --upgrade uv
bash requirements/install.sh embodied --env maniskill_libero --venv .venv-libero --install-rlinf
source .venv-libero/bin/activate
```

If you need mirror acceleration:

```bash
bash requirements/install.sh embodied --env maniskill_libero --venv .venv-libero --install-rlinf --use-mirror
```

## Verify Environment

```bash
python - <<'PY'
import gymnasium
import mani_skill
import rlinf
print("Libero environment setup is ready.")
PY
```
