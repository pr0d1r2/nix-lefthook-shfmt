# SPEC — flatten nix-lefthook-shfmt (drop nix-dev-shell-agentic)

## Goal
Remove the `nix-dev-shell-agentic` flake input from this repo so it stops
dragging the near-cyclic `agentic → cavekit → hooks → agentic` dependency
tree into every consumer's `flake.lock`. Replace it with `flake = false`
`-src` leaf inputs for the sibling hook repos + inline `pkgs.mkShell`
devShells, mirroring the proven `nix-lefthook-statix` template.

## Preserved outputs (MUST be identical)
- `packages.<system>.default` = `lefthook-shfmt`, built verbatim:
  `pkgs.writeShellApplication { name = "lefthook-shfmt";
   runtimeInputs = [ pkgs.shfmt ]; text = builtins.readFile ./lefthook-shfmt.sh; }`
- `devShells.<system>.default` and `devShells.<system>.ci` (names unchanged).
- `nixConfig` cachix substituter/key unchanged.
- `lefthook-shfmt.sh` logic unchanged (only a `shfmt -i2 -ci` reformat if needed).

## Input changes
### Remove
- `nix-dev-shell-agentic` (and its `inputs.nixpkgs.follows`).

### Keep
- `nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";`
- `nixpkgs.follows = "nixpkgs-lock/nixpkgs";`

### Add (all `flake = false` source leaves — github:pr0d1r2/<name>)
Mirror the statix template's wrapper set, but swap self↔sibling: this repo's
`lefthook.yml` remotes list its SIBLINGS — it lists `nix-lefthook-statix`
(not `nix-lefthook-shfmt`, since shfmt IS this repo / the package default).
So drop `-shfmt-src`, add `-statix-src`:

- nix-lefthook-bats-unit-src
- nix-lefthook-deadnix-src
- nix-lefthook-editorconfig-checker-src
- nix-lefthook-file-size-check-src
- nix-lefthook-git-conflict-markers-src
- nix-lefthook-git-no-local-paths-src
- nix-lefthook-missing-final-newline-src
- nix-lefthook-nixfmt-src
- nix-lefthook-shellcheck-src
- nix-lefthook-statix-src   (NEW — sibling; replaces self-shfmt wrapper)
- nix-lefthook-trailing-whitespace-src
- nix-lefthook-typos-src
- nix-lefthook-yamllint-src

(`bats-parse` and `nix-flake-check` remain runtime-only lefthook remotes,
not flake wrappers — same as the statix template, which also omits them.)

## devShell rebuild (inline, no agentic)
- `wrap = name: src: extra: pkgs.writeShellApplication ({ inherit name;
   text = builtins.readFile "${src}/${name}.sh"; } // extra);`
- `lefthookWrappersFor pkgs` → list of the 13 sibling wrappers above with
  their `runtimeInputs` (statix→[pkgs.statix], file-size-check special-cased
  exactly as the template does, etc.).
- `batsWithLibsFor pkgs` = `pkgs.bats.withLibraries [bats-support bats-assert bats-file]`.
- `ci` = `pkgs.mkShell { packages = ciCommon; BATS_LIB_PATH = "${batsWithLibs}/share/bats"; }`
- `default` = `pkgs.mkShell { packages = ciCommon; shellHook = replaceStrings
   @BATS_LIB_PATH@ → ${batsWithLibs} (readFile ./dev.sh); }`
- `ciCommon` includes `self.packages.<sys>.default` (lefthook-shfmt), bats,
  coreutils, git, lefthook, nix, parallel, shfmt + wrappers.

## Config
- `config/lefthook/file_size_limits.yml`: bump `nix: 4096 → 10240`
  (the flattened flake.nix is larger; matches statix template).

## Validation gate
1. `nix flake check` green.
2. `nix flake show` lists `packages.<sys>.default` only (= lefthook-shfmt).
3. `lefthook run pre-commit --all-files` passes inside `nix develop`
   (never --no-verify).
4. `flake.lock` node count drops substantially.

## Anti-bloat
No vendored external files. Changes limited to flake.nix, flake.lock
(regenerated), file_size_limits.yml, and a shfmt reformat of the .sh.
