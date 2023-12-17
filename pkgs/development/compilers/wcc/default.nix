{ lib
, stdenv
, fetchFromGitHub
, substituteAll
, capstone
, linenoise
, openlibm
, luajit_2_0
, libbfd
, libelf
, libiberty
}:

let
  luajit = luajit_2_0;
in

stdenv.mkDerivation {
  pname = "wcc";
  version = "0.0.4-unstable-2023-02-04";

  src = fetchFromGitHub {
    owner = "endrazine";
    repo = "wcc";
    rev = "825448004e5e53c3ab9a9dac0886544bc499d259";
    hash = "sha256-SZnZYgTGx8vrGt+suShCvkqIx7aDvFkhCySCYfMrODA=";
  };

  # Remove headers provided by upstream
  postUnpack = ''
    rm -f source/src/wsh/include/{lauxlib.h,linenoise.h,lua.h,luaconf.h,lualib.h}
  '';

  patches = [
    (substituteAll {
      src = ./fix-dependencies.patch;
      luajit = "${luajit}";
      openlibm = "${openlibm}";
      linenoise = "${linenoise}";
    })
  ];

  nativeBuildInputs = [ linenoise luajit openlibm ];

  buildInputs = [
    capstone
    libbfd
    libelf
    libiberty
  ];

  postPatch = ''
    sed -i src/wsh/include/libwitch/wsh.h src/wsh/scripts/INDEX \
      -e "s#/usr/share/wcc#$out/share/wcc#"
  '';

  installFlags = [ "DESTDIR=$(out)" ];

  preInstall = ''
    mkdir -p $out/usr/bin
  '';

  postInstall = ''
    mv $out/usr/* $out
    rmdir $out/usr
    mkdir -p $out/share/man/man1
    cp doc/manpages/*.1 $out/share/man/man1/
  '';

  preFixup = ''
    # Let patchShebangs rewrite shebangs with wsh.
    PATH+=:$out/bin
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "https://github.com/endrazine/wcc";
    description = "Witchcraft compiler collection: tools to convert and script ELF files";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ orivej ];
  };
}
