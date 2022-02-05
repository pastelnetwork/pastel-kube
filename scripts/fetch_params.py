#!/usr/bin/env python3
# Copyright (c) 2022 The Pastel Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or https://www.opensource.org/licenses/mit-license.php.

import urllib.request
from urllib.parse import urljoin
from pathlib import Path
import shutil
import hashlib

FETCH_URL="https://www.dropbox.com/sh/gsfmcb4b0wd38vf/"
FETCH_SUFFIX="?dl=1"
DOWNLOAD_PATH=".pastel-params"

PARAM_FILES = {
	'sapling-spend.params'  : ('AACRCfGwkDcwdbhDXzl0XFeka/', '8e48ffd23abb3a5fd9c5589204f32d9c31285a04b78096ba40a79b75677efc13'),
	'sapling-output.params' : ('AABuQfzAMAiwlzzQyeEP4Sw0a/', '2f0ebbcbb9bb0bcffe95a397e7eba89c29eb4dde6191c339db88570e3f3fb0e4'),
	'sprout-groth16.params' : ('AABSvmY9SQWwyYXGK2DB8f4xa/', 'b685d700c60328498fbde589c8c7c484c722b788b265b72af448a5bf0ee55b50')
}

download_dir = Path(DOWNLOAD_PATH)
if not download_dir.exists():
    download_dir.mkdir()
url_opener = urllib.request.build_opener(
    urllib.request.HTTPDefaultErrorHandler(),
    urllib.request.HTTPCookieProcessor(),
    urllib.request.HTTPRedirectHandler(),
    urllib.request.HTTPSHandler(),
    )
for filename, fparams in PARAM_FILES.items():
    local_file = download_dir / filename
    print(f'Processing [{filename}]...')
    if local_file.exists():
        print('...already exists')
        continue
    url = urljoin(urljoin(FETCH_URL, fparams[0]), filename) + FETCH_SUFFIX
    try:
        request = urllib.request.Request(url)
        output_file = str(local_file) + '.chk'
        print('  - downloading')
        with url_opener.open(request) as response, open(output_file, 'wb') as out_file:
            shutil.copyfileobj(response, out_file)
            print('  - downloaded')
        chksum = False
        with open(output_file, 'rb') as f:
            bytes = f.read()
            hash = hashlib.sha256(bytes).hexdigest()
            if (hash == fparams[1]):
                chksum = True
        if chksum:
            f = Path(output_file)
            f.rename(f.parent / filename)
            print('  - checksum matches')
        else:
            print('  - checksum does not match')
        print('...done')
    except OSError as e:
        print(f"Failed to retrieve URL [{url}] {e}")