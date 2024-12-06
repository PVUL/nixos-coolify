{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Basic system configuration
  system.stateVersion = "24.05";
  
  # Boot configuration
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  
  # Networking
  networking = {
    hostName = "coolify-server";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 
        22 80 443    # Basic ports
        3000         # Coolify dashboard
      ] ++ (lib.range 8000 9000);    # Range for deployed applications
    };
  };

  # System tweaks for running containers
  boot.kernel.sysctl = {
    "vm.max_map_count" = 262144;  # Required for Elasticsearch
    "net.ipv4.ip_forward" = 1;     # Required for container networking
  };

  # Docker configuration
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # User and access setup
  users.users = {
    root = {
      openssh.authorizedKeys.keyFiles = [ "/etc/ssh/authorized_keys" ];
    };
    nixos = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" ];  # Grants sudo and Docker access.
      openssh.authorizedKeys.keyFiles = [ "/etc/ssh/authorized_keys" ];
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false; # Set to `true` to require a password for sudo.
  };

  # SSH configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # System packages
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    docker-compose
    nginx
    jq
    curl
    wget
    tree
  ];
}
