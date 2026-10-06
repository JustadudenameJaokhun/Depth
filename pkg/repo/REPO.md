# Dive Community Package Repository

Welcome to the official repository specification for the Depth Hinux `dive` package engine.

## Repository Layout
```
pkg/repo/
├── repo.json          Package registry index and manifest metadata
├── packages/          Pre-built .dpk distribution archives
│   ├── depth-base.dpk
│   ├── depth-sh.dpk
│   ├── fastfetch.dpk
│   ├── google-chrome.dpk
│   ├── nano.dpk
│   ├── curl.dpk
│   └── rare-desktop.dpk
└── recipes/           Package recipes and build blueprints
```

## How to Package an Application (.dpk)

A `.dpk` package is a standardized, high-speed gzip-compressed tar archive containing the binary payload for Depth Hinux:

1. Prepare your application payload directory:
```bash
mkdir -p myapp_payload/bin
cp myapp myapp_payload/bin/
```

2. Compile into a `.dpk` archive using `dive`:
```bash
dive build myapp_payload myapp.dpk
```

3. Test local installation:
```bash
dive -install myapp.dpk
```

## How to Submit / Upload Applications
1. Place your `.dpk` archive in `pkg/repo/packages/`.
2. Add the package metadata entry to `pkg/repo/repo.json`.
3. Submit a pull request to the upstream repository.
4. Users can now search and install your application:
```bash
dive -search myapp
dive -install myapp
dive -install-similiar myapp
```
