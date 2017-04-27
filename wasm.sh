# Build and test the WebAssembly target.
haxe build.hxml &&
# Compile the code to a WebAssembly AST:
node bin/refresh.js -wasm -t3 test/test.prog test/test.wast &&
# Compile the AST to bytecode:
wasm -d test/test.wast -o test/test.wasm
# Run the WebAssembly code:
wasm-interp --run-all-exports test/test.wasm