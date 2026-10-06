# DEPTH HINUX

```
    ███▄
    ██████▄      DEPTH HINUX [x86_64]
    █████████▄   Dimensions Node | Bedrock Architecture
    ████████████▄
    ██████████████▄
    ███████████████▌     88.1% Pure ASM Core | Zero GNU Bloat
    ███████████████▌     Kernel: Hinux ASM Microvisor & Linux ABI
    ██████████████▀      Raw Silicon. Built From Scratch.
    ████████████▀
    █████████▀
    ██████▀
    ███▀
```

Depth Hinux is an open-source bedrock operating system engineered from raw silicon. It replaces traditional monolithic kernel components with a custom, high-performance x86-64 assembly system architecture (**88.1% Pure ASM Core**), completely eliminating GNU bloatware, heavy libc wrappers, and runtime overhead.

---

## Key Highlights

- **88.1% Pure x86-64 Assembly Layer**: 4,999 lines of pure assembly across standalone coreutils, runtime subsystems, and the bare-metal kernel core.
- **Bare-Metal Hinux Kernel (`sys/kernel/`)**: Handcrafted 64-bit microkernel written entirely in assembly:
  - 32-to-64-bit Long Mode Multiboot trampoline and initial PML4 paging.
  - 64-bit Interrupt Descriptor Table (IDT) with 256 gates and PIC remapping.
  - Physical memory frame bitmap allocator (4 KB pages).
  - Preemptive Round-Robin Task Scheduler and 64-bit context switcher.
  - MSR `LSTAR` (0xC0000082) hardware syscall trap dispatcher handling native system calls directly from Ring 3.
  - Direct memory-mapped VGA text buffer driver (`0xB8000`) and serial COM1 driver (`0x3F8`).
- **Zero GNU Bloat**: Free of GPL/GNU toolchains in userspace; native MIT-licensed Hinux command set.
- **Solid "D" Geometry**: Custom standing-triangle identity rendered in solid ANSI truecolor blocks with zero wireframe gaps.
- **Dive Package Engine (`dive`)**: Fast package manager with fuzzy name matching (`-install-similiar`), repository indexing, and standalone `.dpk` archives.
- **Dedicated Community Repository (`pkg/repo/`)**: Open distribution format allowing anyone to build and submit software packages.
- **Pure ASM Network Manager (`network` / `net`)**: Ultra-compact terminal interface to configure networking, DHCP, nameservers, and gateway routing on bare metal.
- **Dual Boot Execution**: Boot either directly onto the pure assembly microkernel or boot the hybrid distribution ISO under QEMU.

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
├── sys/                 # 88.1% Pure x86-64 assembly system layer
│   ├── kernel/          # 100% Pure assembly microkernel (boot, IDT, MM, sched, syscall)
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

### 1. Boot Pure ASM Hinux Kernel on Bare Metal (QEMU)
```bash
make run-kernel
```
Boots the 100% pure assembly Hinux microkernel (`sys/kernel/hinux-kernel.bin`) directly on bare metal without any Linux C code, initializing long mode, paging, IDT, syscall MSRs, and the solid red "D" console.

### 2. Generate Full Hybrid Bootable ISO
```bash
make iso
```
Outputs `boot/depth-hinux.iso` (25 MB bootable hybrid ISO image).

### 3. Boot Directly from the Hybrid ISO
```bash
make run-iso
```
Boots `boot/depth-hinux.iso` as a live CD/DVD with virtual user networking and the bedrock userland.

### 4. Direct Kernel Boot with Verbose Scrolling
```bash
make run
```

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
