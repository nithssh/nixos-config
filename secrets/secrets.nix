let
  hostEcKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII0cvE2dX4lxUCvvJnTM0NHxV/9LdOC4cfyrtU/s73J8";
in                              
{                               
  "cloudflare_token.age".publicKeys = [ hostEcKey ];
  "cf_cert_env_vars.age".publicKeys = [ hostEcKey ];
}                               

