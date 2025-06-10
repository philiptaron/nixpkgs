{
  lib,
  buildPythonPackage,
  fetchPypi,
  llama-cloud-services,
  poetry-core,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "llama-parse";
  version = "0.6.30";
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = fetchPypi {
    pname = "llama_parse";
    inherit version;
    hash = "sha256-JQaAK8fzl0x12RREOHsO4iw6kYKM0Z2g3Z6jJ8n0enk=";
  };

  build-system = [ poetry-core ];

  dependencies = [
    llama-cloud-services
  ];

  pythonImportsCheck = [ "llama_parse" ];

  meta = with lib; {
    description = "Parse files into RAG-Optimized formats";
    homepage = "https://pypi.org/project/llama-parse/";
    license = licenses.mit;
    maintainers = with maintainers; [ fab ];
  };
}
