# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <agenix/modules/age.nix>
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable OpenGL
  hardware.graphics.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };


  # Enable the GNOME Desktop Environment.
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm = {
    enable = true;
    autoSuspend = false;
  };

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nithi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "gamemode" "scanner" "lp" ];
    packages = with pkgs; [
      tree
      discord
      obsidian
      fractal
      tmux
      keepassxc
      gh
    ];
  };

  programs.firefox.enable = true;
  programs.tmux.enable = true;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };
  programs.gamemode.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    vim # Just for the fallback cases
    gnome-tweaks
    git
    dig
    htop
    trash-cli
    nixpkgs-fmt
    (pkgs.callPackage <agenix/pkgs/agenix.nix> { })
  ];

  environment.variables = { EDITOR = "nvim"; };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  #virtualisation.docker.enable = true;

  ### Networked Services - Begin ###

  services.immich = {
    enable = true;
    settings.server.externalDomain = "https://pics.nithish.dev";
    #host = "localhost";
    #openFirewall = false; # Behind a reverse proxy
  };

  users.users.immich.extraGroups = [ "video" "render" ];

  # Reverse proxy

  services.nginx = {
    enable = true;

    # If the requested vhost is not defined, the first listing was being served.
    # Disabling that behaviour here. It
    virtualHosts."_" = {
      default = true;
      rejectSSL = true; # !Useful in default server blocks to avoid serving the certificate for another vhost.

      # Drop all requests
      locations."/" = {
        extraConfig = "return 444;";
      };
    };

    virtualHosts."pics.nithish.dev" = {
      forceSSL = true;
      useACMEHost = "nithish.dev"; # Use wildcard cert
      locations."/" = {
        proxyPass = "http://${config.services.immich.host}:${toString config.services.immich.port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;

        extraConfig = ''
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          client_max_body_size 10G;
        '';
      };
    };
  };

  services.openssh = {
    enable = true;
    ports = [ 2247 ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      cache-size = 1000; # Ehhh, why not

      # Upstream nameservers
      server = [ "1.1.1.1" "1.0.0.1" ];

      # Records of intrest. If I need to host a subdomain of nithish.dev. in a diff host
      # then the subdomains pointing to this host should be listed individually.
      # dnsmasq will resolve all subdomains to have the IPs of the parent domain.
      address = [ "/nithish.dev/192.168.0.32" ];
    };
  };

  # Based on sample config at https://sourceforge.net/p/ddclient/code/HEAD/tree/trunk/sample-etc_ddclient.conf
  # See https://www.reddit.com/r/SelfHosting/comments/16wnu3s/ddclient_and_cloudflare_dynamic_dns/ for gotchas on
  # token generation. tl;dr: The token needs to have access to all zones of the account.
  services.ddclient = {
    enable = true;
    #verbose = true;
    protocol = "cloudflare";
    zone = "nithish.dev";
    username = "nithssh@proton.me";
    passwordFile = config.age.secrets.cloudflare_token.path;
    domains = [ "cardinal.nithish.dev" ];
    usev6 = "";
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "nithssh@proton.me";
    certs = {
      "nithish.dev" = {
        domain = "*.nithish.dev";
        group = "nginx";

        # See https://go-acme.github.io/lego/dns/cloudflare/
        dnsProvider = "cloudflare";
        environmentFile = config.age.secrets.cf_cert_env_vars.path;
      };
    };
  };

  ### Networked Services - End ###

  # Open ports in the firewall.
  networking.firewall = {
	# DNS, DNSoverTLS HTTPS
  	allowedTCPPorts = [ 53 853 443 ];
	allowedUDPPorts = [ 53 853 443 ];
  };

  networking.nftables.ruleset = let
    geofenceDrv = import ./geofence.nix { inherit pkgs; };
  in
  ''
    table inet ip_restriction {
      set india_only {
        type ipv4_addr
	flags interval
        elements = {  ${lib.readFile "${geofenceDrv}/india.zone"} }
      }

      chain input {
        type filter hook input priority 10; policy drop;

	# Allow incoming packets from existing connections.
	ct state established,related accept
	# Accept loopback connections
	iifname "lo" accept comment "trusted interfaces"
    
        # Allow private IPv4 ranges (RFC 1918)
	ip saddr 10.0.0.0/8 accept
        ip saddr 172.16.0.0/12 accept
        ip saddr 192.168.0.0/16 accept

        ip saddr @india_only accept

	tcp flags & (fin | syn | rst | ack) == syn log prefix "refused connection: " level info
      }
    }
  '';

  networking = {
    hostName = "cardinal";
    hosts = {
    "127.0.0.1" = [ "localhost" "cardinal.nithish.dev" ];
  };

    networkmanager.enable = true;
    nftables.enable = true; # Note: Normally incompatible with docker and libvirt
  };


  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  nixpkgs.config = {
    allowUnfree = true;
  };

  age.secrets = {
    cloudflare_token.file = ./secrets/cloudflare_token.age;
    cf_cert_env_vars.file = ./secrets/cf_cert_env_vars.age;
  };

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 8 * 1024;
  }];

  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.hplipWithPlugin ];
  };


  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

}

