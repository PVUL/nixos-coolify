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
    nixos = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" ];  # Grants sudo and Docker access.
      openssh.authorizedKeys.keys = [ 
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDJZoNId6npxlyODyr7/8QJfG5WkpSS6imi8YkcXiHtdymL4RF6wLBvu7mTvDxta/xpzQ1GazUCCsNPtQ7/uepbrPtCcroMeW9WvJcDwRKrh2ejsbofWoQFpyjHNodA7Cz4PFHQSKQijgRrTuHxGkP0uFNkXX5++ucu0Q8uKHn65UGcyYKgIunanY1jp+RzaZ1S6w8W/nI/vM8rCK3ONZBC4bIrVRJWxLIku/1bvPXkD29LN86G184eYI+GzsG7SH79mZ8hoMdgZrGb1ILbcEf/s8Lk+LEsYQiC0OmocUXRaqth/Qf8+SyayA/sxjITf4SfYe1Otv0YtkeERzL3rD3XrTvJa2qiI8g1lFWZ4sBtb/k+FfJJvjkYp5L9+H6HSGF9msHGAQLK9FZqhEN5hTTsHgQtLS4s6RupzOWkWRqx5KmDB1G8/M+YsjD5BuUurSY0luO8I+LJcFGn4HmNTGC4hoAz66uXdosT+wg/ahr5FlFWM7i9oyr7LfoxuFJROdopH1TRRKfSPfOws775+8GODTEgbHYNChNU/HEgqxAaoFPnTkoQ3G9oWp1Ffj7nOIcgaMjTDaf7EIm5faq3RsPfGfcUv1fE4y/nhed0/dSIltW/OLZhZd3vWACe38lmlBYJfHh32YOT/tP0jOhXUtpzArx6M7/M3Apy8esGbL/pxw==" 
      ];
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
