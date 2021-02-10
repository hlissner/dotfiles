{ lib, python3, nodejs, aria2, coloredlogs }:

with python3.pkgs;
let
  pySmartDL = buildPythonPackage rec {
    pname = "pySmartDL";
    version = "1.3.4";
    src = fetchPypi {
      inherit pname version;
      sha256 = "NSddFpTzR00zvcqTsn02CCZf/UL1rrKOVvOLkGwMNfQ=";
    };
    doCheck = false;
  };
  cfscrape = buildPythonPackage rec {
    pname = "cfscrape";
    version = "2.0.5";
    src = fetchPypi {
      inherit pname version;
      sha256 = "2VwWsGdxJ9+uPqUp82AdFHTK5+MlJ44dnYmipz7yH6k=";
    };
    buildInputs = [ requests ];
    doCheck = false;
  };
in buildPythonApplication rec {
  pname   = "anime-downloader";
  version = "5.0.7";

  src = fetchPypi {
    inherit pname version;
    sha256 = "BP4Wf2efU1RUk6I+82rFcvEdxDSKonTOIZjm3B0x7Eg=";
  };

  propagatedBuildInputs = [
    aria2
    nodejs
    beautifulsoup4
    cfscrape
    click
    coloredlogs
    fuzzywuzzy
    pySmartDL
    pycryptodome
    requests
    requests-cache
    setuptools
    tabulate
  ];

  doCheck = false;

  meta = {
    homepage = "https://github.com/anime-dl/anime-downloader";
    description = "A simple but powerful anime downloader and streamer.";
    license = lib.licenses.unlicense;
    platforms = [ "x86_64-linux" ];
    maintainers = [];
  };
}
