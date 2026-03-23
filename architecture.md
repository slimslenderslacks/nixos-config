# Repository Architecture

This is a fork/adaptation of Mitchell Hashimoto's nixos-config, structured around a single flake that manages multiple machines across macOS, NixOS VMs, and WSL.

## Core Composition Model

`lib/mksystem.nix` is the central abstraction. It's a function that takes a machine name and `{ system, user, darwin, wsl }` and produces either a `darwinSystem` or `nixosSystem` by composing four layers:

```
flake.nix
  └─ mkSystem("macbook-pro-m1", { system="aarch64-darwin", user="slim", darwin=true })
       └─ mksystem.nix
            ├─ overlays (zig, gh/unstable, claude-code/unstable, secretspec/unstable)
            ├─ machines/macbook-pro-m1.nix     (hardware/machine specifics)
            ├─ users/slim/darwin.nix           (macOS OS-level config)
            └─ users/slim/home-manager.nix     (user packages + dotfiles)
```

## How nixpkgs Works on macOS

macOS doesn't run NixOS — there's no init system or service manager managed by Nix. Instead, **nix-darwin** (`github:nix-darwin/nix-darwin`) acts as the macOS equivalent, providing:

- A `darwin-rebuild switch` command analogous to `nixos-rebuild switch`
- Module system for macOS system configuration
- Integration points for Homebrew, system defaults, launchd services
- A `system` profile at `/run/current-system` (symlinked from `/nix/var/nix/profiles/system`)

The key distinction: `nix.useDaemon = true` in `darwin.nix` means nix-darwin does **not** manage the Nix daemon installation itself. The Nix daemon is installed separately (via Determinate Systems `nix-installer` or Flox) before nix-darwin is ever invoked.

Homebrew is also managed declaratively from `darwin.nix` — casks (`ghostty`, `google-chrome`, `1password`, etc.) and brews (`gh`, `pinentry-mac`, `opencode`, etc.) are specified there, and nix-darwin runs `brew` during activation to reconcile them.

## Bootstrapping a New macOS Host

1. **Install Nix** (with flakes): Use [Determinate Systems nix-installer](https://github.com/DeterminateSystems/nix-installer) or Flox. This installs the Nix daemon and creates `/nix`.

2. **Clone the repo** and run:
   ```bash
   NIXNAME=macbook-pro-m1 make
   ```

3. `make switch` on Darwin runs:
   ```bash
   # Step 1: Build the system closure
   NIXPKGS_ALLOW_UNFREE=1 nix build --impure \
     --experimental-features "nix-command flakes" \
     ".#darwinConfigurations.macbook-pro-m1.system"

   # Step 2: Activate it
   sudo NIXPKGS_ALLOW_UNFREE=1 \
     ./result/sw/bin/darwin-rebuild switch --impure \
     --flake "$(pwd)#macbook-pro-m1"
   ```

   `darwin-rebuild` is bootstrapped from the build result itself (`./result/sw/bin/darwin-rebuild`) — you don't need it pre-installed. This is how the first activation works before nix-darwin is on PATH.

## How the Environment Becomes Active: The PATH Story

There are four distinct PATH layers that compose the final shell environment.

### Layer 1: Nix daemon bootstrap (one-time, from nix-installer)

The Determinate Systems installer creates `/etc/zshrc.d/nix.sh` (or patches `/etc/zshenv`) that sources:
```
/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```
This puts the `nix` CLI itself on PATH (`/nix/var/nix/profiles/default/bin`). This layer runs before any nix-darwin or home-manager config.

### Layer 2: nix-darwin system activation

When `darwin-rebuild switch` runs, it:
- Builds the full system closure into `/nix/store/...`
- Creates `/run/current-system` pointing to that store path
- Creates `/run/current-system/sw` as an aggregated view of all system packages
- Patches `/etc/zshrc` and `/etc/bashrc` to source the nix-darwin shell setup

This puts `/run/current-system/sw/bin` on PATH, making all `environment.systemPackages` available.

### Layer 3: home-manager user packages

With `home-manager.useUserPackages = true`, home-manager installs packages into:
```
/nix/var/nix/profiles/per-user/slim/profile
```
And symlinks it as `~/.nix-profile`. The home-manager activation (run during `darwin-rebuild switch`) prepends `~/.nix-profile/bin` to PATH.

### Layer 4: bashrc (manual additions)

`users/slim/bashrc` (written to `~/.bashrc` by home-manager via `programs.bash.initExtra`) adds:
```bash
export PATH=~/go/bin:~/.local/bin/:/opt/homebrew/bin:$PATH
```
This handles Go binaries, local scripts, and Homebrew's prefix (`/opt/homebrew/bin` on Apple Silicon).

### Full PATH at runtime (conceptual order)

```
~/go/bin
~/.local/bin
/opt/homebrew/bin                      <- Homebrew packages (pinentry-mac, opencode, etc.)
~/.nix-profile/bin                     <- home-manager packages (fzf, ripgrep, nvim, etc.)
/run/current-system/sw/bin             <- nix-darwin system packages
/nix/var/nix/profiles/default/bin      <- nix CLI itself
/usr/local/bin, /usr/bin, /bin         <- macOS base system
```

### Key activation files (written by nix-darwin into `/etc`)

| File | Purpose |
|---|---|
| `/etc/bashrc` | Sourced by bash; sets up Nix environment |
| `/etc/zshrc` | Sourced by zsh; same |
| `/etc/static/` | Symlinked from the Nix store; actual content of nix-darwin-managed `/etc` files |
| `/run/current-system` | Symlink to the active system generation |

## The Two-Track Package System

| Mechanism | Where packages live | Activated by |
|---|---|---|
| Nix / home-manager | `/nix/store`, linked via `~/.nix-profile` | Shell rc files patched by nix-darwin |
| Homebrew (declarative) | `/opt/homebrew` | Managed by nix-darwin's homebrew module, always on PATH via bashrc |

The design uses both because some macOS GUI apps (`.app` bundles) and certain tools with macOS-specific requirements work better via Homebrew casks, while the bulk of the CLI development environment is managed purely through nixpkgs.

## Darwin Build Graph

```mermaid
graph LR
    FlakeLock(["flake.lock"])
    FlakeLock -->|pins| FlakeNix

    subgraph ExternalInputs["flake inputs (external)"]
        direction TB

        subgraph NixpkgsGroup["nixpkgs"]
            direction TB
            Nixpkgs["nixpkgs 25.05"]
            NixpkgsUnstable["nixpkgs-unstable"]
        end

        subgraph DarwinGroup["darwin tooling"]
            direction TB
            NixDarwin["nix-darwin 25.05"]
            HomeManagerFlake["home-manager 25.05"]
        end

        subgraph ToolsGroup["tools"]
            direction TB
            ZigOverlay["zig overlay"]
            Dagger["dagger"]
            Ghostty["ghostty"]
            NeovimNightly["neovim-nightly-overlay"]
            Beads["beads"]
        end

        subgraph VimPluginsGroup["neovim plugins"]
            direction TB
            VimPlugins["conform · dressing · gitsigns\nlspconfig · lualine · nui\nplenary · telescope · web-devicons\nvim-marked"]
        end
    end

    subgraph Repo["nixos-config repository"]
        direction TB

        FlakeNix["flake.nix"]

        subgraph LibGroup["lib/"]
            direction TB
            MkSystem["mksystem.nix"]
            OverlaysLib["overlays.nix"]
        end

        subgraph MachinesGroup["machines/"]
            direction TB
            MbpM1["macbook-pro-m1.nix"]
            MbpX86["macbook-pro-x86.nix"]
        end

        subgraph UsersGroup["users/slim/"]
            direction TB
            DarwinUser["darwin.nix"]
            HomeManager["home-manager.nix"]
            VimOverlay["vim.nix"]
        end

        subgraph OverlaysGroup["overlays/"]
            direction TB
            OverlaysDefault["default.nix"]
            OverlaysGo["go.nix"]
            OverlaysBuildpack["buildpack.nix"]
        end

        subgraph NixSources["nix/"]
            direction TB
            SourcesNix["sources.nix"]
            SourcesJson["sources.json"]
        end
    end

    subgraph DarwinOutput["darwin system output"]
        direction TB
        MacbookM1["darwinConfigurations.macbook-pro-m1"]
        MacbookX86["darwinConfigurations.macbook-pro-x86"]
    end

    %% Entry point wiring
    FlakeNix -->|"calls mkSystem(darwin=true)"| MkSystem
    FlakeNix -->|"passes inputs"| MkSystem

    %% mkSystem orchestration
    MkSystem -->|"imports machine config"| MbpM1
    MkSystem -->|"imports machine config"| MbpX86
    MkSystem -->|"imports user OS config"| DarwinUser
    MkSystem -->|"imports via home-manager"| HomeManager
    MkSystem -->|"applies overlays"| OverlaysLib
    MkSystem -->|"uses darwinSystem"| NixDarwin
    MkSystem -->|"uses home-manager module"| HomeManagerFlake

    %% overlays.nix auto-loads overlays/
    OverlaysLib -->|"auto-loads"| OverlaysDefault
    OverlaysLib -->|"auto-loads"| OverlaysGo
    OverlaysLib -->|"auto-loads"| OverlaysBuildpack

    %% darwin.nix imports
    DarwinUser -->|"imports"| OverlaysLib
    DarwinUser -->|"imports"| VimOverlay

    %% home-manager.nix imports
    HomeManager -->|"imports"| SourcesNix
    HomeManager -->|"uses"| NeovimNightly
    HomeManager -->|"uses"| Dagger

    %% vim overlay imports
    VimOverlay -->|"sources plugins from"| VimPlugins
    VimOverlay -->|"sources plugins from"| SourcesNix

    %% nix sources
    SourcesNix -->|"reads"| SourcesJson

    %% flake inputs used by overlays
    FlakeNix -->|"applies"| ZigOverlay
    FlakeNix -->|"applies"| NixpkgsUnstable
    FlakeNix -->|"uses"| Ghostty
    FlakeNix -->|"uses"| Beads

    %% nixpkgs base
    MkSystem -->|"resolves packages from"| Nixpkgs

    %% outputs
    MkSystem -->|"produces"| MacbookM1
    MkSystem -->|"produces"| MacbookX86

    %% Styles — primary containers
    style Repo fill:#E5F2FC,stroke:#1D63ED,color:#00084D
    style ExternalInputs fill:#fff7f0,stroke:#d4915e,color:#00084D
    style DarwinOutput fill:#f0faf4,stroke:#86c5a0,color:#00084D

    %% Styles — secondary containers
    style LibGroup fill:#f0f7ff,stroke:#7aaede,color:#00084D
    style MachinesGroup fill:#f0f7ff,stroke:#7aaede,color:#00084D
    style UsersGroup fill:#f0f7ff,stroke:#7aaede,color:#00084D
    style OverlaysGroup fill:#f0f7ff,stroke:#7aaede,color:#00084D
    style NixSources fill:#f0f7ff,stroke:#7aaede,color:#00084D

    %% Styles — external subgroups
    style NixpkgsGroup fill:#fff7f0,stroke:#d4915e,color:#00084D
    style DarwinGroup fill:#fff7f0,stroke:#d4915e,color:#00084D
    style ToolsGroup fill:#fff7f0,stroke:#d4915e,color:#00084D
    style VimPluginsGroup fill:#fff7f0,stroke:#d4915e,color:#00084D

    %% Styles — entry point / interface nodes
    style FlakeNix fill:#fff,stroke:#0DB7ED,color:#384D54
    style FlakeLock fill:#fff,stroke:#1D63ED,color:#00084D

    %% Styles — lib nodes (implementation)
    style MkSystem fill:#E5F2FC,stroke:#0DB7ED,color:#384D54
    style OverlaysLib fill:#E5F2FC,stroke:#0DB7ED,color:#384D54

    %% Styles — machine nodes
    style MbpM1 fill:#E5F2FC,stroke:#1D63ED,color:#00084D
    style MbpX86 fill:#E5F2FC,stroke:#1D63ED,color:#00084D

    %% Styles — user nodes
    style DarwinUser fill:#e0f2e6,stroke:#6db88a,color:#384D54
    style HomeManager fill:#e0f2e6,stroke:#6db88a,color:#384D54
    style VimOverlay fill:#e0f2e6,stroke:#6db88a,color:#384D54

    %% Styles — overlay nodes
    style OverlaysDefault fill:#f8fbff,stroke:#9fc5e8,color:#00084D
    style OverlaysGo fill:#f8fbff,stroke:#9fc5e8,color:#00084D
    style OverlaysBuildpack fill:#f8fbff,stroke:#9fc5e8,color:#00084D

    %% Styles — nix source nodes
    style SourcesNix fill:#f8fbff,stroke:#9fc5e8,color:#00084D
    style SourcesJson fill:#f8fbff,stroke:#9fc5e8,color:#00084D

    %% Styles — external nodes
    style Nixpkgs fill:#fff0e5,stroke:#d4915e,color:#384D54
    style NixpkgsUnstable fill:#fff0e5,stroke:#d4915e,color:#384D54
    style NixDarwin fill:#fff0e5,stroke:#d4915e,color:#384D54
    style HomeManagerFlake fill:#fff0e5,stroke:#d4915e,color:#384D54
    style ZigOverlay fill:#fff0e5,stroke:#d4915e,color:#384D54
    style Dagger fill:#fff0e5,stroke:#d4915e,color:#384D54
    style Ghostty fill:#fff0e5,stroke:#d4915e,color:#384D54
    style NeovimNightly fill:#fff0e5,stroke:#d4915e,color:#384D54
    style Beads fill:#fff0e5,stroke:#d4915e,color:#384D54
    style VimPlugins fill:#fff0e5,stroke:#d4915e,color:#384D54

    %% Styles — output nodes
    style MacbookM1 fill:#e0f2e6,stroke:#6db88a,color:#384D54
    style MacbookX86 fill:#e0f2e6,stroke:#6db88a,color:#384D54
```
