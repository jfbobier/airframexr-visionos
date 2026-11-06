#!/bin/sh
# Applies the AirFrameXR patches (patches/*.patch) to the ALVR submodule, once: a patch that is already in (reverse applies) is skipped.
# Run from the repository root, before building alvr_client_core.
set -e
for p in patches/*.patch; do
  [ -e "$p" ] || continue
  if git -C ALVR apply --reverse --check "../$p" 2>/dev/null; then
    echo "patch already applied: $p"
  else
    git -C ALVR apply "../$p"
    echo "patch applied: $p"
  fi
done
