{ ... }:

{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.bat = {
    enable = true;
  };
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Shota Arakaki";
        email = "syotaa1@gmail.com";
      };
      credential."https://github.com".helper = "!op plugin run -- gh auth git-credential";
    };
    ignores = [ ".DS_Store" ];
  };
  programs.difftastic = {
    enable = true;
    git.enable = true;
  };
  programs.vim = {
    enable = true;
    defaultEditor = true;
  };
  programs.vscode = {
    enable = true;
  };
  programs.poetry = {
    enable = true;
    settings = {
      virtualenvs.create = true;
      virtualenvs.in-project = true;
    };
  };
}
