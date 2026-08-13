{
  description = "CHANGEME";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";

    set-and-setting.url = "github:pr0d1r2/set-and-setting";
    set-and-setting.inputs.nixpkgs-lock.follows = "nixpkgs-lock";
  };

  outputs =
    {
      self,
      nixpkgs,
      set-and-setting,
      ...
    }:
    set-and-setting.lib.mkConsumerFlake {
      inherit self nixpkgs set-and-setting;
      # The pinned set-and-setting actionlint helper still passes a scalar
      # regex to sourceByRegex. Keep the actions fragment in materialization
      # (it is part of the canonical hook) and replace only that broken
      # generated check with the same check using the current API.
      lib = set-and-setting.lib // {
        checksFor = args:
          set-and-setting.lib.checksFor (args // {
            fragments = builtins.filter (fragment: fragment != "actions") args.fragments;
          })
          // {
            actionlint = args.pkgs.runCommand "actionlint-check" { } ''
              cd ${nixpkgs.lib.sources.sourceByRegex args.src [ "^\\.github/workflows/.*" ]}
              mapfile -t files < <(find . -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)
              if [ ''${#files[@]} -gt 0 ]; then
                ${args.pkgs.actionlint}/bin/actionlint "''${files[@]}"
              fi
              touch $out
            '';
          };
      };
      fragments = [
        "base"
        "actions"
        "nix"
        "shell"
        "ascii"
        "markdown"
        "yaml"
      ];
      extraPackages = pkgs: {
        default = pkgs.writeShellApplication {
          name = "lefthook-shfmt";
          runtimeInputs = [ pkgs.shfmt ];
          text = builtins.readFile ./lefthook-shfmt.sh;
        };
      };
      src = ./.;
    };
}
