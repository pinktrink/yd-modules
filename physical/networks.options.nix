{ lib, config, ... }: let
  inherit (builtins) isList;
  inherit (lib) types;
  inherit (lib.lists) toList length elemAt head;
  inherit (lib.options) mkOption;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.attrsets) foldlAttrs recursiveUpdate attrNames filterAttrs;

  masks = map (x: concatStringsSep "." (map toString x)) [
    [ 0 0 0 0 ]
    [ 128 0 0 0 ]
    [ 192 0 0 0 ]
    [ 224 0 0 0 ]
    [ 240 0 0 0 ]
    [ 248 0 0 0 ]
    [ 252 0 0 0 ]
    [ 254 0 0 0 ]
    [ 255 0 0 0 ]
    [ 255 128 0 0 ]
    [ 255 192 0 0 ]
    [ 255 224 0 0 ]
    [ 255 240 0 0 ]
    [ 255 248 0 0 ]
    [ 255 252 0 0 ]
    [ 255 254 0 0 ]
    [ 255 255 0 0 ]
    [ 255 255 128 0 ]
    [ 255 255 192 0 ]
    [ 255 255 224 0 ]
    [ 255 255 240 0 ]
    [ 255 255 248 0 ]
    [ 255 255 252 0 ]
    [ 255 255 254 0 ]
    [ 255 255 255 0 ]
    [ 255 255 255 128 ]
    [ 255 255 255 192 ]
    [ 255 255 255 224 ]
    [ 255 255 255 240 ]
    [ 255 255 255 248 ]
    [ 255 255 255 252 ]
    [ 255 255 255 254 ]
  ];

  v4Octet = types.ints.between 0 255;
  partialV4Type = types.either v4Octet (types.listOf v4Octet);
  partialIPV4 = x: mkOption ({
    type = partialV4Type;
    default = [ ];
    apply = toList;
  } // x);

  concatV4Octets = ps: ss: let
    os = ps ++ ss;
    l = length os;
    ip = concatStringsSep "." (map toString os);
  in if l == 4 then ip else throw "Incorrect octet count for V4 address ${ip} (${toString l} != 4).";

  concatMapAttrs = f: foldlAttrs (a: n: v: recursiveUpdate a (f n v)) {};

  coercedListOf = t: mkOption {
    type = types.either t (types.listOf t);
    apply = toList;
  };

  cfg = config.physical;
in {
  options = {
    physical = {
      rack = mkOption {
        type = types.nullOr (types.submodule ({ config, ... }: {
          options = {
            name = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            vlan = {
              enable = mkOption {
                type = types.bool;
                default = true;
              };
              trust = mkOption {
                type = types.bool;
                default = false;
              };
              name = mkOption {
                type = types.str;
                default = "rack";
              };
              ipv4 = {
                enable = mkOption {
                  type = types.bool;
                  default = true;
                };
                addressPrefix = coercedListOf types.ints.u8;
                prefixLength = mkOption { type = types.ints.u8; };
                address = mkOption {
                  type = types.str;
                  default = concatStringsSep "." (map toString (config.vlan.ipv4.addressPrefix ++ config.location));
                  readOnly = true;
                };
              };
              interface = mkOption { type = types.str; };
            };
            location = coercedListOf types.ints.u8;
            size = mkOption {
              type = types.int;
              default = 1;
            };
          };
        }));
        default = null;
      };
      residence = {
        address = mkOption {
          type = types.str;
          default = with cfg.residence; if length suffix > 0 && network != null then concatV4Octets cfg.networks.${network}.prefix suffix else null;
        };
        network = mkOption {
          type = types.nullOr types.str;
          default = let
            res = attrNames (filterAttrs (_: v: v.residence) cfg.networks);
          in if length res > 0 then head res else null;
        };
        suffix = mkOption {
          type = types.nullOr partialV4Type;
          default = [ ];
        };
      };
      networks = mkOption {
        type = types.attrsOf (types.submodule ({ name, config, ... }: {
          options = {
            residence = mkOption {
              type = types.bool;
              default = false;
            };
            interface = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            trust = mkOption {
              type = types.bool;
              default = false;
            };
            prefix = partialIPV4 {};
            suffix = partialIPV4 {
              default = cfg.residence.suffix;
            };
            prefixLength = mkOption {
              type = types.ints.between 0 32;
              default = 24;
            };
            netMask = mkOption {
              type = types.str;
              default = elemAt masks config.prefixLength;
            };
            address = mkOption {
              type = types.either partialV4Type types.str;
              default = with config; concatV4Octets prefix suffix;
              apply = x: if isList x then concatV4Octets x else x;
            };
            CIDR = mkOption {
              type = types.str;
              default = "${config.address}/${toString config.prefixLength}";
            };
            ranges = let
              networkConfig = config;
            in mkOption {
              type = types.attrsOf (types.submodule ({ config, ... }: {
                options = {
                  startSuffix = partialIPV4 {};
                  endSuffix = partialIPV4{};
                  startAddress = mkOption {
                    type = types.str;
                    default = concatV4Octets networkConfig.prefix config.startSuffix;
                  };
                  endAddress = mkOption {
                    type = types.str;
                    default = concatV4Octets networkConfig.prefix config.endSuffix;
                  };
                  rangeLength = mkOption {
                    type = types.ints.between 0 32;
                    default = networkConfig.prefixLength;
                  };
                  CIDR = mkOption {
                    type = types.str;
                    default = "${config.startAddress}/${toString config.rangeLength}";
                  };
                };
              }));
              default = {};
            };
            createInterface = mkOption {
              type = types.bool;
              default = true;
            };
            macvlan = {
              enable = mkOption {
                type = types.bool;
                default = false;
              };
              name = mkOption {
                type = types.str;
                default = name;
              };
              interface = mkOption { type = types.str; };
            };
          };
        }));
        default = {};
      };
    };
  };
}
