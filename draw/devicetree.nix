{
  lib,
  python3,
  fetchFromGitHub,
  tree-sitter
}:
python3.pkgs.buildPythonApplication rec {
  pname = "tree-sitter-devicetree";
  version = "0.12.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "joelspadin";
    repo = "tree-sitter-devicetree";
    tag = "v${version}";
    hash = "sha256-UVxLF4IKRXexz+PbSlypS/1QsWXkS/iYVbgmFCgjvZM=";
  };

  build-system = [
    python3.pkgs.setuptools
    python3.pkgs.wheel
  ];

  dependencies = [
    python3.pkgs.tree-sitter
  ];

  nativeBuildInputs = [
    tree-sitter
  ];

  pythonImportsCheck = [
    "tree_sitter_devicetree"
  ];

  meta = {
    description = "Tree-sitter parser for Devicetree files, with support for Zephyr's superset of Devicetree syntax";
    homepage = "https://pypi.org/project/tree-sitter-devicetree/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "tree-sitter-devicetree";
  };
}
