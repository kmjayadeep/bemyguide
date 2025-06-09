{ pkgs, ... }:

{

  cachix.enable = false;

  android = {
    enable = true;
    flutter.enable = true;
  };
}
