# callPackage
{
  lib,
  stdenv,
  glibcLocales,
  removeReferencesTo,
  graalvmPackages,
}:

lib.extendMkDerivation {
  constructDrv = stdenv.mkDerivation;

  excludeDrvArgNames = [
    "LC_ALL"
    "executable"
    "extraNativeImageBuildArgs"
    "graalvmDrv"
    "jar"
  ];

  extendDrvArgs =
    finalAttrs:
    {
      src,
      jar ? src,
      executable ? null,

      # The GraalVM derivation to use
      graalvmDrv ? graalvmPackages.graalvm-ce,

      # Default native-image arguments. You probably don't want to set this,
      # except in special cases. In most cases, use extraNativeBuildArgs instead
      nativeImageBuildArgs ? null,

      # Extra arguments to be passed to the native-image
      extraNativeImageBuildArgs ? [ ],

      # XMX size of GraalVM during build
      graalvmXmx ? "-J-Xmx6g",

      LC_ALL ? "en_US.UTF-8",

      env ? { },
      meta ? { },
      passthru ? { },
      ...
    }@args:
    let
      executable' = if executable == null then finalAttrs.meta.mainProgram else executable;

      nativeImageBuildArgs' =
        if nativeImageBuildArgs != null then
          nativeImageBuildArgs
        else
          [
            (lib.optionalString stdenv.hostPlatform.isDarwin "-H:-CheckToolchain")
            (lib.optionalString (
              stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isAarch64
            ) "-H:PageSize=64K")
            "-H:Name=${executable'}"
            "-march=compatibility"
            "--verbose"
          ];
    in

    {
      strictDeps = args.strictDeps or true;
      __structuredAttrs = args.__structuredAttrs or true;

      env = {
        inherit LC_ALL;
      } // env;

      inherit jar;

      dontUnpack = args.dontUnpack or (jar == finalAttrs.src);

      nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [
        graalvmDrv
        glibcLocales
        removeReferencesTo
      ];

      nativeImageBuildArgs = nativeImageBuildArgs' ++ extraNativeImageBuildArgs ++ [ graalvmXmx ];

      buildPhase =
        args.buildPhase or ''
          runHook preBuild

          native-image -jar "$jar" ''${nativeImageBuildArgs[@]}

          runHook postBuild
        '';

      installPhase =
        args.installPhase or ''
          runHook preInstall

          install -Dm755 ${executable'} -t $out/bin

          runHook postInstall
        '';

      postInstall = ''
        remove-references-to -t ${graalvmDrv} $out/bin/${executable'}
        ${args.postInstall or ""}
      '';

      disallowedReferences = [ graalvmDrv ];

      passthru = {
        inherit graalvmDrv;
      } // passthru;

      meta =
        {
          # default to graalvm's platforms
          inherit (graalvmDrv.meta) platforms;
        }
        // lib.optionalAttrs (executable != null) {
          mainProgram = executable;
        }
        // meta;
    };
}
