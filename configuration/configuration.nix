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

 # Create Docker network
 systemd.services.docker-network-coolify = {
   description = "Create Docker network for Coolify";
   after = [ "network.target" "docker.service" ];
   requires = [ "docker.service" ];
   wantedBy = [ "multi-user.target" ];
   serviceConfig = {
     Type = "oneshot";
     RemainAfterExit = true;
     ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.docker}/bin/docker network create coolify 2>/dev/null || true'";
   };
 };

 # PostgreSQL service for Coolify
 systemd.services.coolify-db = {
   description = "PostgreSQL for Coolify";
   after = [ "network.target" "docker.service" "docker-network-coolify.service" ];
   requires = [ "docker.service" "docker-network-coolify.service" ];
   wantedBy = [ "multi-user.target" ];
   serviceConfig = {
     ExecStartPre = "${pkgs.docker}/bin/docker rm -f postgres || true";
     ExecStart = "${pkgs.docker}/bin/docker run --rm --name postgres --network coolify -e POSTGRES_DB=coolify -e POSTGRES_USER=coolify -e POSTGRES_PASSWORD=coolify -v coolify-db-data:/var/lib/postgresql/data postgres:14-alpine";
     ExecStop = "${pkgs.docker}/bin/docker stop postgres";
     Restart = "on-failure";
   };
 };

 # Redis service for Coolify
 systemd.services.coolify-redis = {
   description = "Redis for Coolify";
   after = [ "network.target" "docker.service" "docker-network-coolify.service" ];
   requires = [ "docker.service" "docker-network-coolify.service" ];
   wantedBy = [ "multi-user.target" ];
   serviceConfig = {
     ExecStartPre = "${pkgs.docker}/bin/docker rm -f coolify-redis || true";
     ExecStart = "${pkgs.docker}/bin/docker run --rm --name coolify-redis --network coolify redis:alpine";
     ExecStop = "${pkgs.docker}/bin/docker stop coolify-redis";
     Restart = "on-failure";
   };
 };

 # Coolify service
 systemd.services.coolify = {
   description = "Coolify container";
   after = [ "network.target" "docker.service" "docker-network-coolify.service" "coolify-redis.service" "coolify-db.service" ];
   requires = [ "docker.service" "docker-network-coolify.service" "coolify-redis.service" "coolify-db.service" ];
   wantedBy = [ "multi-user.target" ];

   serviceConfig = {
     ExecStartPre = [
       "-${pkgs.docker}/bin/docker rm -f coolify"
       "${pkgs.bash}/bin/bash -c 'until ${pkgs.docker}/bin/docker exec postgres pg_isready; do sleep 1; done'"
     ];
     ExecStart = ''
       ${pkgs.docker}/bin/docker run --rm \
         --name coolify \
         --network coolify \
         -p 3000:3000 \
         -p 8000:8000 \
         -v /var/run/docker.sock:/var/run/docker.sock \
         -v coolify-logs:/app/logs \
         -v /data/coolify:/data/coolify \
         -e POSTGRES_HOST=postgres \
         -e POSTGRES_PORT=5432 \
         -e POSTGRES_USER=coolify \
         -e POSTGRES_PASSWORD=coolify \
         -e POSTGRES_DB=coolify \
         -e DATABASE_URL="postgresql://coolify:coolify@postgres:5432/coolify" \
         -e REDIS_HOST=coolify-redis \
         -e REDIS_PORT=6379 \
         -e SSL_MODE=off \
         coollabsio/coolify:latest
     '';
     ExecStop = "${pkgs.docker}/bin/docker stop coolify";
     Restart = "always";
     RestartSec = "10s";
   };
 };

 # Ensure the data directory exists with correct permissions
 systemd.tmpfiles.rules = [
   "d /data/coolify 0755 root root -"
 ];

 users.users.nixos = {
   isNormalUser = true;
   extraGroups = [ "wheel" "docker" ];  # Grants sudo and Docker access.
   openssh.authorizedKeys.keys = [
     "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2OjoL61AJ+k/AzHvD9n9PEPM1h7RMH+Ls5WWKZ2HnL"
   ];
 };

 security.sudo = {
   enable = true;
   wheelNeedsPassword = false;
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
