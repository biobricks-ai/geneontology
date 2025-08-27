{
  description = "GeneOntology Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: 
    flake-utils.lib.eachDefaultSystem (system:
      with import nixpkgs { inherit system; }; {
        devShells.default = mkShell {
          buildInputs = [
            R
            rPackages.R_utils
            rPackages.purrr
            rPackages.vroom
            rPackages.arrow
            rPackages.stringr
            rPackages.dplyr
            rPackages.rdflib
            rPackages.tidyr
            rPackages.readr
            rPackages.data_table
            rPackages.digest
          ];
        };
      });
}