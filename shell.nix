{ dappPkgs ? (
    import (fetchTarball "https://github.com/makerdao/makerpkgs/tarball/master") {}
  ).dappPkgsVersions.master-20220524
}: with dappPkgs;

mkShell {
  DAPP_SOLC = solc-static-versions.solc_0_8_14 + "/bin/solc-0.8.14";
  # SOLC_FLAGS = "--optimize --optimize-runs=200";
  buildInputs = [
    dapp
  ];
}
