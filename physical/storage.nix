{ lib, config, ... }: let
  inherit (builtins) isBool toString removeAttrs throw;
  inherit (lib.lists) toList foldl' head length elem;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.attrsets) isAttrs optionalAttrs mapAttrsToList filterAttrs attrValues concatMapAttrs;

  flatMapAttrs = f: s: let
    flatMapAttrs' = p: f: s: concatMapAttrs (n: v: if isAttrs v then
      flatMapAttrs' (p ++ [ n ]) f v
    else
      f (p ++ [ n ]) v
    ) s;
  in flatMapAttrs' [ ] f s;

  cfg = config.physical;
in {
  imports = [ ./storage.options.nix ];

  config = let
    fsFS = filterAttrs (_: v: (!v.systemd.enable)) cfg.storage;
    systemdFS = filterAttrs (_: v: v.systemd.enable) cfg.storage;
    foldOptions = foldl' (a: x: a ++ (
      if isAttrs x then
        mapAttrsToList (n: v': if isBool v' then n else "${n}=${toString v'}") (
          filterAttrs (_: v'': v'' != false) (flatMapAttrs (p: v'': { ${concatStringsSep "." p} = v''; }) x)
        )
      else
        [ x ]
    )) [ ] ;
  in {
    fileSystems = mkIf (fsFS != {}) (concatMapAttrs (_: v: {
      ${v.mountPoint} = removeAttrs v [ "name" "types" "options" "systemd" ] // optionalAttrs (v.options != [ ]) {
        options = foldOptions v.options;
      };
    }) fsFS);
    systemd.mounts = mkIf (systemdFS != {}) (mapAttrsToList (_: v: {
      inherit (v.systemd) unitConfig;
      what = v.device;
      where = v.mountPoint;
      type = v.fsType;
      options = concatStringsSep "," (foldOptions v.options);
      wantedBy = [ "multi-user.target" ];
    }) systemdFS);

    lib.physical = rec {
      storagesOfType = t: let
        s = attrValues (filterAttrs (_: v: elem t v.types) cfg.storage);
      in if length s == 0 then
        throw "No storage of type '${t}'."
      else
        s;
      storageOfType = t: let
        s = storagesOfType t;
      in if length s > 1 then
        throw "More than one storage of type '${t}': ${concatStringsSep ", " s}."
      else
        head s;
    };
  };
}
