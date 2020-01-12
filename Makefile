NIXOS_VERSION := 19.09
NIXOS_PREFIX  := $(PREFIX)/etc/nixos
NIXOS_FLAGS   := -I my=$(PWD)


all: channels config secrets.nix test

install: result channels update config
	@nixos-generate-config --root "$(PREFIX)"
	@nixos-install --root "$(PREFIX)"

upgrade: update switch

switch:
	@sudo nixos-rebuild $(NIXOS_FLAGS) switch

test:
	@sudo nixos-rebuild $(NIXOS_FLAGS) test

clean:
	@rm -f secrets.nix


# Parts
update:
	@sudo nix-channel --update

config: $(NIXOS_PREFIX)/configuration.nix

channels:
	sudo nix-channel --add "https://nixos.org/channels/nixos-${NIXOS_VERSION}" nixos
	sudo nix-channel --add "https://github.com/rycee/home-manager/archive/release-${NIXOS_VERSION}.tar.gz" home-manager
	sudo nix-channel --add "https://nixos.org/channels/nixpkgs-unstable" nixpkgs-unstable

$(NIXOS_PREFIX)/configuration.nix:
	@sudo mkdir -p "$(NIXOS_PREFIX)"
	@echo "import ../dotfiles \"$$(hostname)\"" | sudo tee "$(NIXOS_PREFIX)/configuration.nix"

secrets.nix: secrets.nix.gpg
	gpg -dq $< > $@

.PHONY: update config channels test upgrade install
