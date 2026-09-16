"""Removes the three empty usage-description keys Godot's iOS template always
writes, from an exported Xcode project.

  python3 tools/tidy_ios_export.py ~/Developer/CarGarage-iOS

Godot's `ios.zip` hardcodes these in its Info.plist template:

    <key>NSCameraUsageDescription</key>
    <string>$camera_usage_description</string>

and substitutes whatever the export preset holds. Car Garage leaves all three
blank on purpose - the game has no camera, microphone or photo-library code -
so the substitution produces the KEY with an EMPTY STRING, which is worse than
having no key at all. Xcode flags each one, App Store review treats an empty
purpose string as a rejection trigger, and it contradicts the privacy policy at
https://biglittlejobs.com/privacy, which says in as many words that the apps
"do not ask for the camera, the microphone, the photo library, contacts, or
location, and cannot use them".

There is no preset option that suppresses them, so this runs after every export.
The exported Xcode project is a build artifact and is regenerated every time -
never edit it by hand expecting the edit to survive.

A key is only removed when its value is EMPTY. If a future version of the game
genuinely asks for one of these, fill the description in the export preset and
this leaves it alone.

It also fixes the signing conflict Godot writes into project.pbxproj. Godot sets
CODE_SIGN_STYLE = Automatic AND CODE_SIGN_IDENTITY = "Apple Distribution" on the
Release configuration, and Xcode refuses that pair:

    CarGarage has conflicting provisioning settings. CarGarage is automatically
    signed for development, but a conflicting code signing identity Apple
    Distribution has been manually specified.

Under automatic signing the identity is Xcode's to choose - it substitutes the
distribution certificate itself when you Archive and Distribute. "Apple
Development" is the value automatic signing expects, and it does NOT mean the
archive comes out development-signed.
"""
# Tree Crew's own tidier (agentic-brian/Tree-Chopper bf29315), for Car Garage.
import plistlib
import sys
from pathlib import Path

KEYS = (
    "NSCameraUsageDescription",
    "NSMicrophoneUsageDescription",
    "NSPhotoLibraryUsageDescription",
)


def tidy(plist_path):
    with open(plist_path, "rb") as fh:
        data = plistlib.load(fh)
    removed, kept = [], []
    for key in KEYS:
        if key not in data:
            continue
        if str(data[key]).strip() == "":
            del data[key]
            removed.append(key)
        else:
            kept.append(key)
    if removed:
        with open(plist_path, "wb") as fh:
            plistlib.dump(data, fh)
    return removed, kept


def fix_signing(pbxproj):
    """Apple Distribution -> Apple Development, so automatic signing can work."""
    text = pbxproj.read_text(encoding="utf-8")
    old = 'CODE_SIGN_IDENTITY = "Apple Distribution";'
    n = text.count(old)
    if n:
        pbxproj.write_text(text.replace(old, 'CODE_SIGN_IDENTITY = "Apple Development";'),
                           encoding="utf-8")
    return n


def main(argv):
    if len(argv) != 2:
        print(next(l.strip() for l in __doc__.splitlines() if "tidy_ios_export.py" in l))
        return 2
    root = Path(argv[1]).expanduser()
    plists = [p for p in root.rglob("*-Info.plist") if ".xcframework" not in str(p)]
    if not plists:
        print("no *-Info.plist under %s - is that an exported Xcode project?" % root)
        return 1
    fails = 0
    for plist in plists:
        removed, kept = tidy(plist)
        print("%s" % plist.relative_to(root))
        for key in removed:
            print("  removed  %s (was empty)" % key)
        for key in kept:
            print("  kept     %s (has a description)" % key)
        if not removed and not kept:
            print("  nothing to do")
        leftover = [k for k in KEYS if k in plistlib.loads(plist.read_bytes()) and
                    str(plistlib.loads(plist.read_bytes())[k]).strip() == ""]
        fails += len(leftover)
    for pbxproj in root.rglob("project.pbxproj"):
        n = fix_signing(pbxproj)
        print("%s" % pbxproj.relative_to(root))
        if n:
            print("  fixed    %d CODE_SIGN_IDENTITY, Apple Distribution -> Apple Development" % n)
        else:
            print("  nothing to do")
        left = pbxproj.read_text(encoding="utf-8").count('CODE_SIGN_IDENTITY = "Apple Distribution";')
        fails += left
    print("TIDY_IOS %s" % ("PASS" if fails == 0 else "FAIL %d" % fails))
    return 0 if fails == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
