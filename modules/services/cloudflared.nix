# modules/services/cloudflared.nix
#
# Cloudflare Tunnel (cloudflared) service for Zero Trust private network access.
# Provides WARP routing for private IPs and browser SSH emergency access.
#
# This module enables secure remote access to home network (e.g., 192.168.50.0/24)
# through Cloudflare Zero Trust with two access methods:
#
# 1. WARP private routing (primary): External devices with WARP client can
#    directly SSH to private IPs like 192.168.50.143 (Linux) and 192.168.50.227 (Mac)
#
# 2. Browser SSH (emergency): SSH via browser at https://ssh-linux.your-domain.com
#    when WARP is not installed
#
# Configuration steps:
#
# 1. Prerequisites:
#    - Domain hosted on Cloudflare (NS records pointing to Cloudflare)
#    - Cloudflare Zero Trust organization created (free tier: <50 users)
#    - Fixed IPs for home devices (DHCP reservation on router)
#
# 2. Initial tunnel setup (run on the Linux server that will host cloudflared):
#    $ cloudflared tunnel login
#    $ cloudflared tunnel create home
#    # Note the tunnel ID shown (e.g., "abcd1234-...")
#
# 3. Encrypt credentials with agenix:
#    $ agenix -e hosts/<hostname>/secrets/cloudflared-credentials.age \
#             -i /etc/ssh/host_ed25519 \
#             ~/.cloudflared/<tunnel-id>.json
#
# 4. Enable this module in host configuration (e.g., hosts/atlas/default.nix):
#    modules.services.cloudflared = {
#      enable = true;
#      tunnelId = "your-tunnel-id";
#      credentialsFile = ./secrets/cloudflared-credentials.age;
#      warpRouting = {
#        enabled = true;
#        cidrs = [ "192.168.50.0/24" ];
#      };
#    };
#
# 5. Deploy and test:
#    $ sudo nixos-rebuild switch --flake .#<hostname>
#    $ darwin-rebuild switch --flake .#<hostname>
#    $ ssh c1@192.168.50.227  # Test atlas (Linux)
#    $ ssh c1@192.168.50.143  # Test charlie (macOS)
#
# Network topology (dual tunnel):
#
#   Home Network (192.168.50.0/24)
#   ├── atlas (Linux, 192.168.50.227) runs cloudflared tunnel
#   ├── charlie (macOS, 192.168.50.143) runs cloudflared tunnel
#   └── Cloudflare Zero Trust
#       ├── WARP clients (external devices with Zero Trust enrollment)
#       └── Browser SSH (emergency access via public hostnames)
#
# Security notes:
# - Browser SSH requires server user matching email prefix (siyuan.arc@gmail.com → user siyuan.arc)
# - Enable MFA in Cloudflare Access policies
# - Use SSH keys only, disable password authentication
# - Configure firewall to allow SSH only from home network
#
# Example configuration for atlas (Linux server, IP: 192.168.50.227):
#
# In hosts/atlas/default.nix, add to modules section:
#
#   modules.services.cloudflared = {
#     enable = true;
#     tunnelId = "your-tunnel-id-here";  # From 'cloudflared tunnel create'
#     credentialsFile = ./secrets/cloudflared-credentials.age;
#     warpRouting = {
#       enabled = true;
#       cidrs = [ "192.168.50.0/24" ];
#     };
#     extraConfig = {
#       # Optional: Set tunnel name for routing commands
#       tunnelName = "home";
#     };
#   };
#
# For charlie (macOS, IP: 192.168.50.143):
#
# 1. Ensure fixed IP via router DHCP reservation (bind MAC address to 192.168.50.143)
# 2. Configure SSH server to allow key-based authentication only
# 3. Create user 'siyuan.arc' for browser SSH emergency access
# 4. Test SSH access from atlas: ssh c1@192.168.50.143
#
# Router configuration (typical):
# - DHCP reservation: Map charlie's MAC address to 192.168.50.143
# - DHCP reservation: Map atlas's MAC address to 192.168.50.227
# - Ensure firewall allows SSH (port 22) between local devices
#

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.services.cloudflared;
  user = config.user.name;
  homeDir = config.user.home;
  configDir = "${homeDir}/.cloudflared";
  configFile = "${configDir}/config.yml";
  secretGroup = if pkgs.stdenv.isDarwin then "staff" else "users";
in {
  options.modules.services.cloudflared = with types; {
    enable = mkBoolOpt false;

    tunnelId = mkOpt' str "" "Cloudflare Tunnel ID (from 'cloudflared tunnel create')";

    tunnelName = mkOpt' str "home" "Tunnel name (used for routing commands)";

    credentialsFile = mkOpt' (nullOr path) null
      "Age-encrypted credentials JSON file (e.g., secrets/cloudflared-credentials.age)";

    extraConfig = mkOpt' attrs {} "Additional YAML config attributes";

    warpRouting = {
      enabled = mkBoolOpt false;
      cidrs = mkOpt' (listOf str) [] "Private CIDRs to route through WARP (e.g., [\"192.168.50.0/24\"])";
    };

    package = mkOpt package pkgs.cloudflared;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.tunnelId != "";
          message = "modules.services.cloudflared.tunnelId must be set";
        }
        {
          assertion = cfg.credentialsFile != null;
          message = "modules.services.cloudflared.credentialsFile must be set (age-encrypted credentials)";
        }
      ];

      environment.systemPackages = [ cfg.package ];

      # Decrypt credentials file to ~/.cloudflared/<tunnel-id>.json
      age.secrets."cloudflared-credentials" = {
        file = cfg.credentialsFile;
        owner = user;
        group = secretGroup;
        path = "${configDir}/${cfg.tunnelId}.json";
      };

      # Create config.yml
      home.file.".cloudflared/config.yml" = {
        text = let
          tunnelName = cfg.extraConfig.tunnelName or "home";
          baseConfig = {
            tunnel = cfg.tunnelId;
            credentials-file = "${configDir}/${cfg.tunnelId}.json";
          };
          warpConfig = optionalAttrs cfg.warpRouting.enabled {
            warp-routing.enabled = true;
          };
          mergedConfig = recursiveUpdate (baseConfig // warpConfig) cfg.extraConfig;
        in builtins.toJSON mergedConfig;
      };
    }

    # Ensure config directory exists with correct permissions
    (optionalAttrs pkgs.stdenv.isLinux {
        systemd.user.tmpfiles.rules = [
          "d ${configDir} 0700 ${user} users - -"
        ];

        # Systemd service for cloudflared
        systemd.services.cloudflared = {
          description = "Cloudflare Tunnel daemon";
          after = [ "network.target" "age-secrets-cloudflared-credentials.service" ];
          wants = [ "age-secrets-cloudflared-credentials.service" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "simple";
            User = user;
            Group = "users";
            ExecStart = "${cfg.package}/bin/cloudflared --config ${configFile} tunnel run";
            Restart = "on-failure";
            RestartSec = "10s";
            LimitNOFILE = 100000;
            # Protect sensitive credentials
            ReadWritePaths = configDir;
            PrivateTmp = true;
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = "read-only";
          };

          environment = {
            # Cloudflared needs to write logs and cache
            XDG_CACHE_HOME = "${homeDir}/.cache";
            XDG_STATE_HOME = "${homeDir}/.local/state";
          };
        };

        # Add WARP routes if specified
        systemd.services.cloudflared-routes = mkIf (cfg.warpRouting.enabled && cfg.warpRouting.cidrs != []) {
          description = "Add WARP routes for Cloudflare Tunnel";
          after = [ "cloudflared.service" ];
          requires = [ "cloudflared.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig.Type = "oneshot";
           script = let
             tunnelName = cfg.tunnelName;
             routeCommands = map (cidr: ''
              ${cfg.package}/bin/cloudflared tunnel route ip add ${cidr} ${tunnelName} || true
            '') cfg.warpRouting.cidrs;
          in ''
            # Wait for tunnel to be ready
            sleep 10
            ${concatStringsSep "\n" routeCommands}
          '';
        };
      })

      (optionalAttrs pkgs.stdenv.isDarwin {
        launchd.user.agents.cloudflared = {
          serviceConfig = {
            ProgramArguments = [ "${cfg.package}/bin/cloudflared" "--config" configFile "tunnel" "run" ];
            KeepAlive = true;
            RunAtLoad = true;
            EnvironmentVariables = {
              XDG_CACHE_HOME = "${homeDir}/.cache";
              XDG_STATE_HOME = "${homeDir}/.local/state";
            };
            StandardOutPath = "${homeDir}/Library/Logs/cloudflared.out.log";
            StandardErrorPath = "${homeDir}/Library/Logs/cloudflared.err.log";
          };
        };

        # Ensure correct permissions on activation
        system.activationScripts.cloudflaredPermissions.text = ''
          echo "Fixing cloudflared directory permissions..."
          if [ -d "${configDir}" ]; then
            chown -R ${user} "${configDir}"
            chmod 700 "${configDir}"
          fi
          
          # Fix agenix secret permissions
          # On Darwin, agenix might create secrets as root:admin 400 in /run/agenix
          # We need to ensure the user can read the credentials file
          CRED_LINK="${configDir}/${cfg.tunnelId}.json"
          if [ -L "$CRED_LINK" ]; then
            TARGET=$(readlink "$CRED_LINK")
            if [ -f "$TARGET" ]; then
              echo "Fixing permission for cloudflared credentials: $TARGET"
              chown ${user} "$TARGET"
              chmod 600 "$TARGET"
            fi
          fi
        '';
      })
    (mkIf cfg.warpRouting.enabled {
      warnings = optional (cfg.warpRouting.cidrs == [])
        "WARP routing enabled but no CIDRs specified. Add private networks to modules.services.cloudflared.warpRouting.cidrs.";
    })
  ]);
}
