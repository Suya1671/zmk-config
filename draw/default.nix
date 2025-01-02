{
  lib,
  python3,
  fetchPypi,
  tree-sitter-grammars,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "keymap-drawer";
  version = "0.19.0";
  pyproject = true;

  src = fetchPypi {
    pname = "keymap_drawer";
    inherit version;
    hash = "sha256-/+QWhDXJeS/qJGzHb8K9Fa5EyqEl5zI2it/vPl9AtO4=";
  };

  build-system = [
    python3.pkgs.poetry-core
  ];

  dependencies = with python3.pkgs; [
    pcpp
    platformdirs
    pydantic
    pydantic-settings
    pyyaml
    tree-sitter
    (pkgs.callPackage ./devicetree.nix { })
  ];

  pythonImportsCheck = [
    "keymap_drawer"
  ];

  meta = {
    description = "Visualize keymaps that use advanced features like hold-taps and combos, with automatic parsing";
    homepage = "https://github.com/caksoylar/keymap-drawer";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "keymap-drawer";
  };
}
