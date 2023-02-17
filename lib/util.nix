{ lib, ... }:

rec {
  boolTo = bool: trueStr: falseStr:
    if (bool == false || bool == null || bool == 0)
    then falseStr
    else trueStr;
  boolToStr = bool: boolTo bool "true" "false";
}
