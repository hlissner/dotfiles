{ config, lib, pkgs, ... }:

{
  boot.zfs.devNodes = "/dev/disk/by-partuuid";
}
