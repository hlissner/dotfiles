NIXOS_VERSION := 19.09
NIXOS_PREFIX  := $(PREFIX)/etc/nixos
COMMAND       := test
FLAGS         := -I "nixpkgs-overlays=$$(pwd)/overlays.nix" \
				 -I "config=$$(pwd)/config" \
				 -I "modules=$$(pwd)/modules" $(FLAGS)

# The real Labowski
all: channels
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
	@rm -f result


# Parts
config: $(NIXOS_PREFIX)/configuration.nix

channels:
	@sudo nix-channel --add "https://nixos.org/channels/nixos-${NIXOS_VERSION}" nixos
	@sudo nix-channel --add "https://github.com/rycee/home-manager/archive/release-${NIXOS_VERSION}.tar.gz" home-manager
	@sudo nix-channel --add "https://nixos.org/channels/nixpkgs-unstable" nixpkgs-unstable

$(NIXOS_PREFIX)/configuration.nix:
	@sudo nixos-generate-config --root "$(PREFIX)"
	@echo "(import /etc/dotfiles \"$$(hostname)\")" | sudo tee "$(NIXOS_PREFIX)/configuration.nix"


# Convenience aliases
i: install
s: switch
up: upgrade


.PHONY: config
