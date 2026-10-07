# DEPTH HINUX

```
    ███▄
    ██████▄      DEPTH HINUX [x86_64]
    █████████▄   Dimensions Node | Bedrock Architecture
    ████████████▄
    ██████████████▄
    ███████████████▌     Pure ASM Core | Zero GNU Bloat
    ███████████████▌     Kernel: Hinux ASM Microvisor & Linux ABI
    ██████████████▀      Filesystem: X1 Encrypted Fast Block FS
    ████████████▀        Privilege Layer: rac (Root Actions)
    █████████▀           Package Engine: dive (Cloud DPK)
    ██████▀              Bootloader: Depth Hinux ASM / UEFI 64-bit
    ███▀
```

Depth Hinux is an open-source bedrock operating system engineered from raw silicon. It replaces traditional bloated userland components with a custom, ultra-fast x86-64 assembly system architecture, completely eliminating GNU bloatware, heavy libc wrappers, and runtime overhead.

---

## Key Highlights

- **Pure x86-64 Assembly Layer**: Standalone pure assembly coreutils, driver daemons, partitioners, filesystem tools, bootloader, and microkernel.
- **Dual Boot Architecture (MBR / CSM & GPT / UEFI)**:
  - **MBR Mode (CSM / Legacy BIOS)**: Powered by Depth Hinux's custom pure assembly bootloader (`sys/bootloader/depth-boot.asm`), replacing legacy ISOLINUX with native bedrock boot code.
  - **GPT Mode (UEFI 64-bit)**: Native UEFI support with EFI System Partition (`/EFI/BOOT/BOOTX64.EFI`), fully bootable on modern UEFI firmware and physical hardware.
- **Custom X1 Filesystem (`x1fs`)**: Depth Hinux's proprietary encrypted filesystem (`0x58314653 [X1FS]`) engineered for maximum I/O throughput and hardware-accelerated encryption (`mkfs.x1`, `mount.x1`).
- **Root Actions Controller (`rac`)**: Dedicated pure assembly privilege escalation system replacing `sudo` (`rac <command> [args...]`).
- **Dive Package Engine (`dive`)**: Cloud-connected package manager utilizing `.dpk` (Depth Package) archives. Automatically downloads and merges split sections on-the-fly and cleans up temporary archives, preventing local disk bloat.
- **Pure Assembly Drive Partitioner (`depthpart` / `part`)**: Native x86-64 assembly MBR partition editor and disk scanner with `BLKRRPART` kernel reloading.
- **Pure Assembly Driver Daemon (`hinux-driverd`)**: Hardware telemetry monitor gathering real-time network and battery metrics into `/run/hinux/`.
- **Glare Cinnamon Desktop**: Refined desktop experience with top-positioned taskbar, an upright red triangle logo, vertically flipped diagonal wallpaper (black on top, deep crimson red on bottom), system-wide dark mode with custom Depth red icons for Nemo and system folders, dark terminal, native Mozilla Firefox, and live hardware telemetry applets (`depth-network@depth.org`, `depth-power@depth.org`).
- **Hybrid USB Flashdrive Bootable**: Generated hybrid ISO (`boot/depth-hinux.iso`) ready to burn directly to physical USB flashdrives or optical media.
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
├── sys/                 # Pure x86-64 assembly system layer
│   ├── kernel/          # Pure assembly microkernel (boot, IDT, MM, sched, syscall)
│   ├── asm/             # Syscall dispatch tables, memory allocators, string SIMD
│   ├── bootloader/      # Pure assembly El Torito & MBR bootloader (depth-boot.asm)
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
│   ├── build-iso.sh     # Hybrid bootable ISO generator for MBR and GPT UEFI
│   ├── depth-boot.bin   # Pure assembly bootloader binary
│   └── efiboot.img      # UEFI System Partition FAT32 boot image
└── installer/           # Automated hardware installer TUI (depthinstall)
```

---

## Building Depth Hinux

### Interactive Build & Target Selection

When running `make`, `make iso`, `make build`, `make bare`, or `make glare`, the build system interactively prompts for your desired edition and boot architecture:

```
Select Depth Hinux edition:
  [1] Glare (Cinnamon Desktop Environment)
  [2] Bare  (Bedrock minimal CLI)
Select [1/2, default 1]:

Select bootloader architecture:
  [1] UEFI (GPT 64-bit Bootloader)
  [2] Legacy BIOS (MBR / CSM Bootloader)
Select [1/2, default 1]:
```

### Direct Automated Builds

You can bypass interactive prompts by specifying command line variables:

```bash
make bare BOOT_ARCH=mbr
make glare BOOT_ARCH=gpt
make build MODE=glare BOOT_ARCH=gpt
```

---

## Booting in QEMU

### 1. UEFI GPT Boot (Recommended for Modern Systems)
Boots using UEFI firmware (OVMF):
```bash
make run-uefi
```

### 2. MBR / CSM Legacy BIOS Boot
Boots using SeaBIOS and Depth Hinux's custom pure assembly bootloader:
```bash
make run-mbr
```

### 3. Rebuild and Boot ISO
Rebuilds the ISO image with interactive Edition and Architecture prompts, and automatically boots the resulting ISO in QEMU:
```bash
make run-iso
```

### 4. Direct Kernel Boot
Boots the Linux kernel and Depth Hinux initramfs directly:
```bash
make run
```

### 5. Pure Assembly Microkernel
Boots the native Depth Hinux assembly microkernel:
```bash
make run-kernel
```

### 6. Bedrock Serial CLI
Boots in headless terminal mode:
```bash
make run-cli
```

---

## Flashing to Physical USB Flashdrives

To create a bootable USB flashdrive for real hardware:

1. Identify your target flashdrive device path (e.g., `/dev/sdX` or `/dev/nvme0n1`).
2. Write the image directly using `rac dd`:

```bash
rac dd if=boot/depth-hinux.iso of=/dev/sdX bs=4M status=progress && sync
```

Once written:
- For **GPT / UEFI**: Insert the USB flashdrive, enter your BIOS boot menu (F12, F11, ESC, or F8), and select the UEFI USB entry.
- For **MBR / CSM**: Enable CSM / Legacy Boot in BIOS settings and select the USB drive.

---

## Root Actions (`rac`)

Depth Hinux uses `rac` instead of `sudo`:

```bash
rac dive install git
rac depthpart list
rac mkfs.x1 /dev/sda1 -L DEPTH_ROOT
rac nano /etc/hosts
```

---

## The `dive` Package Manager

`dive` provides fast, cloud-connected software management:

```bash
rac dive install <pkg>
dive search [query]
dive list
dive info <pkg>
dive verify <pkg>
rac dive remove <pkg>
dive split <file.dpk> [mb]
dive merge <file.dpk.00> [out.dpk]
dive repo-index [dir]
```

### Splitting and Cloud Hosting
GitHub enforces a 25 MB web upload limit. Large packages (such as Firefox) are split into cloud upload sections:

```bash
dive split firefox.dpk 20
```

This generates `firefox.dpk.00`, `firefox.dpk.01`, etc., which are committed to `pkg/repo/packages/`. During installation, `dive install` automatically streams and merges all sections into `/tmp`, installs the package, and immediately purges temporary files to prevent disk usage bloat.

For full packaging instructions, see [pkg/repo/README.md](pkg/repo/README.md).

---

## X1 Filesystem (`x1fs`)

Format partitions with Depth Hinux's encrypted filesystem:

```bash
rac mkfs.x1 /dev/sda1 -L DEPTH_ROOT
rac mount.x1 /dev/sda1 /mnt
```

---

## License

Open source under the [MIT License](LICENSE).
