# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./main-user.nix
      inputs.home-manager.nixosModules.default
    ];

  # Bootloader.
  boot.loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
      #grub = {
          #enable = true;
          #devices = [ "nodev" ];
          #efiSupport = true;
          #useOSProber = true;
      #};
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  main-user.enable = true;
  main-user.userName = "tapiok";

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "tapiok" = import ./home.nix;
    };
  };

  #hardware
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;

  services.gnome.gnome-keyring.enable = true;
  services.upower.enable = true;

  services.xserver = {
    enable = true;

    xkb.layout = "fi";
    xkb.variant = "";

    #xkbOptions = "caps:ctrl_modifier";

    displayManager = {
      sddm.enable = true;
      defaultSession = "none+awesome";
    };

    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      extraPackages = hp: [
        hp.dbus
	hp.monad-logger
	hp.xmonad-contrib
      ];
    };

    windowManager.awesome = {
      enable = true;
      luaModules = with pkgs.luaPackages; [
        luarocks
        luadbi-mysql
      ];
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };


  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";
  time.hardwareClockInLocalTime = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_DK.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "da_DK.UTF-8";
    LC_IDENTIFICATION = "da_DK.UTF-8";
    LC_MEASUREMENT = "da_DK.UTF-8";
    LC_MONETARY = "da_DK.UTF-8";
    LC_NAME = "da_DK.UTF-8";
    LC_NUMERIC = "da_DK.UTF-8";
    LC_PAPER = "da_DK.UTF-8";
    LC_TELEPHONE = "da_DK.UTF-8";
    LC_TIME = "da_DK.UTF-8";
  };


  # Configure console keymap
  console.keyMap = "fi";

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  # Enable automatic login for the user.
  services.getty.autologinUser = "tapiok";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.pulseaudio = true;
  # List packages installed in system profile. To search, run:
  # $ nix search wget

  #nixpkgs.config.cudaSupport = true;

  services.avahi = {
    enable = true;
    openFirewall = true;
    nssmdns = true;
    publish = {
      enable = true;
      userServices = true;
      addresses = true;
      workstation = true;
    };
  };

  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  '';

  users.users.sunshine = {
    isNormalUser = true;
    home = "/home/sunshine";
    description = "Sunshine Server";
    extraGroups = [ "wheel" "networkmanager" "input" "video" "sound" ];
  };

  security.sudo.extraRules = [
    {
      users = [ "sunshine" ];
      commands = [
        {
	  command = "ALL";
	  options = [ "NOPASSWD" ];
	}
      ];
    }
  ];

  security.wrappers.sunshine = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+p";
    source = "${pkgs.sunshine}/bin/sunshine";
  };


  programs.dconf.enable = true;


  systemd.services.sunshine = {
    wantedBy = [ "graphical-session.target" ];
    description = "Sunshine is a Game stream host for Moonlight.";
    startLimitIntervalSec = 500;
    startLimitBurst = 5;
    partOf = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.sunshine}/bin/sunshine";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  environment.systemPackages = with pkgs; [
    pkgs.alacritty
    pkgs.librewolf
    pkgs.lsof
    pkgs.appimage-run
    pkgs.pavucontrol
    pkgs.git
    pkgs.gtk4
    pkgs.spotify
    pkgs.nvidia-vaapi-driver
    pkgs.ffmpeg_5-full
    pkgs.teamspeak_client
   (pkgs.sunshine.override {
      cudaSupport = true;
      stdenv = pkgs.cudaPackages.backendStdenv;
    })
    fishPlugins.done
    fishPlugins.fzf-fish
    fishPlugins.hydro
    fzf
    fishPlugins.grc
    grc
    (wineWowPackages.full.override {
     wineRelease = "staging";
     mingwSupport = true;
    })
    winetricks
    lutris
    rofi
    polybar
  ];

services.samba = {
  enable = true;
  securityType = "user";
  openFirewall = true;
  extraConfig = ''
    workgroup = WORKGROUP
    server string = smbnix
    netbios name = smbnix
    security = user 
    #use sendfile = yes
    #max protocol = smb2
    # note: localhost is the ipv6 localhost ::1
    hosts allow = 192.168.0. 127.0.0.1 localhost
    hosts deny = 0.0.0.0/0
    guest account = nobody
    map to guest = bad user
  '';
  shares = {
    public = {
      path = "/mnt/Shares/Public";
      browseable = "yes";
      "read only" = "no";
      "guest ok" = "yes";
      "create mask" = "0644";
      "directory mask" = "0755";
      "force user" = "username";
      "force group" = "groupname";
    };
    private = {
      path = "/mnt/Shares/Private";
      browseable = "yes";
      "read only" = "no";
      "guest ok" = "no";
      "create mask" = "0644";
      "directory mask" = "0755";
      "force user" = "username";
      "force group" = "groupname";
    };
  };
};

services.samba-wsdd = {
  enable = true;
  openFirewall = true;
};


  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [ { from = 0; to = 65535; } ];
    allowedUDPPortRanges = [ { from = 0; to = 65535; } ];
    allowPing = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
