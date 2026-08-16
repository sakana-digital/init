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
      NSTableViewDefaultSizeMode = 1;
      "com.apple.sound.beep.volume" = 0.0;
      "com.apple.trackpad.scaling" = 1.5;
    };

    dock = {
      autohide = true;
      orientation = "right";
      tilesize = 25;
      show-recents = false;
      showAppExposeGestureEnabled = true;
      showMissionControlGestureEnabled = true;

      persistent-apps = [ ];

      persistent-others = [
        {
          folder = {
            path = "/Users/${primaryUser}/Downloads";
            arrangement = "date-added";
            showas = "fan";
          };
        }
      ];
    };

    finder = {
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "clmv";
      NewWindowTarget = "Home";
    };

    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;

      # Three-finger drag needs the three-finger swipes out of the way;
      # four-finger swipes cover Mission Control / App Expose instead
      TrackpadThreeFingerHorizSwipeGesture = 0;
      TrackpadThreeFingerVertSwipeGesture = 0;
    };

    menuExtraClock = {
      FlashDateSeparators = true;
      ShowAMPM = true;
      ShowDate = false;
      ShowDayOfWeek = true;
      ShowSeconds = true;
    };

    WindowManager = {
      HideDesktop = true;
      AppWindowGroupingBehavior = true;
      EnableTiledWindowMargins = true;
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
      "github"
    ];

    brews = [ ];
  };
}
