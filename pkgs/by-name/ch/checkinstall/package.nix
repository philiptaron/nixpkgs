{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  gettext,
  dpkg,
  file,
  util-linux,
  which,
  nix-update-script,
  runtimeShell,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "checkinstall";
  version = "1.8.3";

  src = fetchFromGitHub {
    owner = "ssgelm";
    repo = "checkinstall";
    tag = "v${finalAttrs.version}";
    hash = "sha256-JpfiESEdfPbPVkdzMgGBKnEmIIEHAp85GUts+Hu/psg=";
  };

  patches = [
    # installwatch logs faccessat() and euidaccess() calls since 1.8.0, but
    # the package file list only drops access() lines. Drop these too, or
    # every program a shell checks before running it ends up in the package.
    ./filter-access-family.patch

    # Include empty directories created by the installation script in
    # generated packages.  (E.g., if a `make install' does `mkdir
    # /var/lib/mystuff', then /var/lib/mystuff should be included in
    # the package.)
    ./empty-dirs.patch

    # Stop access() from copying the file it asks about into the package.
    # Otherwise every tool `make install` runs ends up in the package.
    (fetchpatch {
      name = "stop-access-materialising.patch";
      url = "https://github.com/ssgelm/checkinstall/commit/f2538619907e73b7d7183b7775a456f28ced6579.patch";
      hash = "sha256-g9TaRQDx4D75aBfrEXNkhUosqrkiZdBlPP2LMadIheo=";
    })
  ];

  nativeBuildInputs = [ gettext ];

  hardeningDisable = [ "fortify" ];

  makeFlags = [ "PREFIX=${placeholder "out"}" ];

  postPatch = ''
    patchShebangs tests
    # The scripts the tests install with have to run under a shell that
    # installwatch can be preloaded into. The sandbox's /bin/sh may be a
    # static busybox, which LD_PRELOAD cannot reach.
    substituteInPlace tests/tests/*.sh --replace-quiet '#!/bin/sh' '#!${runtimeShell}'

    substituteInPlace checkinstallrc-dist \
      --replace-fail /usr/local "$out"

    substituteInPlace installwatch/create-localdecls \
      --replace-fail /usr/include/unistd.h ${lib.getDev stdenv.cc.libc}/include/unistd.h
  '';

  postInstall =
    # Clear the RPATH, otherwise installwatch.so won't work properly
    # as an LD_PRELOADed library on applications that load against a
    # different Glibc.
    ''
      patchelf --set-rpath "" $out/lib/installwatch.so
    '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    dpkg
    file
    util-linux
    which
  ];
  installCheckPhase = ''
    runHook preInstallCheck

    # The sandbox has no /var/tmp, which is where checkinstall puts its
    # scratch files by default.
    mkdir -p "$NIX_BUILD_TOP/ck-tmp"
    sed "s|^BASE_TMP_DIR=.*|BASE_TMP_DIR=$NIX_BUILD_TOP/ck-tmp|" \
      $out/lib/checkinstall/checkinstallrc-dist > "$NIX_BUILD_TOP/checkinstallrc"

    CHECKINSTALL_INSTALLED=$out CHECKINSTALL_RC="$NIX_BUILD_TOP/checkinstallrc" \
      tests/run-tests.sh

    runHook postInstallCheck
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    homepage = "https://github.com/ssgelm/checkinstall";
    description = "Tool for automatically generating Slackware, RPM or Debian packages when doing `make install`";
    maintainers = with lib.maintainers; [ philiptaron ];
    platforms = lib.platforms.linux;
    license = lib.licenses.gpl2Only;
  };
})
