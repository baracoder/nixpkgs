#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3 python3Packages.requests

import requests
import re
import json

manifset_c_url = 'https://raw.githubusercontent.com/NVIDIA/nvidia-installer/main/manifest.c'

file_contents = requests.get(manifset_c_url, allow_redirects=True).text

#    /*
#     * inherit_path   ------------------------------------------+
#     * is_conflicting ---------------------------------------+  |
#     * is_temporary   ------------------------------------+  |  |
#     * is_opengl      ---------------------------------+  |  |  |
#     * is_shared_lib  ------------------------------+  |  |  |  |
#     * is_symlink     ---------------------------+  |  |  |  |  |
#     * has_path       ------------------------+  |  |  |  |  |  |
#     * installable    ---------------------+  |  |  |  |  |  |  |
#     * has_arch       ------------------+  |  |  |  |  |  |  |  |
#     *                                  |  |  |  |  |  |  |  |  |
#     */
#      ENTRY(KERNEL_MODULE_SRC,          F, T, F, F, F, F, F, T, T)


p = re.compile(r'ENTRY\((?P<entry>[A-Z0-9_]+),\s*(?P<has_arch>T|F), (?P<installable>T|F), (?P<has_path>T|F), (?P<is_symlink>T|F), (?P<is_shared_lib>T|F), (?P<is_opengl>T|F), (?P<is_temporary>T|F), (?P<is_conflicting>T|F), (?P<inherit_path>T|F)\)')

matches = [m.groupdict() for m in p.finditer(file_contents)]


def map_entry(entry):
    """
    Translate T or F strings to True and False
    """
    def map_types(k, v):
        if k == 'entry':
            return v
        return v == 'T'
    return { k: map_types(k, v) for (k, v) in entry.items()}

matches_parsed = [map_entry(x) for x in matches]
for m in matches_parsed:
    print(m)

with open('manifest-types.json', 'w') as outfile:
    json.dump(matches_parsed, outfile, indent=4)