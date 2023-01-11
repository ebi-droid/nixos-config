{ config, lib, pkgs, ... }:

let
  user = "ruixi";
in
{
  environment.systemPackages = with pkgs; [
    waybar
  ];

  home-manager.users.${user} = {
    # Home-manager waybar config
    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
        target = "sway-session.target"; # Needed for waybar to start automatically
      };
    };
  };
}
