{ config, lib, pkgs, ... }:

{
  my.packages = [ pkgs.teensy-loader-cli ];
  my.alias.teensyload = "sudo teensy-loader-cli -w -v --mcu=atmega32u4";
}
