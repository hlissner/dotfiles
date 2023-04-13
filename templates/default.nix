{ ... }:

rec {
  default = {
    path = ./many;
    description = "A multiple-host deployment of this framework.";
  };

  one = {
    path = ./one;
    description = "A single-host deployment of this framework.";
  };
}
