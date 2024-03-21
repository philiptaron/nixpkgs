{ lib
, buildPythonPackage
, fetchFromGitHub
, poetry-core
, apkinspector
, dataset
, frida-python
, future
, networkx
, pygments
, loguru
, lxml
, colorama
, matplotlib
, mutf8
, asn1crypto
, click
, pydot
, ipython
, packaging
, pyqt5
, pyperclip
, pyyaml
, nose
, nose-timer
, mock
, python-magic
, codecov
, coverage
, qt5
# This is usually used as a library, and it'd be a shame to force the GUI
# libraries to the closure if GUI is not desired.
, withGui ? false
# Tests take a very long time, and currently fail, but next release' tests
# shouldn't fail
, doCheck ? false
}:

buildPythonPackage rec {
  pname = "androguard";
  version = "4.1.1";
  pyproject = true;

  src = fetchFromGitHub {
    repo = pname;
    owner = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-P6GUKUZZFTTKkGokmhKAnzWEijh+4bKYLbpGpEBdY5U=";
  };

  postPatch = ''
    # Already provided by Nix
    sed -i "s/^PyQt5-Qt5.*//" pyproject.toml
  '' + lib.optionalString (!withGui) ''
    sed -i "s/^PyQt5.*//" pyproject.toml

    # The UI is standalone.
    rm -rf androguard/ui
  '';

  nativeBuildInputs = [
    packaging
    poetry-core
  ] ++ lib.optionals withGui [
    qt5.wrapQtAppsHook
  ];

  propagatedBuildInputs = [
    apkinspector
    asn1crypto
    click
    colorama
    dataset
    future
    frida-python
    ipython
    loguru
    lxml
    matplotlib
    mutf8
    networkx
    pydot
    pygments
    pyyaml
  ] ++ lib.optionals withGui [
    pyqt5
    pyperclip
  ];

  nativeCheckInputs = [
    codecov
    coverage
    mock
    nose
    nose-timer
    pyperclip
    pyqt5
    python-magic
  ];

  inherit doCheck;

  # If it won't be verbose, you'll see nothing going on for a long time.
  checkPhase = ''
    runHook preCheck
    nosetests --verbosity=3
    runHook postCheck
  '';

  preFixup = lib.optionalString withGui ''
    makeWrapperArgs+=("''${qtWrapperArgs[@]}")
  '';

  meta = with lib; {
    description = "Tool and Python library to interact with Android Files";
    homepage = "https://github.com/androguard/androguard";
    license = licenses.asl20;
    maintainers = with maintainers; [ pmiddend ];
  };
}
