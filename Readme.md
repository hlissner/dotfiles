Oye, tu. Finalmente estás despierto. Estabas intentando configurar tu sistema operativo de forma declarativa, ¿verdad? Entré directamente en esa emboscada de NixOS, al igual que nosotros, y esos archivos de puntos de allí.



  

Cascarón:	zsh + zgen
DM:	lightdm + lightdm-mini-recibidor
WM:	bspwm + polybar
Editor:	Doom Emacs (y ocasionalmente vim )
Terminal:	S t
Lanzacohetes:	rofi
Navegador:	Firefox
Tema GTK:	Hormiga drácula
Inicio rápido
Yoink la última versión de NixOS 21.05 .
Inicie en el instalador.
Haga sus particiones y monte su raíz en /mnt( por ejemplo )
Instale estos archivos de puntos:
nix-shell -p git nixFlakes
git clone https://github.com/hlissner/dotfiles /mnt/etc/nixos
Instale NixOS : nixos-install --root /mnt --flake /mnt/etc/nixos#XYZ, donde XYZestá el host que desea instalar . Úselo #genericpara una configuración universal simple o cree un subdirectorio hosts/para su dispositivo. Consulte host / kuro para ver un ejemplo.
¡Reiniciar!
¡Cambie sus contraseñas rooty $USER!
administración
Y yo digo bin/hey. ¿Que esta pasando?

Usage: hey [global-options] [command] [sub-options]

Available Commands:
  check                  Run 'nix flake check' on your dotfiles
  gc                     Garbage collect & optimize nix store
  generations            Explore, manage, diff across generations
  help [SUBCOMMAND]      Show usage information for this script or a subcommand
  rebuild                Rebuild the current system's flake
  repl                   Open a nix-repl with nixpkgs and dotfiles preloaded
  rollback               Roll back to last generation
  search                 Search nixpkgs for a package
  show                   [ARGS...]
  ssh HOST [COMMAND]     Run a bin/hey command on a remote NixOS system
  swap PATH [PATH...]    Recursively swap nix-store symlinks with copies (or back).
  test                   Quickly rebuild, for quick iteration
  theme THEME_NAME       Quickly swap to another theme module
  update [INPUT...]      Update specific flakes or all of them
  upgrade                Update all flakes and rebuild system

Options:
    -d, --dryrun                     Don't change anything; preform dry run
    -D, --debug                      Show trace on nix errors
    -f, --flake URI                  Change target flake to URI
    -h, --help                       Display this help, or help for a specific command
    -i, -A, -q, -e, -p               Forward to nix-env
Preguntas frecuentes
¿Por qué NixOS?

Porque la configuración declarativa, generacional e inmutable es un regalo del cielo cuando tiene una flota de computadoras para administrar.

¿Cómo gestionas los secretos?

Con agenix .

¿Cómo cambio el nombre de usuario predeterminado?

Establezca la USERvariable de entorno la primera vez que ejecute nixos-install: USER=myusername nixos-install --root /mnt --flake /path/to/dotfiles#XYZ
O cambie "hlissner"en modules / options.nix.
¿Por qué escribiste bin / hey?

Envidio la CLI del Guix y quiero similar para NixOS, pero su cadena de herramientas se extiende por muchos comandos, ninguno de los cuales son tan intuitivo: nix, nix-collect-garbage, nixos-rebuild, nix-env, nix-shell.

No digo que heysea ​​la respuesta, pero a todo el mundo le gusta su propia cerveza.

¿Cómo 2 copos?

¿Sería la experiencia de NixOS si le diera todas las respuestas en un solo lugar conveniente?

No. Sufre mi dolor:

Un artículo de tweag de tres partes que todos han leído.
Una configuración sobre-diseñada para asustar a los principiantes.
Una configuración minimalista para principiantes asustados.
Una página wiki de nixos que detalla el formato de flake.nix.
Documentación oficial que nadie lee.
Algunos videos geniales sobre herramientas y piratería nixOS en general.
Un par escamas configuraciones que puede haber descaradamente revolvió a través .
Algunas notas sobre el uso de Nix
Lo que me ayudó a descubrir los generadores (para npm, yarn, python y haskell)
Lo que todos necesitarán cuando Nix los lleve a beber.
