#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33mWARN:\033[0m %s\n' "$*"; }
error() { printf '\033[1;31mERROR:\033[0m %s\n' "$*"; }

check_cmd() {
  if ! command -v "$1" &>/dev/null; then
    error "$1 is not installed."
    return 1
  fi
}

# ---------------------------------------------------------------------------
# 1. check prerequisites
# ---------------------------------------------------------------------------
info "Checking prerequisites…"

check_cmd node
check_cmd pnpm

NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]')
if (( NODE_MAJOR < 20 )); then
  error "Node.js >= 20 required (found $(node -v)). Please upgrade."
  exit 1
fi
info "Node $(node -v) ✓"

# ---------------------------------------------------------------------------
# 2. install pnpm dependencies
# ---------------------------------------------------------------------------
info "Installing pnpm dependencies…"
pnpm install

# ---------------------------------------------------------------------------
# 3. build shared package (other packages depend on it)
# ---------------------------------------------------------------------------
info "Building @wrench/shared…"
pnpm run build -w @wrench/shared

# ---------------------------------------------------------------------------
# 4. python environment (optional — for modal-infra development)
# ---------------------------------------------------------------------------
MODAL_DIR="$REPO_ROOT/packages/modal-infra"

setup_python() {
  info "Setting up Python environment for modal-infra…"

  if ! command -v python3 &>/dev/null; then
    warn "python3 not found — skipping Python setup."
    warn "Install Python >= 3.12 if you plan to work on packages/modal-infra."
    return
  fi

  PY_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')
  if (( PY_MINOR < 12 )); then
    warn "Python >= 3.12 required for modal-infra (found $(python3 --version))."
    warn "Skipping Python setup."
    return
  fi

  if command -v uv &>/dev/null; then
    info "Syncing Python dependencies with uv.lock…"
    (
      cd "$MODAL_DIR"
      uv sync --frozen --extra dev
    )
    info "Python environment ready (activate with: source packages/modal-infra/.venv/bin/activate)"
    return
  fi

  warn "uv not found — falling back to pip editable install."
  warn "Install uv for lockfile-reproducible Python environments."

  if [ ! -d "$MODAL_DIR/.venv" ]; then
    info "Creating virtualenv at packages/modal-infra/.venv…"
    python3 -m venv "$MODAL_DIR/.venv"
  fi

  # shellcheck disable=SC1091
  source "$MODAL_DIR/.venv/bin/activate"
  info "Installing Python dev dependencies…"
  pip install -q -e "$MODAL_DIR[dev]"
  deactivate
  info "Python environment ready (activate with: source packages/modal-infra/.venv/bin/activate)"
}

if [ -d "$MODAL_DIR" ]; then
  if command -v python3 &>/dev/null; then
    setup_python
  else
    info "python3 not found — skipping optional modal-infra Python setup."
  fi
fi

# ---------------------------------------------------------------------------
# 5. verify the setup
# ---------------------------------------------------------------------------
info "Running type check…"
if pnpm run typecheck; then
  info "Type check passed ✓"
else
  warn "Type check had issues — you may need to build additional packages."
fi

# ---------------------------------------------------------------------------
# done
# ---------------------------------------------------------------------------
printf '\n'
info "Setup complete! You can now:"
info "  pnpm run dev -w @wrench/web             # start web dev server"
info "  pnpm run test -w @wrench/control-plane   # run control-plane tests"
info "  pnpm run lint                             # lint all packages"
info "  pnpm run typecheck                        # type-check all packages"
