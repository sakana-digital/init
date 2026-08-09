{
  config,
  pkgs,
  lib,
  configDir,
  ...
}:
let
  # Real file, not /nix/store, so edits show up in git diff
  link =
    path:
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${configDir}/dotfiles/${path}";
in
{
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    nixfmt
    devbox

    gh

    ffmpeg
    exiftool
  ];

  programs.direnv = {
    enable = true;

    # Without this, a GC wipes every project's devShell
    nix-direnv.enable = true;
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
      # Vite+ bin (https://viteplus.dev)
      [ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
    '';

    profileExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv zsh)"
    '';

    initContent = lib.mkMerge [
      (lib.mkOrder 1000 ''
        # bun completions
        [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

        # Bun
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"

        export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

        export PATH="$HOME/.local/bin:$PATH"

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
