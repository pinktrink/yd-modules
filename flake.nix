{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = inputs@{ self, ... }: {
    nixosOptions = {
      physical = import ./physical/default.options.nix;
    };
    nixosModules = {
      physical = import ./physical;
      deployment = import ./deployment;
    };
  };
}
