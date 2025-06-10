{ pkgs, ... }:

{

  cachix.enable = false;

  android = {
    enable = true;
    flutter.enable = true;
  };

  devcontainer.enable = true;

  tasks = {
    "dotenv:init" = {
      exec = "
        echo CLOUDFLARE_AI_URL=$(pass cloudflare/ai-gateway/url) > app/.env;
        echo CLOUDFLARE_AI_TOKEN=$(pass cloudflare/ai-gateway/token) >> app/.env
      ";
      before = [ "devenv:enterShell" ];
    };
  };

}
