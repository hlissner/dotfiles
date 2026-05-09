{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.quickshell;
    quickshell03 = pkgs.unstable.quickshell.overrideAttrs (old: rec {
      version = "0.3.0";
      src = pkgs.fetchFromGitea {
        domain = "git.outfoxxed.me";
        owner = "quickshell";
        repo = "quickshell";
        tag = "v${version}";
        hash = "sha256-gU+VGpwGJ2vvg0mtYqVvj5u+2LteuHlpokH6JSAtueY=";
      };
      buildInputs = old.buildInputs ++ (with pkgs.unstable; [
        glib
        polkit
        cpptrace
      ]);
      nativeBuildInputs = old.nativeBuildInputs ++ (with pkgs.unstable; [
        vulkan-headers
      ]);
      cmakeFlags = [
        (lib.cmakeFeature "DISTRIBUTOR" "Nixpkgs")
        (lib.cmakeBool "DISTRIBUTOR_DEBUGINFO_AVAILABLE" true)
        (lib.cmakeBool "DO_NOT_CHECK_CPPTRACE_USABILITY" true)
        (lib.cmakeFeature "INSTALL_QML_PREFIX" pkgs.unstable.qt6.qtbase.qtQmlPrefix)
        (lib.cmakeFeature "GIT_REVISION" "tag-v${version}")
      ];
    });
    quickshellRuntimeDeps = with pkgs.unstable; [
      quickshell03
      kdePackages.qtbase
      kdePackages.qtdeclarative
      kdePackages.qtmultimedia
      kdePackages.qtpositioning
      kdePackages.qtsensors
      kdePackages.qtsvg
      kdePackages.qtwayland
      kdePackages.qtimageformats
      kdePackages.kirigami
      kdePackages.kdialog
      kdePackages.syntax-highlighting
      kdePackages.qt5compat
      adwaita-icon-theme
    ];
    qmlRuntimeDeps = quickshellRuntimeDeps ++ (with pkgs.unstable; [
      # `kdePackages.kirigami` is a wrapper with only propagation metadata; the
      # imported end4 Waffle family needs the actual org.kde.kirigami QML files.
      kdePackages.kirigami.unwrapped
    ]);
    qmlImportPath = makeSearchPath "lib/qt-6/qml" qmlRuntimeDeps;
    qtPluginPath = makeSearchPath "lib/qt-6/plugins" quickshellRuntimeDeps;
    quickshellPackage = pkgs.symlinkJoin {
      name = "axiom-quickshell";
      paths = quickshellRuntimeDeps;
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        for bin in quickshell qs; do
          if [[ -e "$out/bin/$bin" ]]; then
            target="$(readlink -f "$out/bin/$bin")"
            rm "$out/bin/$bin"
            makeWrapper "$target" "$out/bin/$bin" \
              --prefix QML2_IMPORT_PATH : "${qmlImportPath}" \
              --prefix QML_IMPORT_PATH : "${qmlImportPath}" \
              --prefix QT_PLUGIN_PATH : "${qtPluginPath}"
          fi
        done
      '';
      meta.mainProgram = "quickshell";
    };
    iiPython = pkgs.python3.withPackages (ps: with ps; [
      click
      loguru
      materialyoucolor
      numpy
      opencv4
      pillow
      pygobject3
      tqdm
    ]);
    iiPythonEnv = pkgs.runCommand "illogical-impulse-python-env" {} ''
      mkdir -p "$out/bin"
      ln -s ${iiPython}/bin/python "$out/bin/python"
      ln -s ${iiPython}/bin/python3 "$out/bin/python3"
      cat > "$out/bin/activate" <<EOF
      export PATH="$out/bin:\$PATH"
      deactivate() { unset -f deactivate; }
      EOF
    '';
    cliphistWatcher = pkgs.writeShellApplication {
      name = "axiom-cliphist-watch";
      runtimeInputs = [ cfg.package pkgs.wl-clipboard pkgs.cliphist ];
      text = ''
        wl-paste --type text --watch bash -c 'cliphist store; qs -c ${cfg.configName} ipc call cliphistService update >/dev/null 2>&1 || true' &
        text_pid=$!
        wl-paste --type image --watch bash -c 'cliphist store; qs -c ${cfg.configName} ipc call cliphistService update >/dev/null 2>&1 || true' &
        image_pid=$!

        trap 'kill "$text_pid" "$image_pid" 2>/dev/null || true' INT TERM EXIT
        wait -n "$text_pid" "$image_pid"
      '';
    };
in {
  options.modules.desktop.quickshell = with types; {
    enable = mkBoolOpt false;
    package = mkOpt package quickshellPackage;
    configName = mkOpt str "ii";
    illogicalImpulsePythonEnv = mkOpt package iiPythonEnv;
    search.clipboard = {
      enable = mkBoolOpt true;
      backend = mkOpt (enum [ "cliphist" ]) "cliphist";
      maxEntries = mkOpt int 500;
      maxEntryBytes = mkOpt int (64 * 1024);
    };
    phase4Services.enable = mkBoolOpt true;
    polkitAgent.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cfg.package
      cfg.illogicalImpulsePythonEnv
      cliphistWatcher
      fuzzel
      gtk3
      xdg-utils
      wl-clipboard
      cliphist
      wlogout
      libnotify
      pamixer
      brightnessctl
      ddcutil
      playerctl
      wireplumber
      networkmanager
      bluez
      networkmanagerapplet
      blueman
      pavucontrol
      jq
      bc
      curl
      libsecret
      tesseract
    ] ++ optionals cfg.phase4Services.enable (with pkgs; [
      cava
      songrec
      libqalculate
      matugen
      swww
      imagemagick
      ffmpeg
      mpvpaper
      power-profiles-daemon
      procps
      lm_sensors
      kdePackages.kdialog
    ]);

    fonts.packages = mkIf cfg.phase4Services.enable (with pkgs; [
      material-symbols
      googlesans-code
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-cjk-sans
    ]);

    boot.kernelModules = mkIf cfg.phase4Services.enable [ "i2c-dev" ];
    hardware.i2c.enable = mkIf cfg.phase4Services.enable true;
    users.groups.i2c = mkIf cfg.phase4Services.enable {};
    user.extraGroups = mkIf cfg.phase4Services.enable [ "video" "input" "i2c" ];

    security.polkit.enable = mkIf cfg.phase4Services.enable true;
    services.power-profiles-daemon.enable = mkIf cfg.phase4Services.enable true;

    systemd.user.services.axiom-polkit-agent = mkIf (cfg.phase4Services.enable && cfg.polkitAgent.enable) {
      description = "Axiom graphical polkit agent";
      wantedBy = [ "hyprland-session.target" ];
      after = [ "hyprland-session.target" ];
      partOf = [ "hyprland-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    systemd.user.services.quickshell = {
      description = "Axiom Quickshell product shell";
      wantedBy = [ "hyprland-session.target" ];
      after = [ "hyprland-session.target" ];
      partOf = [ "hyprland-session.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/quickshell --config ${cfg.configName}";
        Restart = "on-failure";
        RestartSec = 2;
      };
      environment = {
        ILLOGICAL_IMPULSE_VIRTUAL_ENV = "${cfg.illogicalImpulsePythonEnv}";
      };
    };

    systemd.user.services.axiom-clipboard-history = mkIf cfg.search.clipboard.enable {
      description = "Axiom clipboard history watcher";
      wantedBy = [ "hyprland-session.target" ];
      after = [ "hyprland-session.target" ];
      partOf = [ "hyprland-session.target" ];
      serviceConfig = {
        ExecStart = "${cliphistWatcher}/bin/axiom-cliphist-watch";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    home.configFile = {
      "quickshell/${cfg.configName}" = {
        source = "${hey.configDir}/quickshell/${cfg.configName}";
        recursive = true;
      };
      "matugen" = {
        source = "${hey.configDir}/matugen";
        recursive = true;
      };
      "fuzzel" = {
        source = "${hey.configDir}/fuzzel";
        recursive = true;
      };
    };

    hey.hooks.reload."94-quickshell" = ''
      hey.do systemctl --user restart quickshell.service
    '';
  };
}
