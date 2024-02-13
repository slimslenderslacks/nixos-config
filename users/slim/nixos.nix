{ pkgs, inputs, ... }:

{
  # https://github.com/nix-community/home-manager/pull/2408
  # environment.pathsToLink = [ "/share/fish" ];
  
  users.users.root = {
    home = "/root";
    shell = pkgs.bash;
    initialPassword = "root";
  };

  users.users.slim = {
    isNormalUser = true;
    home = "/home/slim";
    extraGroups = [ "docker" "wheel" ];
    shell = pkgs.bash;
    hashedPassword = "$y$j9T$u.SWHx4zUkOLom7/DFb46/$kxgTbtU8RuoAlb3CzMrWaJHXz5b0P5VCIQrjZcccSY/";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbTIKIPtrymhvtTvqbU07/e7gyFJqNS4S0xlfrZLOaY mitchellh"
    ];
  };

  nixpkgs.overlays = import ../../lib/overlays.nix ++ [
    (import ./vim.nix {inherit inputs;})
  ];
}
