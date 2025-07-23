{ isWSL, inputs, ... }:

{ config, lib, pkgs, ... }:

let
  sources = import ../../nix/sources.nix;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # For our MANPAGER env var
  # https://github.com/sharkdp/bat/issues/1145
  manpager = (pkgs.writeShellScriptBin "manpager" (if isDarwin then ''
    sh -c 'col -bx | bat -l man -p'
    '' else ''
    cat "$1" | col -bx | bat --language man --style plain
  ''));
in {
  # Home-manager 22.11 requires this be set. We never set it so we have
  # to use the old state version.
  home.stateVersion = "18.09";

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using
  # per-project flakes sourced with direnv and nix-shell, so this is
  # not a huge list.
  home.packages = [
    pkgs._1password
    pkgs.curl
    pkgs.fd
    pkgs.htop
    pkgs.watch
    pkgs.clojure-lsp pkgs.temurin-bin pkgs.leiningen pkgs.babashka
    pkgs.figlet pkgs.toilet
    pkgs.grype pkgs.hadolint
    pkgs.graphviz
    pkgs.screen
    pkgs.socat

    pkgs.thefuck
    pkgs.zoxide
    pkgs.tldr
    pkgs.scc
    pkgs.eza
    pkgs.lazydocker
    pkgs.procs
    pkgs.fzf
    pkgs.bat
    pkgs.jq
    pkgs.ripgrep
    pkgs.tree
    pkgs.pstree

    pkgs.gopls
    #pkgs.yaml-language-server

    # Node is required for Copilot.vim
    pkgs.nodejs
    pkgs.yarn

    # Babashka Jet
    pkgs.jet

    # GitHub
    pkgs.gh

    # Charmbracelet
    pkgs.glow
    pkgs.gum
    pkgs.vhs

    # Python dev
    #pkgs.nodePackages.pyright
    
    inputs.dagger.packages.${pkgs.system}.dagger

    # atuin
    pkgs.atuin

    # daytona is an overlay from pkgs/daytona 
    pkgs.daytonaai-bin

    # use the ghostty input
    # inputs.ghostty.packages.${pkgs.system}.default

  ] ++ (lib.optionals isDarwin [
    # This is automatically setup on Linux
    pkgs.cachix
    pkgs.tailscale
    pkgs.pngpaste
  ]) ++ (lib.optionals (isLinux && !isWSL) [
    pkgs.chromium
    pkgs.firefox
    pkgs.rofi
    pkgs.zathura
    pkgs.xfce.xfce4-terminal
  ]);

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    MANPAGER = "${manpager}/bin/manpager";
  };

  home.file.".gdbinit".source = ./gdbinit;
  home.file.".inputrc".source = ./inputrc;

  xdg.configFile."i3/config".text = builtins.readFile ./i3;
  xdg.configFile."rofi/config.rasi".text = builtins.readFile ./rofi;
  xdg.configFile."devtty/config".text = builtins.readFile ./devtty;

  # Rectangle.app. This has to be imported manually using the app.
  xdg.configFile."rectangle/RectangleConfig.json".text = builtins.readFile ./RectangleConfig.json;

  # tree-sitter parsers
  xdg.configFile."nvim/parser/proto.so".source = "${pkgs.tree-sitter-proto}/parser";
  xdg.configFile."nvim/queries/proto/folds.scm".source =
    "${sources.tree-sitter-proto}/queries/folds.scm";
  xdg.configFile."nvim/queries/proto/highlights.scm".source =
    "${sources.tree-sitter-proto}/queries/highlights.scm";
  xdg.configFile."nvim/queries/proto/textobjects.scm".source =
    ./textobjects.scm;
  xdg.configFile."ghostty/config".text = builtins.readFile ./ghostty;

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs.gpg.enable = !isDarwin;

  programs.bash = {
    enable = true;
    shellOptions = [];
    historyControl = [ "ignoredups" "ignorespace" ];
    initExtra = builtins.readFile ./bashrc;
    profileExtra = builtins.readFile ./bash_profile;
  };

  programs.starship.enable = true;
  programs.starship.settings = {
    add_newline = false;
    format = "$username$git_branch$git_status$directory$jobs$cmd_duration$character";
    shlvl = {
      disabled = true;
      symbol = "ﰬ";
      style = "bright-red bold";
    };
    shell = {
      disabled = false;
      format = "$indicator";
      fish_indicator = "";
      bash_indicator = "[BASH](bright-white) ";
      zsh_indicator = "[ZSH](bright-white) ";
    };
    username = {
      style_user = "bright-white bold";
      style_root = "bright-red bold";
    };
  };


  programs.direnv= {
    enable = true;
    nix-direnv = {
      enable = true;
      package = pkgs.nix-direnv;
    };
  };

  programs.git = {
    enable = true;
    userName = "Jim Clark";
    userEmail = "slimslenderslacks@gmail.com";
    signing = {
      key = "73305B2338AAA7BE";
      signByDefault = true;
    };
    aliases = {
      prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      root = "rev-parse --show-toplevel";
    };
    extraConfig = {
      branch.autosetuprebase = "always";
      color.ui = true;
      core.askPass = ""; # needs to be empty to use terminal for ask pass
      credential.helper = "store"; # want to make this more secure
      github.user = "slimslenderslacks";
      push.default = "tracking";
      init.defaultBranch = "main";
    };
  };

  programs.tmux = {
    enable = true;
    terminal = "xterm-256color";
    shortcut = "l";
    secureSocket = false;

    extraConfig = ''
      set -ga terminal-overrides ",*256col*:Tc"

      set -g @dracula-show-battery false
      set -g @dracula-show-network false
      set -g @dracula-show-weather false

      bind -n C-k send-keys "clear"\; send-keys "Enter"

      run-shell ${sources.tmux-pain-control}/pain_control.tmux
      run-shell ${sources.tmux-dracula}/dracula.tmux
    '';
  };

  programs.alacritty = {
    enable = true;

    settings = {
      env.TERM = "xterm-256color";

      key_bindings = [
        { key = "K"; mods = "Command"; chars = "ClearHistory"; }
        { key = "V"; mods = "Command"; action = "Paste"; }
        { key = "C"; mods = "Command"; action = "Copy"; }
        { key = "Key0"; mods = "Command"; action = "ResetFontSize"; }
        { key = "Equals"; mods = "Command"; action = "IncreaseFontSize"; }
        { key = "Subtract"; mods = "Command"; action = "DecreaseFontSize"; }
      ];
    };
  };

  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./kitty;
  };

  programs.i3status = {
    enable = isLinux;

    general = {
      colors = true;
      color_good = "#8C9440";
      color_bad = "#A54242";
      color_degraded = "#DE935F";
    };

    modules = {
      ipv6.enable = false;
      "wireless _first_".enable = false;
      "battery all".enable = false;
    };
  };

  programs.neovim = {
    enable = true;
    package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;

    withPython3 = true;

    plugins = with pkgs; [
      customVim.vim-copilot
      customVim.vim-marked
      customVim.vim-cue
      customVim.vim-fish
      customVim.vim-fugitive
      customVim.vim-glsl
      #customVim.vim-misc
      customVim.vim-pgsql
      customVim.vim-tla
      customVim.pigeon
      #customVim.AfterColors

      customVim.vim-devicons
      # customVim.vim-nord
      customVim.nvim-comment
      # customVim.nvim-lspconfig
      # customVim.nvim-plenary # required for telescope
      # customVim.nvim-telescope
      customVim.nvim-treesitter
      customVim.nvim-treesitter-textobjects
      customVim.nvim-gen
      customVim.nvim-ollama
      customVim.vim-goyo
      customVim.vim-paredit

      customVim.nvim-web-devicons
      customVim.nvim-gitsigns
      customVim.nvim-dressing
      customVim.nvim-conform
      customVim.nvim-nui

      vimPlugins.vim-gitgutter
      vimPlugins.vim-slime
      vimPlugins.nerdtree
      vimPlugins.nerdcommenter

      # vimPlugins.vim-markdown
      vimPlugins.vim-nix
      vimPlugins.typescript-vim
    ];

    extraConfig = (import ./vim-config.nix) { inherit sources; };
  };

  services.gpg-agent = {
    enable = isLinux;

    # cache the keys forever so we don't get asked for a password
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
  };

  xresources.extraConfig = builtins.readFile ./Xresources;

  # Make cursor not tiny on HiDPI screens
  home.pointerCursor = lib.mkIf isLinux {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
    x11.enable = true;
  };
}
