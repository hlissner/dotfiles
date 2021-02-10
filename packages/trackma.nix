{ lib, python3 }:

with python3.pkgs;
buildPythonApplication rec {
  pname = "Trackma";
  version = "0.8.4";

  src = fetchPypi {
    inherit pname version;
    sha256 = "9UHhxpbDcjW42JlefDHkTor1TdKmCQ1a1u0JS0Rt79k=";
  };

  # No tests included
  doCheck = false;
  pythonImportsCheck = [ "trackma" ];

  meta = with lib; {
    homepage    = "https://github.com/z411/trackma";
    description = "Open multi-site list manager for Unix-like systems. (ex-wMAL)";
    license     = licenses.gpl3;
    platforms = [ "x86_64-linux" ];
    maintainers = [];
  };
}
