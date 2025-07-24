{
  description = "NixOS systems and tools by mitchellh";

  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations. Be very careful changing this because
    # it'll impact your entire system.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Build a custom WSL installer
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Other packages
    zig = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # flakes
    dagger = {
      url = "github:dagger/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Non-flakes
    nvim-treesitter = {
      url = "github:nvim-treesitter/nvim-treesitter/v0.9.2";
      flake = false;
    };

    vim-copilot = {
      url = "github:github/copilot.vim/v1.47.0";
      flake = false;
    };

    vim-marked = {
      url = "github:itspriddle/vim-marked/v1.0.0";
      flake = false;
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };

    nvim-conform.url = "github:stevearc/conform.nvim/v7.1.0";
    nvim-conform.flake = false;
    nvim-dressing.url = "github:stevearc/dressing.nvim";
    nvim-dressing.flake = false;
    nvim-gitsigns.url = "github:lewis6991/gitsigns.nvim/v0.9.0";
    nvim-gitsigns.flake = false;
    nvim-lspconfig.url = "github:neovim/nvim-lspconfig";
    nvim-lspconfig.flake = false;
    nvim-lualine.url ="github:nvim-lualine/lualine.nvim";
    nvim-lualine.flake = false;
    nvim-nui.url = "github:MunifTanjim/nui.nvim";
    nvim-nui.flake = false;
    nvim-plenary.url = "github:nvim-lua/plenary.nvim";
    nvim-plenary.flake = false;
    nvim-telescope.url = "github:nvim-telescope/telescope.nvim/0.1.8";
    nvim-telescope.flake = false;
    nvim-web-devicons.url = "github:nvim-tree/nvim-web-devicons";
    nvim-web-devicons.flake = false;
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }@inputs: let
    # Overlays is the list of overlays we want to apply from flake inputs.
    overlays = [
      inputs.zig.overlays.default
      (final: prev: rec {
        # gh CLI on stable has bugs.
        gh = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.gh;

        # Want the latest version of these
        claude-code = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.claude-code;
        nushell = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.nushell;
        secretspec = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.secretspec;
      })
    ];

    mkSystem = import ./lib/mksystem.nix {
      inherit overlays nixpkgs inputs;
    };
  in {
    nixosConfigurations.vm-aarch64 = mkSystem "vm-aarch64" {
      system = "aarch64-linux";
      user   = "slim";
    };

    nixosConfigurations.vm-aarch64-prl = mkSystem "vm-aarch64-prl" rec {
      system = "aarch64-linux";
      user   = "slim";
    };

    nixosConfigurations.vm-aarch64-utm = mkSystem "vm-aarch64-utm" rec {
      system = "aarch64-linux";
      user   = "mitchellh";
    };

    nixosConfigurations.vm-intel = mkSystem "vm-intel" rec {
      system = "x86_64-linux";
      user   = "slim";
    };

    nixosConfigurations.wsl = mkSystem "wsl" {
      system = "x86_64-linux";
      user   = "slim";
      wsl    = true;
    };

    darwinConfigurations.macbook-pro-m1 = mkSystem "macbook-pro-m1" {
      system = "aarch64-darwin";
      user   = "slim";
      darwin = true;
    };

    darwinConfigurations.macbook-pro-x86 = mkSystem "macbook-pro-x86" {
      system = "x86_64-darwin";
      user   = "slim";
      darwin = true;
    };
  };
}
