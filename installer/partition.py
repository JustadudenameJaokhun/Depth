import os
import sys
import subprocess
import json

def run_cmd(cmd):
    p = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return p.returncode, p.stdout.strip(), p.stderr.strip()

def list_devices():
    rc, out, _ = run_cmd("lsblk -J -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE")
    if rc == 0:
        try:
            data = json.loads(out)
            return data.get("blockdevices", [])
        except Exception:
            pass
    return []

def get_disk_partitions(disk_name):
    dev_path = f"/dev/{disk_name}" if not disk_name.startswith("/dev/") else disk_name
    rc, out, _ = run_cmd(f"sfdisk -d {dev_path}")
    if rc != 0:
        return []
    parts = []
    for line in out.splitlines():
        line = line.strip()
        if line.startswith(dev_path) and "start=" in line and "size=" in line:
            tokens = line.split(":")
            pdev = tokens[0].strip()
            attrs = tokens[1].strip()
            start_val = 0
            size_val = 0
            type_val = "Linux"
            for attr in attrs.split(","):
                attr = attr.strip()
                if attr.startswith("start="):
                    start_val = int(attr.split("=")[1])
                elif attr.startswith("size="):
                    size_val = int(attr.split("=")[1])
                elif attr.startswith("type="):
                    type_val = attr.split("=")[1]
            parts.append({
                "device": pdev,
                "start": start_val,
                "size": size_val,
                "type": type_val
            })
    return parts

def cut_partition(disk_name, part_idx, cut_size_mb, dry_run=False):
    dev_path = f"/dev/{disk_name}" if not disk_name.startswith("/dev/") else disk_name
    parts = get_disk_partitions(dev_path)
    if not parts or part_idx >= len(parts):
        return False, "Target partition index out of range"
    
    target = parts[part_idx]
    sector_size = 512
    cut_sectors = (cut_size_mb * 1024 * 1024) // sector_size
    
    if cut_sectors >= target["size"] - 2048:
        return False, "Cut size exceeds partition boundaries"
    
    part1_start = target["start"]
    part1_size = cut_sectors
    part2_start = part1_start + part1_size
    part2_size = target["size"] - part1_size
    
    print(f"\033[38;2;230;25;25m[CUT]\033[0m Splitting {target['device']} into:")
    print(f"  Part A: start={part1_start}, size={part1_size} sectors ({round(part1_size*sector_size/(1024*1024))} MB)")
    print(f"  Part B: start={part2_start}, size={part2_size} sectors ({round(part2_size*sector_size/(1024*1024))} MB)")
    
    if dry_run:
        return True, "Dry-run cut successful"
    
    script_lines = ["label: gpt" if "nvme" in dev_path else "label: dos"]
    for i, p in enumerate(parts):
        if i == part_idx:
            script_lines.append(f"start={part1_start}, size={part1_size}, type={p['type']}")
            script_lines.append(f"start={part2_start}, size={part2_size}, type={p['type']}")
        else:
            script_lines.append(f"start={p['start']}, size={p['size']}, type={p['type']}")
    
    payload = "\n".join(script_lines) + "\n"
    cmd = f"sfdisk --force {dev_path}"
    p = subprocess.run(cmd, shell=True, input=payload, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if p.returncode == 0:
        return True, "Partition cut completed"
    return False, p.stderr.strip()

def merge_partitions(disk_name, part1_idx, part2_idx, dry_run=False):
    dev_path = f"/dev/{disk_name}" if not disk_name.startswith("/dev/") else disk_name
    parts = get_disk_partitions(dev_path)
    if part1_idx >= len(parts) or part2_idx >= len(parts):
        return False, "Target partition index out of range"
    
    if abs(part1_idx - part2_idx) != 1:
        return False, "Partitions must be adjacent to merge"
    
    first = parts[min(part1_idx, part2_idx)]
    second = parts[max(part1_idx, part2_idx)]
    
    if first["start"] + first["size"] != second["start"]:
        return False, "Partitions are not strictly contiguous"
    
    merged_start = first["start"]
    merged_size = first["size"] + second["size"]
    sector_size = 512
    
    print(f"\033[38;2;230;25;25m[MERGE]\033[0m Merging {first['device']} and {second['device']}:")
    print(f"  Unified: start={merged_start}, size={merged_size} sectors ({round(merged_size*sector_size/(1024*1024))} MB)")
    
    if dry_run:
        return True, "Dry-run merge successful"
    
    script_lines = []
    skip_idx = max(part1_idx, part2_idx)
    keep_idx = min(part1_idx, part2_idx)
    for i, p in enumerate(parts):
        if i == skip_idx:
            continue
        elif i == keep_idx:
            script_lines.append(f"start={merged_start}, size={merged_size}, type={first['type']}")
        else:
            script_lines.append(f"start={p['start']}, size={p['size']}, type={p['type']}")
    
    payload = "\n".join(script_lines) + "\n"
    cmd = f"sfdisk --force {dev_path}"
    p = subprocess.run(cmd, shell=True, input=payload, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if p.returncode == 0:
        return True, "Partition merge completed"
    return False, p.stderr.strip()

def format_target(partition_path, fs_type="ext4"):
    print(f"\033[38;2;230;25;25m[FORMAT]\033[0m Formatting {partition_path} as {fs_type}...")
    if fs_type == "ext4":
        rc, _, err = run_cmd(f"mkfs.ext4 -F -L DEPTH_ROOT {partition_path}")
    elif fs_type == "vfat":
        rc, _, err = run_cmd(f"mkfs.vfat -F 32 -n DEPTH_BOOT {partition_path}")
    else:
        return False, f"Unsupported filesystem: {fs_type}"
    return rc == 0, err

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("\033[1m\033[38;2;230;25;25mDEPTH PARTITION ENGINE\033[0m")
        print("Usage:")
        print("  python3 partition.py list")
        print("  python3 partition.py show <disk>")
        print("  python3 partition.py cut <disk> <part_idx> <cut_size_mb> [--dry-run]")
        print("  python3 partition.py merge <disk> <part1_idx> <part2_idx> [--dry-run]")
        sys.exit(1)
    
    cmd = sys.argv[1]
    if cmd == "list":
        devs = list_devices()
        print(json.dumps(devs, indent=2))
    elif cmd == "show":
        if len(sys.argv) < 3:
            sys.exit(1)
        pts = get_disk_partitions(sys.argv[2])
        print(json.dumps(pts, indent=2))
    elif cmd == "cut":
        if len(sys.argv) < 5:
            sys.exit(1)
        dry = "--dry-run" in sys.argv
        ok, msg = cut_partition(sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), dry_run=dry)
        print(f"Status: {ok} | {msg}")
    elif cmd == "merge":
        if len(sys.argv) < 5:
            sys.exit(1)
        dry = "--dry-run" in sys.argv
        ok, msg = merge_partitions(sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), dry_run=dry)
        print(f"Status: {ok} | {msg}")
