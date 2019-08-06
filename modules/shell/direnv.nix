{ config, lib, pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      lorri =
        let src = (super.fetchFromGitHub {
              owner = "target";
              repo = "lorri";
              rev = "e943fa403234f1a5e403b6fdc112e79abc1e29ba";
              sha256 = "1ar7clza117qdzldld9qzg4q0wr3g20zxrnd1s51cg6gxwlpg7fa";
            });
        in super.callPackage src { inherit src; };
    })
  ];

  environment.systemPackages = with pkgs; [
    direnv
    lorri
  ];
}
