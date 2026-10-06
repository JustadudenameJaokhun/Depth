import os
import sys
import json
import platform

def get_system_summary():
    return {
        "os_name": "Depth Rare (Mint Abyss)",
        "kernel": platform.release(),
        "arch": platform.machine(),
        "python": platform.python_version(),
        "theme": {
            "name": "Abyss Crimson",
            "accent": "#E61919",
            "base": "#0A0A0C"
        },
        "display": {
            "resolution": "1920x1080",
            "scale": "100%",
            "refresh": "60Hz"
        },
        "package_manager": {
            "name": "dive",
            "repo": "https://repo.depth-os.org/core"
        }
    }

if __name__ == "__main__":
    print(json.dumps(get_system_summary(), indent=2))
