{

  minimal = {
    path = ./minimal;
    description = "A grossly incandescent and minimal nixos config";
  };

  # Hosts
  host-desktop = {
    path = ./hosts/desktop;
    description = "A starter hosts/* config for someone's daily driver";
  };
  # host-linode = {
  #   path = ./hosts/linode;
  #   description = "A starter hosts/* config for a Linode config";
  # };
  # host-server = {
  #   path = ./hosts/homeserver;
  #   description = "A starter hosts/* config for a home server config";
  # };

  # Projects
  project-discourse-theme = {
    path = ./project/discourse-theme;
    description = "A Discourse component or theme";
  };
  project-discourse-plugin = {
    path = ./project/discourse-plugin;
    description = "A Discourse component or theme";
  };
  project-nodejs = {
    path = ./project/nodejs;
    description = "NodeJS dev environment";
  };
  # TODO project-rust
  # TODO project-rust-bevy
  # TODO project-love2d
  # TODO for Laravel, p?react, emacs plugins, rails, etc
}
