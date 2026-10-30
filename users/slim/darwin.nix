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
      cleanup = "none";
    };
    taps = [
      "jganoff/tap"
    ];
    casks  = [
      "ghostty"
      "discord"
      "slack"
      "claude-code"
      "1password-cli"
      "alfred"
      "logseq"
      "migsilva89/imark/imark"
    ];
    brews = [
      "bash"
      "pinentry-mac"
      "jganoff/tap/wsp"
      "gh"
      "opencode"
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
