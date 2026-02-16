# Run:
#   $ nix-instantiate --eval 'modules/generic/meta-maintainers/test.nix'
#
# Expected output:
#   { }
#
# Debugging:
#   drop .test from the end of this file, then use nix repl on it
let
  ghost = {
    github = "ghost";
    githubId = 0;
    name = "ghost";
  };
in
rec {
  lib = import ../../../lib;

  # Inject ghost into lib.maintainers so it passes the addCheck validation
  testLib = lib // {
    maintainers = lib.maintainers // { ghost = ghost; };
  };

  example = lib.evalModules {
    specialArgs = { lib = testLib; };
    modules = [
      ../meta-maintainers.nix
      {
        _file = "ghost.nix";
        meta.maintainers = [ ghost ];
      }
    ];
  };

  test =
    assert
      example.config.meta.maintainers == {
        ${toString ../meta-maintainers.nix} = [
          testLib.maintainers.pierron
          testLib.maintainers.roberth
        ];
        "ghost.nix" = [ ghost ];
      };
    { };

}
.test
