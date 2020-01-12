# Even neckbeards have a social life. Not that I have one. A neckbeard, I mean.
# But when I do have either, then discord and weechat (or Emacs) are my go-to.

{ config, lib, pkgs, ... }:
{
  my.packages = with pkgs; [
    # weechat        # TODO For the real neckbeards
    discord        # For everyone else
  ];
}
