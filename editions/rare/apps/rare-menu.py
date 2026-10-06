import sys
import json

CATEGORIES = [
    "All Applications",
    "Accessories",
    "Administration",
    "Development",
    "System"
]

APPLICATIONS = [
    {
        "id": "terminal",
        "name": "Bedrock Terminal",
        "category": "System",
        "exec": "/home/jaokhun/Projects/Depth/sys/bin/ls",
        "icon": "depth-terminal.svg",
        "desc": "Ultra-lean x86-64 assembly console"
    },
    {
        "id": "store",
        "name": "Dive Software Manager",
        "category": "Administration",
        "exec": "python3 /home/jaokhun/Projects/Depth/editions/rare/apps/rare-store.py",
        "icon": "depth-package.svg",
        "desc": "Browse, install, and update Depth packages"
    },
    {
        "id": "files",
        "name": "Depth Files",
        "category": "Accessories",
        "exec": "python3 /home/jaokhun/Projects/Depth/editions/rare/apps/rare-files.py",
        "icon": "depth-files.svg",
        "desc": "Intuitive directory and partition explorer"
    },
    {
        "id": "partition",
        "name": "Disk & Partition Cutter",
        "category": "Administration",
        "exec": "python3 /home/jaokhun/Projects/Depth/installer/partition.py list",
        "icon": "depth-drive.svg",
        "desc": "Automated partition cutting and merging"
    },
    {
        "id": "settings",
        "name": "Control Center",
        "category": "System",
        "exec": "python3 /home/jaokhun/Projects/Depth/editions/rare/apps/rare-settings.py",
        "icon": "depth-settings.svg",
        "desc": "Display, themes, and system settings"
    }
]

def search_apps(query="", category="All Applications"):
    results = []
    q = query.lower()
    for app in APPLICATIONS:
        cat_match = category == "All Applications" or app["category"] == category
        q_match = not q or q in app["name"].lower() or q in app["desc"].lower()
        if cat_match and q_match:
            results.append(app)
    return results

if __name__ == "__main__":
    q = sys.argv[1] if len(sys.argv) > 1 else ""
    cat = sys.argv[2] if len(sys.argv) > 2 else "All Applications"
    print(json.dumps(search_apps(q, cat), indent=2))
