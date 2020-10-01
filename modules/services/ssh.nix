{ options, config, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.ssh;
in {
  options.modules.services.ssh = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      challengeResponseAuthentication = false;
      passwordAuthentication = false;
    };

    user.openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8Tl2pj6CPBV3V72cohPhn+k0a/Na3cOrbmUtFC7rR7icWocSs1S1cSrP3sPLwUqRh3+zfIuLXTrTv3gj8Xvg8WELOspzsiYeAtbcHrnWnx/a7xzYvFyT9/8hkiGM/F6w7IuKEk+AZW34vARSgRPJ1FdH8NbPKJ8ay9zW9XB9YJGnbzIRmsVVpQ8l6Fh8ZqRjZfC1ea7hns8+HgjPrIHFb+S3qZZiwU4Gc8aWJy9ziwwkllEsSchv3aigYA3eOeW0FUQFiKsLGxbX2b2b3d6jFO4Pu+dMSen0h5IzBo0nh7UADSfJPdwbZaMuJzviKe2y6zg6jaM9XRIhLBT6bftDr henrik@lissner.net"
    ];
  };
}
