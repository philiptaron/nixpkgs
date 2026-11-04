{
  stdenvNoCC,
  pem-to-java-pkcs12,
  cacert,
}:

stdenvNoCC.mkDerivation {
  pname = "${cacert.pname}-java-pkcs12";
  inherit (cacert) version;

  nativeBuildInputs = [ pem-to-java-pkcs12 ];

  buildCommand = ''
    pem-to-java-pkcs12 ${cacert}/etc/ssl/certs/ca-bundle.crt "$out"
  '';
}
