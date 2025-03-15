{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "dpms-off";
  version = "0-unstable-2025-06-17";

  src = fetchFromGitHub {
    owner = "lilydjwg";
    repo = "dpms-off";
    rev = "08acbb5a835c28e3fa7d016cde9c2d7045747976";
    hash = "sha256-rT/D0ycQwh7S5i0CtGIzhg83sFdujCvmY0YWTC0Tszg=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-D0TIdhQw9hqfxKoDWsvs+T5Q6vCfm9VMcPUvQm25joQ=";

  meta = {
    description = "Turn off monitors to save power (for Wayland)";
    homepage = "https://github.com/lilydjwg/dpms-off";
    license = lib.licenses.asl20;
    maintainers = [ lib.maintainers.philiptaron ];
    mainProgram = "dpms-off";
  };
}
