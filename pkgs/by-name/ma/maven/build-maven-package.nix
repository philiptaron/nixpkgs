{
  lib,
  stdenv,
  jdk,
  pem-to-java-pkcs12,
  maven,
  writers,
}:
let
  buildMavenPackage =
    {
      src,
      sourceRoot ? null,
      buildOffline ? false,
      doCheck ? true,
      prePatch ? null,
      patches ? [ ],
      postPatch ? null,
      pname,
      version,
      mvnJdk ? maven.jdk or jdk,
      mvnHash ? "",
      /**
        Maven goal to execute. Normally the the default should be used, but some special cases need other goals.
      */
      mvnGoal ? "package",
      /**
        Set the Maven offline argument, `-o`. Normally the default is preferred, but to call `mvn deploy` with
        a directory destination `-o` must be removed. In that case we rely on the Nix sandbox to keep things hermetic.
      */
      mvnOffline ? true,
      mvnFetchExtraArgs ? { },
      mvnDepsParameters ? "",
      manualMvnArtifacts ? [ ],
      manualMvnSources ? [ ],
      mvnParameters ? "",
      ...
    }@args:

    # originally extracted from dbeaver
    # created to allow using maven packages in the same style as rust

    let
      mvnSkipTests = lib.optionalString (!doCheck) "-DskipTests";

      writeProxySettings = writers.writePython3 "write-proxy-settings" { } ./maven-proxy.py;

      fetchedMavenDeps = stdenv.mkDerivation (
        {
          pname = "maven-deps-${pname}";
          inherit
            src
            sourceRoot
            prePatch
            patches
            postPatch
            version
            ;

          nativeBuildInputs = [
            maven
            pem-to-java-pkcs12
          ]
          ++ args.nativeBuildInputs or [ ];

          env = mvnFetchExtraArgs.env or { } // {
            JAVA_HOME = mvnJdk;
          };

          impureEnvVars = lib.fetchers.proxyImpureEnvVars;

          buildPhase = ''
            runHook preBuild

            MAVEN_EXTRA_ARGS="-B"

            # handle proxy
            if [[ -n "''${HTTP_PROXY-}" ]] || [[ -n "''${HTTPS_PROXY-}" ]] || [[ -n "''${NO_PROXY-}" ]];then
              mvnSettingsFile="$(mktemp -d)/settings.xml"
              ${writeProxySettings} $mvnSettingsFile
              MAVEN_EXTRA_ARGS="$MAVEN_EXTRA_ARGS -s=$mvnSettingsFile"
            fi

            # trust an impure NIX_SSL_CERT_FILE, e.g. one with a proxy's CA
            if [[ -r "''${NIX_SSL_CERT_FILE-}" ]]; then
              echo "using $NIX_SSL_CERT_FILE as trust store"
              pem-to-java-pkcs12 "$NIX_SSL_CERT_FILE" "$NIX_BUILD_TOP/cacerts"
              MAVEN_EXTRA_ARGS="$MAVEN_EXTRA_ARGS -Djavax.net.ssl.trustStore=$NIX_BUILD_TOP/cacerts"
            fi
          ''
          + lib.optionalString buildOffline ''
            mvn $MAVEN_EXTRA_ARGS de.qaware.maven:go-offline-maven-plugin:1.2.8:resolve-dependencies -Dmaven.repo.local=$out/.m2 ${mvnDepsParameters}

            for artifactId in ${toString manualMvnArtifacts}
            do
              echo "downloading manual $artifactId"
              mvn $MAVEN_EXTRA_ARGS dependency:get -Dartifact="$artifactId" -Dmaven.repo.local=$out/.m2
            done

            for artifactId in ${toString manualMvnSources}
            do
              group=$(echo $artifactId | cut -d':' -f1)
              artifact=$(echo $artifactId | cut -d':' -f2)
              echo "downloading manual sources $artifactId"
              mvn $MAVEN_EXTRA_ARGS dependency:sources -DincludeGroupIds="$group" -DincludeArtifactIds="$artifact" -Dmaven.repo.local=$out/.m2
            done
          ''
          + lib.optionalString (!buildOffline) ''
            mvn $MAVEN_EXTRA_ARGS package -Dmaven.repo.local=$out/.m2 ${mvnSkipTests} ${mvnParameters}
          ''
          + ''
            runHook postBuild
          '';

          # Preserve .meta because Tycho needs p2-artifacts.properties for offline builds.
          # Maven Resolver's cached prefix indexes are volatile, so remove them and their checksums.
          installPhase = ''
            runHook preInstall

            find $out -type f \( \
              -name \*.lastUpdated \
              -o -name resolver-status.properties \
              -o -name _remote.repositories \) \
              -delete
            rm -f "$out"/.m2/.meta/prefixes-*.txt{,.*}

            runHook postInstall
          '';

          # don't do any fixup
          dontFixup = true;
          outputHashAlgo = if mvnHash != "" then null else "sha256";
          outputHashMode = "recursive";
          outputHash = mvnHash;
        }
        // (removeAttrs mvnFetchExtraArgs [ "env" ])
      );
    in
    stdenv.mkDerivation (
      removeAttrs args [ "mvnFetchExtraArgs" ]
      // {
        inherit fetchedMavenDeps;

        nativeBuildInputs = args.nativeBuildInputs or [ ] ++ [
          maven
        ];

        env = args.env or { } // {
          JAVA_HOME = mvnJdk;
        };

        buildPhase = ''
          runHook preBuild

          mvnDeps=$(cp -dpR ${fetchedMavenDeps}/.m2 ./ && chmod +w -R .m2 && pwd)
          runHook afterDepsSetup
          mvn ${mvnGoal} ${
            if mvnOffline then "-o" else ""
          } -nsu "-Dmaven.repo.local=$mvnDeps/.m2" ${mvnSkipTests} ${mvnParameters}

          runHook postBuild
        '';

        meta = args.meta or { } // {
          platforms = args.meta.platforms or maven.meta.platforms;
        };
      }
    );
in
fnOrAttrs:
let
  finalPackage =
    if !lib.isFunction fnOrAttrs then
      buildMavenPackage fnOrAttrs
    else
      let
        finalAttrs = fnOrAttrs (finalAttrs // { inherit finalPackage; });
      in
      buildMavenPackage finalAttrs;
in
finalPackage
