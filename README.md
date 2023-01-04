# Crane Wasm issue

Demonstrates the issue described at https://github.com/ipetkov/crane/issues/207

This branch builds a `[lib]` since that has been working using `naersk` for some time. Renaming `lib.rs` to `main.rs`, adding `fn main() {}`, and building a `[[bin]]` would also be acceptable but that doesn't work using `crane` either.

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
foo> Export[8]:
foo>  - memory[0] -> "memory"
foo>  - func[31] <canister_init> -> "canister_init"
foo>  - func[32] <canister_post_upgrade> -> "canister_post_upgrade"
foo>  - func[33] <canister_pre_upgrade> -> "canister_pre_upgrade"
foo>  - func[34] <canister_query some_query> -> "canister_query some_query"
foo>  - func[35] <canister_update some_update> -> "canister_update some_update"
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
foo-deps> Export[3]:
foo-deps>  - memory[0] -> "memory"
foo-deps>  - global[1] -> "__data_end"
foo-deps>  - global[2] -> "__heap_base"
...
```
