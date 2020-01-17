{ lib, pkgs, python2 }:

with python2.pkgs;
buildPythonPackage rec {
  pname = "linode-cli";
  version = "2.12.0";
  format = "wheel";

  src = fetchPypi {
    inherit version format;
    pname = "linode_cli";
    sha256 = "d5a91327c7ce41ac63fe4436d6a2469f50ddada217d45724f1de16dc8e1e8191";
  };

  propagatedBuildInputs = [ terminaltables requests wheel setuptools enum34 colorclass pyaml ];

  meta = with lib; {
    homepage = "https://github.com/linode/linode-cli";
    description = "The Linode CLI";
    license = licenses.bsd3;
    maintainers = [ maintainers.hlissner ];
  };
}
