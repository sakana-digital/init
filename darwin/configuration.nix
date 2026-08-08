{
  lib,
  hostPlatform,
  usernames,
  primaryUser,
  ...
}:
{
  nixpkgs.hostPlatform = hostPlatform;

  system.stateVersion = 6;

  system.primaryUser = primaryUser;

  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      NSAutomaticPeriodSubstitutionEnabled = false;
    };

    dock = {
      autohide = true;
      orientation = "right";
      tilesize = 25;
      show-recents = false;
    };

    finder = {
      FXPreferredViewStyle = "clmv";
      NewWindowTarget = "Home";
    };

    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };
  };

  # Determinate Nix: drop this, set nix.enable = false
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  users.users = lib.genAttrs usernames (name: {
    home = "/Users/${name}";
  });

  # Drops $HOME/.nix-profile, which useUserPackages never fills
  environment.profiles = lib.mkForce [
    "/etc/profiles/per-user/$USER"
    "/run/current-system/sw"
    "/nix/var/nix/profiles/default"
  ];

  programs.zsh.enable = true;

  # home-manager extends fpath after /etc/zshrc, so a compinit here would
  # rebuild .zcompdump on every startup
  programs.zsh.enableGlobalCompInit = false;

  programs.zsh.promptInit = ''PS1="%n@%m %1~ %# "'';

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };

    casks = [
      "visual-studio-code"
      "docker-desktop"
      "github"
    ];

    brews = [ ];
  };
}
