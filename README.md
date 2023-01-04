# Crane Wasm issue

Demonstrates the issue described at https://github.com/ipetkov/crane/issues/207

***
UPDATE: building with `--bin` (or `--lib`) fixes the issue. Without those flags, only the dependencies are built (`foo-deps`).
***

This branch builds a `[[bin]]` in case that can provide a path forward. This works using `naersk` but not when using `crane`.

## Usage

### Nix

`nix build .#with-naersk` and `nix build .#with-crane`

### Cargo

`cargo build --target=wasm32-unknown-unknown` and `cargo test` within the dev shell.

## Output

### `naersk`

```
nix build .#with-naersk -L
...
foo> wasm-objdump --section=Export --details:
foo> foo.wasm:  file format wasm 0x1
foo> Section Details:
foo> Export[9]:
foo>  - memory[0] -> "memory"
foo>  - func[36] <canister_init> -> "canister_init"
foo>  - func[37] <canister_post_upgrade> -> "canister_post_upgrade"
foo>  - func[38] <canister_pre_upgrade> -> "canister_pre_upgrade"
foo>  - func[39] <canister_query some_query> -> "canister_query some_query"
foo>  - func[40] <canister_update some_update> -> "canister_update some_update"
foo>  - func[41] <main> -> "main"
foo>  - global[1] -> "__data_end"
foo>  - global[2] -> "__heap_base"
...
```

### `crane`

```
nix build .#with-crane -L
...
foo-deps> wasm-objdump --section=Export --details:
foo-deps> foo.wasm:     file format wasm 0x1
foo-deps> Section Details:
foo-deps> Export[4]:
foo-deps>  - memory[0] -> "memory"
foo-deps>  - func[1] <main> -> "main"
foo-deps>  - global[1] -> "__data_end"
foo-deps>  - global[2] -> "__heap_base"
...
```
