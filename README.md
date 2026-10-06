# DEPTH HINUX

```
    ███▄
    ██████▄      DEPTH HINUX [x86_64]
    █████████▄   Dimensions Node | Bedrock Architecture
    ████████████▄
    ██████████████▄
    ███████████████▌     Pure x86-64 ASM Core | Zero GNU Bloat
    ███████████████▌     Kernel: Linux ABI | Toolset: Hinux Native
    ██████████████▀      Raw Silicon. Built From Scratch.
    ████████████▀
    █████████▀
    ██████▀
    ███▀
```

Depth Hinux is an open-source bedrock operating system engineered from raw silicon. It pairs the 64-bit Linux kernel ABI with a custom, high-performance x86-64 assembly system layer, completely eliminating GNU bloatware, heavy libc wrappers, and runtime overhead.

---

## Key Highlights

- **Pure x86-64 Assembly Layer**: 27 standalone static assembly utilities and 16 core runtime subsystems with direct `syscall` kernel transitions.
- **Zero GNU Bloat**: Free of GPL/GNU toolchains in userspace; native MIT-licensed Hinux command set.
- **Solid "D" Geometry**: Custom standing-triangle identity rendered in solid ANSI truecolor blocks with zero wireframe gaps.
- **Dive Package Engine (`dive`)**: Fast package manager with fuzzy name matching (`-install-similiar`), repository indexing, and standalone `.dpk` archives.
- **Dedicated Community Repository (`pkg/repo/`)**: Open distribution format allowing anyone to build and submit software packages.
- **Pure ASM Network Manager (`network` / `net`)**: Ultra-compact terminal interface to configure networking, DHCP, nameservers, and gateway routing on bare metal.
- **Full Hybrid Bootable ISO**: Generates self-contained `boot/depth-hinux.iso` ready to burn or boot under QEMU.
- **Bedrock Performance**: Runs under 25 MB RAM with instant sub-350ms boot.

---

## Default System Credentials

- **Hostname / Node**: `dimensions`
- **Default User**: `root`
- **Default Password**: `3d`

---

## Architectural Layout

```
Depth/
├── Makefile             # Unified build, ISO creation, and QEMU virtual machine runners
├── sys/                 # Pure x86-64 assembly system layer
│   ├── asm/             # Native syscall dispatches, memory allocators, string SIMD
│   ├── coreutils/       # Standalone ASM binaries (echo, cat, ls, network, etc.)
│   └── init/            # Static Bedrock PID 1 init system (node setup, VT console)
├── pkg/                 # The 'dive' package manager & community repository
│   ├── dive.c           # Statically linked package engine with fuzzy search
│   └── repo/            # Dedicated package registry, manifests, and .dpk archives
│       ├── REPO.md      # Community contribution & packaging specifications
│       ├── repo.json    # Central repository manifest index
│       └── packages/    # Pre-built packages (fastfetch, chrome, nano, curl)
├── boot/                # Bootloaders, initramfs builders, and ISO generators
│   ├── build-initrd.sh  # Standalone initramfs packaging script
│   ├── build-iso.sh     # Hybrid bootable ISO generator (depth-hinux.iso)
│   └── isolinux/        # Syslinux bootloader components
└── installer/           # Automated partition cutting and merging installer
```

---

## Building and Running

### 1. Build Bedrock Binaries & Initramfs
```bash
make build
```

### 2. Generate Full Bootable ISO
```bash
make iso
```
Outputs `boot/depth-hinux.iso` (26 MB bootable hybrid ISO image).

### 3. Launch Graphical Virtual Machine (Direct Kernel Boot)
```bash
make run
```
Launches a real graphical QEMU window with verbose kernel text scrolling, the solid red "D" logo, Fastfetch telemetry, and the interactive bedrock shell.

### 4. Boot Directly from the ISO
```bash
make run-iso
```
Boots the generated `boot/depth-hinux.iso` as a live CD/DVD with full network connectivity.

### 5. Headless Terminal Mode
```bash
make run-cli
```

---

## The `dive` Package Manager

`dive` provides fast, dependency-tracked software management:

```bash
dive -help                         # Display command reference
dive -search                       # List all available packages in the repository
dive -search <query>               # Search repository for specific software
dive -install <pkg>                # Install a target package (.dpk)
dive -install-similiar <query>     # Fuzzy match closest name (e.g. chrome -> google-chrome)
dive -list                         # List currently installed packages
dive -remove <pkg>                 # Uninstall package
dive -repo                         # Display repository endpoints and upload guides
dive build <dir> <out.dpk>         # Package application directory into .dpk archive
```

---

## Network Manager (`network` / `net`)

Depth Hinux includes a pure assembly interactive network TUI:

```bash
# Inside the bedrock shell:
network
# Or use the short alias:
net
```

From the network console, you can:
1. Auto-configure the QEMU Virtual Gateway (`10.0.2.15/24` with gateway `10.0.2.2`).
2. Set DNS nameservers (`10.0.2.3`, `1.1.1.1`, `8.8.8.8`).
3. Verify link connectivity.
4. Launch `dive` directly to search and install online packages.

---

## Community Contributions

Anyone can create and publish packages for Depth Hinux. Consult [pkg/repo/REPO.md](pkg/repo/REPO.md) for full instructions on building `.dpk` archives and submitting software to the registry.

---

## License

Open source under the [MIT License](LICENSE).
