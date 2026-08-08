{
  config,
  pkgs,
  lib,
  configDir,
  ...
}:
let
  jdk = pkgs.temurin-bin-21;

  # Real file, not /nix/store, so edits show up in git diff
  link =
    path:
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${configDir}/dotfiles/${path}";
in
{
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    nixfmt

    fnm
    maven
    bun
    jdk
    qmk

    gh
    ffmpeg
    exiftool
    libjxl

    # tomcat11: nixpkgs build changes the webapps layout
  ];

  home.sessionVariables = {
    JAVA_HOME = jdk.home;
  };

  programs.git = {
    enable = true;

    lfs.enable = true;

    ignores = [
      ".DS_Store"
      "**/.claude/settings.local.json"
    ];

    settings = {
      merge.ff = false;
    };

    # The generated config is a read-only link; identity goes to config.local
    includes = [ { path = "${config.xdg.configHome}/git/config.local"; } ];
  };

  programs.zsh = {
    enable = true;

    dotDir = "${config.xdg.configHome}/zsh";

    envExtra = ''
      [ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
    '';

    profileExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv zsh)"
    '';

    initContent = lib.mkMerge [
      (lib.mkOrder 1000 ''
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
        [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

        [ -s "$HOME/.vite-plus/env" ] && . "$HOME/.vite-plus/env"

        export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

        export PATH="$HOME/.local/bin:$PATH"

        eval "$(fnm env)"

        [ -s "$ZDOTDIR/.zshrc.local" ] && . "$ZDOTDIR/.zshrc.local"
      '')

      # Terminal.app session restore. Last, to see the final $HISTFILE.
      (lib.mkOrder 1300 ''
        if [ -r "/etc/zshrc_$TERM_PROGRAM" ]; then
          . "/etc/zshrc_$TERM_PROGRAM"
        fi
      '')
    ];
  };

  home.file = {
    ".claude/CLAUDE.md".source = link "AGENTS.md";
    ".codex/AGENTS.md".source = link "AGENTS.md";
    ".gemini/GEMINI.md".source = link "AGENTS.md";
  };

  xdg.configFile = {
    # GUI saves can replace the symlink; switch relinks it
    "karabiner/karabiner.json".source = link "karabiner/karabiner.json";

    "zed/settings.json".source = link "zed/settings.json";

    # vim only honours XDG for vimrc
    "vim/vimrc".text = ''
      set viminfofile=$HOME/.local/state/vim/viminfo
      let g:netrw_home = $HOME . '/.local/state/vim'
    '';
  };

  home.activation.vimStateDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.local/state/vim"
  '';
}
