# DEPTH HINUX

```
    ███▄
    ██████▄      DEPTH HINUX [x86_64]
    █████████▄   Dimensions Node | Bedrock Architecture
    ████████████▄
    ██████████████▄
    ███████████████▌     95.1% Pure ASM Core | Zero GNU Bloat
    ███████████████▌     Kernel: Hinux ASM Microvisor & Linux ABI
    ██████████████▀      Filesystem: X1 Encrypted Fast Block FS
    ████████████▀        Privilege Layer: rac (Root Actions)
    █████████▀           Package Engine: dive (Cloud DPK)
    ██████▀
    ███▀
```

Depth Hinux is an open-source bedrock operating system engineered from raw silicon. It replaces traditional bloated userland components with a custom, ultra-fast x86-64 assembly system architecture (**95.1% Pure ASM Core**), completely eliminating GNU bloatware, heavy libc wrappers, and runtime overhead.

---

## Key Highlights

- **95.1% Pure x86-64 Assembly Layer**: Standalone pure assembly coreutils, driver daemons, partitioners, filesystem tools, bootloader, and microkernel.
- **Custom X1 Filesystem (`x1fs`)**: Depth Hinux's proprietary encrypted filesystem (`0x58314653 [X1FS]`) engineered for maximum I/O throughput and hardware-accelerated encryption (`mkfs.x1`, `mount.x1`).
- **Root Actions Controller (`rac`)**: Dedicated pure assembly privilege escalation system replacing `sudo` (`rac <command> [args...]`).
- **Dive Package Engine (`dive`)**: Cloud-connected package manager utilizing `.dpk` (Depth Package) archives. Automatically downloads and merges split sections on-the-fly and cleans up temporary archives, preventing local disk bloat.
- **Pure Assembly Drive Partitioner (`depthpart` / `part`)**: Native x86-64 assembly MBR partition editor and disk scanner with `BLKRRPART` kernel reloading.
- **Pure Assembly Driver Daemon (`hinux-driverd`)**: Hardware telemetry monitor gathering real-time network and battery metrics into `/run/hinux/`.
- **Glare Cinnamon Desktop**: Refined desktop experience with an upright red triangle logo, smooth red-to-black diagonal wallpaper, native Mozilla Firefox, Nemo file manager, and custom taskbar applets (`depth-network@depth.org`, `depth-power@depth.org`).
- **Hybrid USB Flashdrive Bootable**: Generated hybrid ISO (`boot/depth-hinux.iso`) with pure assembly MBR bootloader (`depth-boot`), ready to burn and boot on physical USB flashdrives or optical media.
- **Bedrock Hardware Installer TUI (`depthinstall`)**: Full interactive color TUI with block device discovery, automated X1 encrypted formatting, and live deployment progress bars.

---

## Default System Credentials

- **Hostname / Node**: `dimensions`
- **Default User**: `root`
- **Default Password**: `3d`
- **Terminal Prompt**: `depth-hinux ~/ # ` (Red ANSI truecolor branding)

---

## Architectural Layout

```
Depth/
├── Makefile             # Unified build, ISO creation, and QEMU virtual machine runners
├── sys/                 # 95.1% Pure x86-64 assembly system layer
│   ├── kernel/          # 100% Pure assembly microkernel (boot, IDT, MM, sched, syscall)
│   ├── asm/             # Syscall dispatch tables, memory allocators, string SIMD
│   ├── bootloader/      # Pure assembly hybrid MBR bootloader (depth-boot.asm)
│   ├── coreutils/       # Standalone ASM binaries (rac, mkfs.x1, mount.x1, depthpart, hinux-driverd, etc.)
│   ├── glare/           # Glare Cinnamon session launcher, theme, and custom applets
│   └── init/            # Static Bedrock PID 1 init system (mounting, networking, console)
├── pkg/                 # The 'dive' package manager & community cloud repository
│   ├── dive.c           # High-speed package engine with cloud fetch, split, and merge
│   └── repo/            # Dedicated package registry, manifests, and .dpk archives
│       ├── README.md    # DPK creation, section splitting, and cloud upload guide
│       ├── repo.json    # Central repository manifest index
│       └── packages/    # Pre-built packages (git, fastfetch, nano, curl, etc.)
├── boot/                # Bootloaders, initramfs builders, and ISO generators
│   ├── build-initrd.sh  # Optimized initramfs packaging script (gzip -9)
│   ├── build-iso.sh     # Hybrid bootable ISO generator with MBR injection
│   └── depth-boot.bin   # Pure assembly hybrid MBR bootloader sector
└── installer/           # Automated hardware installer TUI (depthinstall)
```

---

## Building and Running

### 1. Compile Everything
```bash
make
```

### 2. Generate Hybrid Flashdrive-Bootable ISO
```bash
make iso
```
Outputs `boot/depth-hinux.iso`.

### 3. Flash to Physical USB Flashdrive
To boot on physical hardware, flash directly using `dd`:
```bash
rac dd if=boot/depth-hinux.iso of=/dev/sdX bs=4M status=progress && sync
```
*(Replace `/dev/sdX` with your target USB flashdrive device path).*

### 4. Boot in QEMU Virtual Machine
- **Graphical Glare Desktop**:
  ```bash
  make run
  ```
- **Live Hybrid ISO Boot**:
  ```bash
  make run-iso
  ```
- **Bedrock Pure ASM Kernel**:
  ```bash
  make run-kernel
  ```
- **Headless Terminal Mode**:
  ```bash
  make run-cli
  ```

---

## Root Actions (`rac`)

Depth Hinux uses `rac` instead of `sudo`:

```bash
# Authorize administrative actions:
rac dive install git
rac depthpart list
rac mkfs.x1 /dev/sda1 -L DEPTH_ROOT
rac nano /etc/hosts
```

---

## The `dive` Package Manager

`dive` provides fast, cloud-connected software management:

```bash
rac dive install <pkg>             # Install package from local cache or GitHub cloud
dive search [query]                # Search available packages in the repository
dive list                          # List installed packages on the system
dive info <pkg>                    # Inspect package metadata and tracked files
dive verify <pkg>                  # Verify disk integrity of installed files
rac dive remove <pkg>              # Cleanly remove package and unregister manifest
dive split <file.dpk> [mb]         # Split large archive into GitHub upload sections
dive merge <file.dpk.00> [out.dpk] # Reassemble sections into complete archive
dive repo-index [dir]              # Re-index packages into repo.json
```

For full instructions on creating `.dpk` packages, section chunking, and publishing to GitHub, see [pkg/repo/README.md](pkg/repo/README.md).

---

## X1 Filesystem (`x1fs`)

Format partitions with Depth Hinux's encrypted filesystem:

```bash
# Format block device with X1 encrypted filesystem:
rac mkfs.x1 /dev/sda1 -L DEPTH_ROOT
# Or use the x1-format alias:
rac x1-format /dev/vda1 -L DEPTH_ROOT

# Mount X1 device:
rac mount.x1 /dev/sda1 /mnt
```

---

## License

Open source under the [MIT License](LICENSE).
