#!/usr/bin/env bash
# 5 構成の drvPath を出力する。path: フレークで評価して self.rev / self.dirtyRev を null に固定し、
# コミットをまたいだ比較を可能にする (darwin の system.configurationRevision 対策)。
set -euo pipefail
cd "$(dirname "$0")/.."
attrs=(
  'nixosConfigurations."schwertleite".config.system.build.toplevel.drvPath'
  'darwinConfigurations."alice".system.drvPath'
  'darwinConfigurations."harmony".system.drvPath'
  'darwinConfigurations."ShotanoMacBook-Pro".system.drvPath'
  'homeConfigurations."haneta".activationPackage.drvPath'
)
for attr in "${attrs[@]}"; do
  printf '%s %s\n' "$(nix eval --raw "path:$PWD#$attr")" "$attr"
done
