{ lib, config, pkgs, ... }:

let
  cfg = config.main-user;
in
{
  options.main-user = {
    enable
      = lib.mkEnableOption "enable user module";

    userName = lib.mkOption {
      default = "tapiok";
      description = ''
        username
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.userName} = {
      isNormalUser = true;
      description = "Main user";
      extraGroups = [ "networkmanager" "wheel" "audio" ];
      shell = pkgs.fish;
    };
  };
}
