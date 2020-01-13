NIXOS_VERSION := 19.09
NIXOS_PREFIX  := $(PREFIX)/etc/nixos

FLAGS         := -I "my=$(PWD)" $(FLAGS)
COMMAND       := test

# The real Labowski
all: channels config secrets.nix
	@sudo nixos-rebuild $(FLAGS) $(COMMAND)

install: result channels update config
	@nixos-generate-config --root "$(PREFIX)"
	@nixos-install --root "$(PREFIX)"

upgrade: update switch

switch:
	@sudo nixos-rebuild $(FLAGS) switch

clean:
	@rm -f secrets.nix


# Parts
update:
	@sudo nix-channel --update

config: $(NIXOS_PREFIX)/configuration.nix

channels:
	@sudo nix-channel --add "https://nixos.org/channels/nixos-${NIXOS_VERSION}" nixos
	@sudo nix-channel --add "https://github.com/rycee/home-manager/archive/release-${NIXOS_VERSION}.tar.gz" home-manager
	@sudo nix-channel --add "https://nixos.org/channels/nixpkgs-unstable" nixpkgs-unstable

$(NIXOS_PREFIX)/configuration.nix:
	@sudo mkdir -p "$(NIXOS_PREFIX)"
	@echo "import $(PWD)/dotfiles \"$$(hostname)\"" | sudo tee "$(NIXOS_PREFIX)/configuration.nix"

secrets.nix: secrets.nix.gpg
	gpg -dq $< > $@


# Convenience aliases
i: install
t: test
s: switch
up: upgrade


.PHONY: update config channels test upgrade install
