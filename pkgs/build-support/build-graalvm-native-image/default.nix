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
    "extraNativeImageBuildArgs"
    "graalvmDrv"
  ];

  extendDrvArgs =
    finalAttrs:
    {
      dontUnpack ? true,
      strictDeps ? true,
      __structuredAttrs ? true,

      # The GraalVM derivation to use
      graalvmDrv ? graalvmPackages.graalvm-ce,

      # Extra arguments to be passed to the native-image
      extraNativeImageBuildArgs ? [ ],

      env ? { },
      meta ? { },
      passthru ? { },
      ...
    }@args:
    let
      executable = finalAttrs.meta.mainProgram;

      # XMX size of GraalVM during build
      graalvmXmx = "-J-Xmx6g";
    in
    {
      env = {
        LC_ALL = "en_US.UTF-8";
      } // env;

      inherit dontUnpack strictDeps __structuredAttrs;

      nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [
        graalvmDrv
        glibcLocales
        removeReferencesTo
      ];

      # Default native-image arguments. You probably don't want to set this,
      # except in special cases. In most cases, use extraNativeBuildArgs instead
      nativeImageBuildArgs =
        args.nativeImageBuildArgs or (
          [
            (lib.optionalString stdenv.hostPlatform.isDarwin "-H:-CheckToolchain")
            (lib.optionalString (
              stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isAarch64
            ) "-H:PageSize=64K")
            "-H:Name=${executable}"
            "-march=compatibility"
            "--verbose"
          ]
          ++ extraNativeImageBuildArgs
          ++ [ graalvmXmx ]
        );

      buildPhase =
        args.buildPhase or ''
          runHook preBuild

          native-image -jar "$src" ''${nativeImageBuildArgs[@]}

          runHook postBuild
        '';

      installPhase =
        args.installPhase or ''
          runHook preInstall

          install -Dm755 ${executable} -t $out/bin

          runHook postInstall
        '';

      postInstall = ''
        remove-references-to -t ${graalvmDrv} $out/bin/${executable}
        ${args.postInstall or ""}
      '';

      disallowedReferences = [ graalvmDrv ];

      passthru = {
        inherit graalvmDrv;
      } // passthru;

      meta = {
        # default to graalvm's platforms
        inherit (graalvmDrv.meta) platforms;
      } // meta;
    };
}
