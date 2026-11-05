# Reads `simctl list -j devices available` on stdin and prints
# "udid<TAB>name<TAB>OS version" for the device matching the given UDID or,
# when the UDID is empty, the given device name and OS version.
import json
import sys

udid, name, os_version = sys.argv[1:4]
for runtime, devices in json.load(sys.stdin)["devices"].items():
    version = runtime.rsplit(".", 1)[-1].removeprefix("iOS-").replace("-", ".")
    for device in devices:
        matches_udid = udid and device["udid"] == udid
        matches_default = not udid and device["name"] == name and version == os_version
        if matches_udid or matches_default:
            print(device["udid"], device["name"], version, sep="\t")
            sys.exit(0)
sys.exit(1)
