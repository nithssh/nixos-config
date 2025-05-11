let
  # From: /etc/ssh/ssh_host_ed25519_key.pub
  hostEcKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII0cvE2dX4lxUCvvJnTM0NHxV/9LdOC4cfyrtU/s73J8";
in
{
  "cloudflare_token.age".publicKeys = [ hostEcKey ];
  "cf_cert_env_vars.age".publicKeys = [ hostEcKey ];

  # Contents: htpasswd -nB nithish
  "radicale_auth.age".publicKeys = [ hostEcKey ];

  # Contents: openssl rand -hex 512
  "secondary_nvme_key.age".publicKeys = [ hostEcKey ];
}                               

