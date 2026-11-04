{
  lib,
  writeShellApplication,
  gnused,
  openssl,
}:

writeShellApplication {
  name = "pem-to-java-pkcs12";

  runtimeInputs = [
    gnused
    openssl
  ];

  # Keep only plain CERTIFICATE blocks. A bundle like cacert's lists its TLS
  # anchors that way, and the CAs that appear only as TRUSTED CERTIFICATE are
  # trusted for something else, or for nothing.
  #
  # Like upstream JDK 11+, write a PKCS12 store without a password: the JDK
  # opens cacerts without one, and cannot read password-protected certificates.
  # Java trusts a certificate only with Oracle's trusted key usage attribute,
  # which -jdktrust adds. JDK 8 reads it too, as its keystore.type.compat lets
  # the JKS loader open it. Without friendly names, Java numbers the aliases
  # itself.
  text = ''
    if (( $# != 2 )); then
      echo "usage: pem-to-java-pkcs12 <pem-bundle> <output>" >&2
      exit 1
    fi

    sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' "$1" \
      | openssl pkcs12 -export -nokeys -jdktrust anyExtendedKeyUsage \
          -certpbe NONE -nomac -passout pass: -out "$2"
  '';

  meta = {
    description = "Convert a PEM certificate bundle into a Java PKCS12 trust store";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
