# templates/default.nix

{
  default = {
    description = "These dotfiles, minus my host configs";
    welcomeText = ''
      Define a host under hosts/. Use the template to start you off:

          nix flake new -t github:hlissner/dotfiles#host hosts/NAME

      Run `bash ./install.sh` when you're ready to deploy it!
    '';
    # Omit hosts/ so end-user can define their own.
    path = builtins.path {
      name = "dotfiles";
      path = ../.;
      filter = path: type:
        !(type == "directory" && dirOf path == toString ../hosts);
    };
  };

  host = import ./host.nix;
}
