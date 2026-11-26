{ pkgs, ...}:
let
  myPhp = pkgs.php.withExtensions ({ enabled, all }:
    enabled ++ [ all.xdebug all.redis all.intl ]);
in {
  home.stateVersion = "26.11";

home.sessionVariables = {
  EDITOR = "hx";
  VISUAL = "hx";
};

imports = [
 ./niri.nix
 ./terminal.nix
 ./vim.nix
];

  home.packages = with pkgs; [
    #system
      jq
      xwayland-satellite
      noctalia
      ghostty
      yazi
      helix
      thunar

    #take short
      grim
      slurp
      
    #office
      libreoffice

    # browser
      firefox

    #IDE
      phpstorm
      dbeaver-bin
      rust-rover
      
    #AI
      opencode
      claude-code

    #project-manager
      git
      gh      

    #programs lauguage
      #Rust
        rustc
        cargo
        gcc
        pkg-config
        openssl
        rust-analyzer
        clippy
        rustfmt

      #Go
        go
        gopls
        gotools
        delve
        golangci-lint

      #Php
        myPhp
        myPhp.packages.composer
        myPhp.packages.php-cs-fixer
        phpstan
        phpactor        

      #Zig
        zig
        zls

      #js
        nodejs
  ];

  programs.home-manager.enable = true;
}
