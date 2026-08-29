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

    # VS Code extensions run `#!/usr/bin/env node` shims outside any devbox shell
    nodejs

    gh

    # Only so the filter.lfs commands in programs.git resolve, if a repo uses LFS
    git-lfs

    ffmpeg
    exiftool
  ];

  programs.direnv = {
    enable = true;

    # Without this, a GC wipes every project's devShell
    nix-direnv.enable = true;

    # devbox exports hundreds of vars, drowning the prompt on every cd
    config.global.hide_env_diff = true;
  };

  programs.git = {
    enable = true;

    ignores = [
      ".DS_Store"

      "**/.claude/settings.local.json"
    ];

    settings = {
      merge.ff = false;

      init.defaultBranch = "main";

      # GitHub Desktop runs `git lfs install` on launch; with anything but these
      # exact values it tries to rewrite the read-only generated config and fails.
      # `lfs.enable` bakes in an absolute store path, so it cannot be used here.
      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };
    };

    # The generated config is a read-only link; identity goes to config.local
    includes = [ { path = "${config.xdg.configHome}/git/config.local"; } ];
  };

  programs.zsh = {
    enable = true;

    dotDir = "${config.xdg.configHome}/zsh";

    completionInit = "autoload -U compinit && compinit -u";

    profileExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv zsh)"
    '';

    initContent = lib.mkMerge [
      (lib.mkOrder 1000 ''
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
