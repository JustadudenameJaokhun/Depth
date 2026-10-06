import os
import sys
import json
import subprocess

def get_repo_packages():
    repo_file = "/home/jaokhun/Projects/Depth/pkg/repo/repo.json"
    if os.path.exists(repo_file):
        try:
            with open(repo_file, "r") as f:
                data = json.load(f)
                return data.get("packages", [])
        except Exception:
            pass
    return []

def get_installed_packages():
    home = os.environ.get("HOME", "")
    dirs = [
        "/var/lib/dive/installed",
        os.path.join(home, ".local/share/dive/installed")
    ]
    installed = set()
    for d in dirs:
        if os.path.exists(d):
            for name in os.listdir(d):
                if name.endswith(".manifest"):
                    installed.add(name[:-9])
    return list(installed)

def package_action(action, pkg_name):
    dive_bin = "/home/jaokhun/Projects/Depth/pkg/dive"
    cmd = [dive_bin, action, pkg_name]
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return p.returncode == 0, p.stdout.strip()

if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] in ("install", "remove"):
        ok, out = package_action(sys.argv[1], sys.argv[2])
        print(f"Result: {ok}\n{out}")
    else:
        repo_pkgs = get_repo_packages()
        inst = set(get_installed_packages())
        summary = []
        for p in repo_pkgs:
            is_inst = p["name"] in inst
            summary.append({
                "name": p["name"],
                "version": p["version"],
                "arch": p.get("arch", "x86_64"),
                "desc": p["description"],
                "installed": is_inst
            })
        print(json.dumps(summary, indent=2))
