# Compiler Project

## Dependencies

- [The Haxe compiler](https://github.com/haxefoundation/haxe). An install script for Ubuntu-based Linux can be found [here](https://gist.github.com/oscarcs/651f9ce28811784cbf84b4b7ac3d6b6b).
- A [nightly build](https://nodejs.org/download/nightly/) of NodeJS v8.
- Optionally, a regular (non-nightly) recent build of Node.
- The WebAssembly [binary tools](https://github.com/WebAssembly/wabt) and [spec interpreter](https://github.com/WebAssembly/spec/tree/master/interpreter) for building / debugging purposes. 

## Building

To build and test the code, use the provided bash scripts for each target as examples.

``` bash
haxe build.hxml
```

This will give you a JavaScript file of the compiler code.