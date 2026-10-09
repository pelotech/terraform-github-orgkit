{
  description = "terraform-github-orgkit dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.treefmt-nix.flakeModule ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        { pkgs, ... }:
        {
          devShells.default = pkgs.mkShell {
            # tenv's terraform proxy installs the version pinned in .terraform-version
            env.TENV_AUTO_INSTALL = "true";
            packages = with pkgs; [
              # terraform
              tenv

              # pre-commit
              prek
              tflint
              hcledit
              yamllint
              terraform-docs
              actionlint
              zizmor
            ];
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs.terraform.enable = true;
            programs.nixfmt.enable = true;
          };
        };
    };
}
