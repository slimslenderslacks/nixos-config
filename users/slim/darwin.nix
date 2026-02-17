{ inputs, pkgs, ... }:

{
  nixpkgs.overlays = import ../../lib/overlays.nix ++ [
    (import ./vim.nix { inherit inputs; })
  ];

  system.primaryUser="slim";

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
    casks  = [
      "ghostty"
      "google-chrome"
      "1password"
      "alfred"
      "cleanshot"
      "discord"
      "slack"
      "claude-code"
    ];
    brews = [
      "bash"
      "pinentry-mac"
    ];
  };

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.slim = {
    home = "/Users/slim";
    shell = pkgs.bashInteractive;
  };

  # Required for some settings like homebrew to know what user to apply to.
  # system.primaryUser = "slim";
}
