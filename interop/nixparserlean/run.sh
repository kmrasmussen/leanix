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

out_dir="$repo_root/generated/interop-nixparserlean"
mkdir -p "$out_dir"

render_case() {
  local name="$1"
  shift
  local output="$out_dir/$name.flake.nix"

  echo "render: $name"
  (
    cd "$repo_root"
    nix develop --command lake exe leanix "$@" --out "$output"
  )

  echo "desugar: $name"
  (
    cd "$nixparserlean_dir"
    nix develop --command lake exe nixparserlean --desugar --file "$output" >/dev/null
  )

  echo "eval: $name"
  (
    cd "$nixparserlean_dir"
    nix develop --command lake exe nixparserlean --eval --file "$output" >/dev/null
  )
}

render_case "hello" render-example
render_case "closure" render-closure
render_case "cli-schema" render-cli-schema
render_case "showcase" render-showcase
render_case "self" render-self --source "path:$repo_root"

echo "nixparserlean interop smoke passed"
