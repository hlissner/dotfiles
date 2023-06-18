final: prev: {
  rofi-unwrapped = prev.rofi-unwrapped.overrideDerivation (old: {
    version = "1.7.5-dev-fork";

    src = prev.fetchFromGitHub {
      owner = "hlissner";
      repo = "rofi";
      rev = "32ffee7ddd962a23624cccd2f4e059aa1a8a9e53";
      sha256 = "0l71r79dj1n1bycnlllxqzkkq33lsg1jxy86c8n86b3i8hj4k2px";
      fetchSubmodules = true;
    };
  });
}
