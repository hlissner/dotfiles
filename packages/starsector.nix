{ lib
, alsa-lib
, fetchzip
, libXxf86vm
, makeWrapper
, openjdk8
, stdenv
, xorg
}:

stdenv.mkDerivation rec {
  pname = "starsector";
  version = "0.95.1a-RC6";

  src = fetchzip {
    url = "https://s3.amazonaws.com/fractalsoftworks/starsector/starsector_linux-${version}.zip";
    sha256 = "sha256-+0zGJHM+SMonx3sytCQNQA/QBgzdPMEfQvOjrCDSOs8=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = with xorg; [
    alsa-lib
    libXxf86vm
  ];

  dontBuild = true;

  # need to cd into $out in order for classpath to pick up correct jar files
  installPhase = ''
    mkdir -p $out/bin
    rm -r jre_linux # remove jre7
    rm starfarer.api.zip
    cp -r ./* $out
    wrapProgram $out/starsector.sh \
      --prefix PATH : ${lib.makeBinPath [ openjdk8 ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
      --run "mkdir -p \$XDG_DATA_HOME/starsector; cd $out"
    ln -s $out/starsector.sh $out/bin/starsector
  '';

  # it tries to run everything with relative paths, which makes it CWD dependent
  # also point mod, screenshot, and save directory to $XDG_DATA_HOME
  postPatch = ''
    substituteInPlace starsector.sh \
      --replace "./jre_linux/bin/java" "${openjdk8}/bin/java" \
      --replace "./native/linux" "$out/native/linux" \
      --replace "./" "\$XDG_DATA_HOME/starsector/"
  '';

  meta = with lib; {
    description = "Open-world single-player space-combat, roleplaying, exploration, and economic game";
    homepage = "https://fractalsoftworks.com";
    license = licenses.unfree;
    maintainers = with maintainers; [ bbigras ];
  };
}
