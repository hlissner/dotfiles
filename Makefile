NIXOS_VERSION := 19.09
NIXOS_PREFIX  := $(PREFIX)/etc/nixos

FLAGS         := -I "my=$(PWD)" $(FLAGS)
COMMAND       := test

# The real Labowski
all: channels secrets.nix
	@sudo nixos-rebuild $(FLAGS) $(COMMAND)

install: channels update config
	@sudo nixos-install --root "$(PREFIX)" $(FLAGS)

upgrade: update switch

update:
	@sudo nix-channel --update

switch:
	@sudo nixos-rebuild $(FLAGS) switch

gc:
	@nix-collect-garbage -d

clean:
	@rm -f secrets.nix result


# Parts
config: $(NIXOS_PREFIX)/configuration.nix

channels:
	@sudo nix-channel --add "https://nixos.org/channels/nixos-${NIXOS_VERSION}" nixos
	@sudo nix-channel --add "https://github.com/rycee/home-manager/archive/release-${NIXOS_VERSION}.tar.gz" home-manager
	@sudo nix-channel --add "https://nixos.org/channels/nixpkgs-unstable" nixpkgs-unstable

$(NIXOS_PREFIX)/configuration.nix:
	@sudo nixos-generate-config --root "$(PREFIX)"
	@echo "import $(PWD)/dotfiles \"$(HOST)\"" | sudo tee "$(NIXOS_PREFIX)/configuration.nix"

secrets.nix: secrets.nix.gpg
	@nix-shell -p gnupg --run "gpg -dq $< > $@"


# Convenience aliases
i: install
s: switch
up: upgrade


.PHONY: update config channels test upgrade install
