"""Offline checks for tools/update_interface.py."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import update_interface as ui  # noqa: E402

SAMPLE = """Region!STRING:0|BuildConfig!HEX:16|CDNConfig!HEX:16|KeyRing!HEX:16|BuildId!DEC:4|VersionsName!String:0|ProductConfig!HEX:16
## seqn = 3000000
eu|aa|bb||65000|12.1.5.65000|cc
us|aa|bb||65001|12.1.5.65001|cc
"""

assert ui.version_to_interface("12.1.5.65000") == 120105
assert ui.version_to_interface("1.15.9.1234") == 11509
assert ui.version_to_interface("3.80.2.1") == 38002
assert ui.parse_versions(SAMPLE) == "12.1.5.65001"
assert ui.parse_versions("Region!STRING:0|VersionsName!String:0\n") is None

toc = "## Interface: 50504, 38002, 20506, 11509\n## Title: X\r\n"
# New patch for one major, a brand-new major, and nothing fetched for the rest.
out = ui.update_toc(toc, [50505, 60000])
assert out.startswith("## Interface: 60000, 50505, 38002, 20506, 11509\n"), out
assert out.endswith("## Title: X\r\n")
assert ui.update_toc(toc, []) == toc

print("update_interface tests OK")
