import os
import sys
import json
import stat

BOOKMARKS = [
    {"name": "Home", "path": os.environ.get("HOME", "/root"), "icon": "depth-files.svg"},
    {"name": "Root", "path": "/", "icon": "depth-core.svg"},
    {"name": "Depth Project", "path": "/home/jaokhun/Projects/Depth", "icon": "depth-launcher.svg"},
    {"name": "Packages", "path": "/home/jaokhun/Projects/Depth/pkg/repo/packages", "icon": "depth-package.svg"}
]

def list_path(target_path):
    if not os.path.exists(target_path):
        return {"error": "Path does not exist", "items": []}
    items = []
    try:
        for entry in os.scandir(target_path):
            st = entry.stat(follow_symlinks=False)
            is_dir = stat.S_ISDIR(st.st_mode)
            items.append({
                "name": entry.name,
                "is_dir": is_dir,
                "size": st.st_size if not is_dir else 0,
                "path": entry.path
            })
    except PermissionError:
        return {"error": "Permission denied", "items": []}
    items.sort(key=lambda x: (not x["is_dir"], x["name"].lower()))
    return {
        "current_path": target_path,
        "bookmarks": BOOKMARKS,
        "items": items
    }

if __name__ == "__main__":
    p = sys.argv[1] if len(sys.argv) > 1 else "/home/jaokhun/Projects/Depth"
    print(json.dumps(list_path(p), indent=2))
