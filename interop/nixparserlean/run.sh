#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"

if [[ -n "${NIXPARSERLEAN_DIR:-}" ]]; then
  nixparserlean_dir="$NIXPARSERLEAN_DIR"
else
  nixparserlean_dir="$repo_root/../nixparserlean"
fi

if [[ ! -f "$nixparserlean_dir/lakefile.lean" ]]; then
  echo "error: could not find nixparserlean checkout at $nixparserlean_dir" >&2
  echo "set NIXPARSERLEAN_DIR=/path/to/nixparserlean to override" >&2
  exit 1
fi

nixparserlean_dir="$(cd -- "$nixparserlean_dir" && pwd)"

cd "$repo_root"
nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml -- \
  --repo "$repo_root" \
  --nixparserlean-dir "$nixparserlean_dir" \
  --only-nixparserlean-interop
