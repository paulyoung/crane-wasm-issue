{
  inputs = {
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    naersk.url = "github:nix-community/naersk";

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = {
    self,
    nixpkgs,
    crane,
    flake-utils,
    naersk,
    rust-overlay,
  }:
    let
      supportedSystems = [
        flake-utils.lib.system.aarch64-darwin
        flake-utils.lib.system.x86_64-darwin
      ];
    in
      flake-utils.lib.eachSystem supportedSystems (
        system: let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              (import rust-overlay)
            ];
          };

          rustWithWasmTarget = pkgs.rust-bin.stable."1.66.0".default.override {
            targets = [ "wasm32-unknown-unknown" ];
          };

          naerskLib = naersk.lib."${system}".override {
            cargo = rustWithWasmTarget;
            rustc = rustWithWasmTarget;
          };

          craneLib = crane.lib."${system}";

          # NB: we don't need to overlay our custom toolchain for the *entire*
          # pkgs (which would require rebuidling anything else which uses rust).
          # Instead, we just want to update the scope that crane will use by appending
          # our specific toolchain there.
          craneLibWasm = (crane.mkLib pkgs).overrideToolchain rustWithWasmTarget;
        in
          rec {
            # Wasm optimizer
            packages.ic-wasm = craneLib.buildPackage rec {
              src = pkgs.stdenv.mkDerivation {
                name = "ic-wasm-src";
                src = pkgs.fetchFromGitHub {
                  owner = "dfinity";
                  repo = "ic-wasm";
                  rev = "0.2.0";
                  sha256 = "sha256-HXkXJaxSxKITlGaROKbGPTQHjWPPWJ5Jy3ODgDO+A0I=";
                };
                installPhase = ''
                  cp -R --preserve=mode,timestamps . $out
                '';
              };
              doCheck = false;
              nativeBuildInputs = [
                pkgs.libiconv
              ];
            };

            packages.with-crane = craneLibWasm.buildPackage rec {
              pname = "foo";
              src = ./.;
              nativeBuildInputs = [
                # analysis
                pkgs.twiggy
                pkgs.wabt

                # optimization
                packages.ic-wasm
                pkgs.gzip
              ];
              cargoExtraArgs = "--package ${pname}";
              cargoBuildCommand = "cargoWithProfile build --bin ${pname} --target wasm32-unknown-unknown";
              doCheck = true;
              doDist = true;
              distPhase = ''
                set -e

                WASM=./target/wasm32-unknown-unknown/release/foo.wasm
                WASM_GZ="$WASM".gz

                # NOTE: `twiggy` is disabled below since it fails with
                # `error: function or code section is missing`.

                # echo "" &&
                # echo "twiggy top:" &&
                # twiggy top -n 12 "$WASM" &&

                # echo "" &&
                # echo "twiggy monos:" &&
                # twiggy monos "$WASM" &&

                # echo "" &&
                # echo "twiggy garbage:" &&
                # twiggy garbage "$WASM" &&

                echo "" && \
                echo "File size after rustc:" && \
                stat -c "%s" "$WASM" && \

                # NOTE: `ic-wasm` is an optimizer and is disabled because
                # it removes almost everything since it's seen as dead code.

                # ic-wasm -o "$WASM" "$WASM" shrink && \

                # echo "" && \
                # echo "File size after ic-wasm:" && \
                # stat -c "%s" "$WASM" && \

                echo "" && \
                echo "wasm-objdump --headers:" && \
                wasm-objdump --headers "$WASM" && \

                echo "" && \
                echo "wasm-objdump --section=Export --details:" && \
                wasm-objdump --section=Export --details "$WASM" && \

                gzip --to-stdout --best "$WASM" > "$WASM_GZ" && \

                echo "" && \
                echo "File size after gzip:" && \
                stat -c "%s" "$WASM_GZ" && \

                mkdir -p $out/tarballs && \
                cp "$WASM_GZ" $out/tarballs
              '';
            };

            packages.with-naersk = naerskLib.buildPackage rec {
              pname = "foo";
              root = ./.;
              nativeBuildInputs = [
                # analysis
                pkgs.twiggy
                pkgs.wabt

                # optimization
                packages.ic-wasm
                pkgs.gzip
              ];
              cargoBuildOptions = x: x ++ [
                "--package" pname
                "--target" "wasm32-unknown-unknown"
              ];
              doCheck = true;
              cargoTestOptions = x: x ++ [
                "--package" pname
              ];
              compressTarget = false;
              copyBins = false;
              copyTarget = true;
              postInstall = ''
                set -e

                WASM=$out/target/wasm32-unknown-unknown/release/foo.wasm
                WASM_GZ="$WASM".gz

                echo "" &&
                echo "twiggy top:" &&
                twiggy top -n 12 "$WASM" &&

                echo "" &&
                echo "twiggy monos:" &&
                twiggy monos "$WASM" &&

                echo "" &&
                echo "twiggy garbage:" &&
                twiggy garbage "$WASM" &&

                echo "" && \
                echo "File size after rustc:" && \
                stat -c "%s" "$WASM" && \

                # NOTE: `ic-wasm` is an optimizer and is disabled so
                # we can compare it with the results from using `crane`.

                # ic-wasm -o "$WASM" "$WASM" shrink && \

                # echo "" && \
                # echo "File size after ic-wasm:" && \
                # stat -c "%s" "$WASM" && \

                echo "" && \
                echo "wasm-objdump --headers:" && \
                wasm-objdump --headers "$WASM" && \

                echo "" && \
                echo "wasm-objdump --section=Export --details:" && \
                wasm-objdump --section=Export --details "$WASM" && \

                gzip --to-stdout --best "$WASM" > "$WASM_GZ" && \

                echo "" && \
                echo "File size after gzip:" && \
                stat -c "%s" "$WASM_GZ" && \

                mkdir -p $out/tarballs && \
                cp "$WASM_GZ" $out/tarballs
              '';
            };

            devShell = pkgs.mkShell {
              RUST_SRC_PATH = pkgs.rust.packages.stable.rustPlatform.rustLibSrc;
              inputsFrom = builtins.attrValues packages;
              nativeBuildInputs = pkgs.lib.foldl
                (state: drv: builtins.concatLists [state drv.nativeBuildInputs])
                []
                (pkgs.lib.attrValues packages)
              ;
            };
          }
      );
}
