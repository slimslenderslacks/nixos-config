{ pkgs, inputs, ... }:

{
  # https://github.com/nix-community/home-manager/pull/2408
  # environment.pathsToLink = [ "/share/fish" ];
  
  users.users.root = {
    home = "/root";
    shell = pkgs.bash;
    initialPassword = "root";
  };

  users.users."jim.clark" = {
    isNormalUser = true;
    home = "/home/jim.clark";
    extraGroups = [ "docker" "wheel" ];
    shell = pkgs.bash;
    hashedPassword = "$y$j9T$u.SWHx4zUkOLom7/DFb46/$kxgTbtU8RuoAlb3CzMrWaJHXz5b0P5VCIQrjZcccSY/";
  };

  nixpkgs.overlays = import ../../lib/overlays.nix ++ [
    (import ./vim.nix {inherit inputs;})
  ];
}
