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
        echo BACKEND_BASE_URL=$(pass projects/bemyguide/prod/base-url) > app/.env;

        echo JWT_SECRET=$(pass projects/bemyguide/prod/jwt-secret) > backend/.dev.vars.production
        echo JWT_SECRET=test123 > backend/.dev.vars.dev
      ";
      before = [ "devenv:enterShell" ];
    };
  };

}
