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
        echo CLOUDFLARE_AI_BASE_URL=$(pass cloudflare/ai-gateway/baseurl) > app/.env;
        echo CLOUDFLARE_AI_TOKEN=$(pass cloudflare/ai-gateway/token) >> app/.env
        echo CLOUDFLARE_AI_MODEL=workers-ai/@cf/meta/llama-3.1-8b-instruct >> app/.env

        echo JWT_SECRET=$(pass projects/bemyguide/prod/jwt-secret) > backend/.dev.vars.production
        echo JWT_SECRET=test123 > backend/.dev.vars.dev
      ";
      before = [ "devenv:enterShell" ];
    };
  };

}
