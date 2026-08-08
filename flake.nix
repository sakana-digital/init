{
  description = "init";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      ...
    }:
    let
      # Untracked; the flakeref needs `path:`
      machine =
        if builtins.pathExists ./machine.nix then
          import ./machine.nix
        else
          throw "machine.nix is missing. Run ./bootstrap.sh first.";

      inherit (machine)
        hostnames
        usernames
        configDir
        hostPlatform
        ;

      inherit (nixpkgs) lib;

      primaryUser = lib.head usernames;

      configuration = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit
            inputs
            hostPlatform
            usernames
            primaryUser
            ;
        };
        modules = [
          ./darwin/configuration.nix

          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;

              user = primaryUser;

              autoMigrate = true;

              mutableTaps = true;
            };
          }

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.backupFileExtension = "before-hm";

            home-manager.extraSpecialArgs = { inherit configDir; };
            home-manager.users = lib.genAttrs usernames (_: import ./home.nix);
          }
        ];
      };
    in
    {
      darwinConfigurations = lib.genAttrs (lib.unique (hostnames ++ [ "default" ])) (_: configuration);

      formatter.${hostPlatform} = nixpkgs.legacyPackages.${hostPlatform}.nixfmt-tree;
    };
}
