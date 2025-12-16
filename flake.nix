{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = inputs@{ self, ... }: {
    nixosModules = {
      physical = import ./physical;
      physical-options = import ./physical/default.options.nix;
      deployment = import ./deployment;
    };
  };
}
