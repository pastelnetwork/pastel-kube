#!/usr/bin/env python3
# Copyright (c) 2022 The Pastel Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or https://www.opensource.org/licenses/mit-license.php.
import re
import platform
from pathlib import Path

NETCONFIG = 'netconfig.txt'

TEMPLATES = {
  '.docker/Dockerfile.cnode.template'         : '.docker/Dockerfile.cnode',
  '.docker/pastel.conf.template'              : '.docker/cnode/pastel.conf',
  '.k8s/pastel-kube.deployment.template.yaml' : '.k8s/pastel-kube.deployment.yaml'
}

def in_wsl() -> bool:
    return 'microsoft-standard' in platform.uname().release

def remove_prefix(text, prefix):
    if text.startswith(prefix):
        return text[len(prefix):]
    return text

rootdir=Path(__file__).resolve().parent.parent
isWindows = platform.system() == "Windows"
if isWindows or in_wsl():
  # if running on WSL - remove /mnt prefix
  hostVolumeDir='/run/desktop/mnt/host/' + remove_prefix(str(rootdir), '/mnt/')
else:
  hostVolumeDir=str(rootdir)

# read options from a file into dictionary
opts = {}
with open(rootdir / NETCONFIG) as f:
  for line in f:
    s = line.strip()
    # skip comments
    if not s.startswith('#') and s:
      k, v = s.split('=', 1)
      opts[k.rstrip().strip('\"')] = v.lstrip().strip('\"')
opts['host-volume-dir'] = hostVolumeDir
print(f"  Configuration options: {opts}")

print(f"  Building network: {opts['network']}")

# process all template files
# replace options in format ${option} with the values from dictionary
for template_file, target_file in TEMPLATES.items():
  with open(rootdir / template_file, "r") as f:
    data = f.read()
    for k, v in opts.items():
      data = re.sub(r"\$\{" + re.escape(k) + r"\}", v, data)
    with open(rootdir / target_file, "w") as fto:
      fto.write(data)
    print(f'  processed template [{template_file}] -> [{target_file}]');
