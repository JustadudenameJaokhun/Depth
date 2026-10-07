# Depth Hinux - Dive Package Engine & Cloud Repository Guide

The Dive Package Manager (`dive`) is Depth Hinux's native package management and distribution system. It uses `.dpk` (Depth Package) archives with cryptographic SHA-256 verification, manifest tracking, and seamless integration with GitHub cloud hosting.

---

## 1. Cloud-Connected Architecture (Zero Storage Bloat)

To avoid consuming local disk storage, packages can be hosted directly in the cloud (GitHub).
When you install a package via `rac dive install <package>`, Dive:
1. Checks local cache (`/var/cache/dive/packages/` or `pkg/repo/packages/`).
2. If not local, automatically contacts the GitHub cloud repository.
3. Downloads the required archive or chunked sections into `/tmp`.
4. Merges sections on-the-fly and verifies SHA-256 signatures.
5. Deploys the package files and records the manifest in `/var/lib/dive/installed/`.
6. Automatically wipes all temporary downloaded files from `/tmp`, keeping **0 bytes** of redundant package archives on your drive.

---

## 2. Creating a `.dpk` Package

### Step 1: Prepare the File Tree
Create a staging directory containing the files exactly as they should appear on the root filesystem:

```bash
mkdir -p myapp-build/usr/bin myapp-build/usr/share/applications
cp myapp myapp-build/usr/bin/myapp
chmod +x myapp-build/usr/bin/myapp
```

### Step 2: Define Package Metadata (`dpk.meta`)
Create `dpk.meta` inside the staging folder:

```ini
name=myapp
version=1.0.0
arch=x86_64
maintainer=Depth Community
description=High performance utility for Depth Hinux
```

### Step 3: Compile the Archive
Run `dive build`:

```bash
dive build myapp-build myapp.dpk
```

---

## 3. Splitting Packages for GitHub Upload Limits

GitHub enforces strict upload limits (25 MB for web upload, 100 MB for git push). If your package exceeds 20 MB (like web browsers or desktop suites), use `dive split`:

```bash
dive split myapp.dpk 20
```

This generates numbered sections:
- `myapp.dpk.00`
- `myapp.dpk.01`
- `myapp.dpk.02`

Each section is guaranteed to be under 20 MB, enabling effortless web or git uploads to GitHub without any rejections.

To manually reassemble sections:

```bash
dive merge myapp.dpk.00 myapp.dpk
```

---

## 4. Uploading Packages to the GitHub Repository

### Step 1: Place Package Files in the Repository
Place your `.dpk` file (or split `.dpk.00`, `.dpk.01`, etc.) into `pkg/repo/packages/`:

```bash
cp myapp.dpk* pkg/repo/packages/
```

### Step 2: Re-Index the Repository Manifest
Regenerate `pkg/repo/repo.json`:

```bash
dive repo-index pkg/repo/packages
```

### Step 3: Commit and Push to GitHub
```bash
git add pkg/repo/packages/ pkg/repo/repo.json
git commit -m "Add myapp package to Dive cloud repository"
git push origin main
```

Once pushed, anyone running Depth Hinux can install your package immediately via:

```bash
rac dive install myapp
```

---

## 5. Command Reference

| Command | Description |
|---|---|
| `rac dive install <pkg>` | Install a package from local repository or GitHub cloud |
| `dive search <query>` | Query the repository index and available packages |
| `dive list` | Show all currently installed packages |
| `dive info <pkg>` | Display package metadata and tracked files |
| `dive verify <pkg>` | Verify filesystem integrity of installed files |
| `dive remove <pkg>` | Cleanly unlink and uninstall all package files |
| `dive build <dir> [out.dpk]` | Build a directory into a `.dpk` archive |
| `dive split <pkg.dpk> [mb]` | Split a large package into cloud upload sections |
| `dive merge <pkg.dpk.00> [out]`| Merge cloud sections into a single `.dpk` |
| `dive repo-index [dir]` | Re-index packages into `repo.json` |
