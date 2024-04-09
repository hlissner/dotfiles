final: prev: {
  rofi-unwrapped = prev.rofi-unwrapped.overrideDerivation (old: {
    version = "1.7.5-dev-fork";

    src = prev.fetchFromGitHub {
      owner = "hlissner";
      repo = "rofi";
      rev = "634e4455e5a3904d975e69cfadfaa08bbf79cbc1";
      sha256 = "1bsfkis66dmfmwcbvw802ih7fwih9vzj8v7iv7llmlyal25d6jpz";
      fetchSubmodules = true;
    };
  });
}
