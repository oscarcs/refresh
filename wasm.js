const fs = require('fs');
const buf = fs.readFileSync('test/test.wasm');

var array = new Uint8Array(buf); 

var imports = {js: {
    import1: () => console.log("Hello, world!"),
}};

WebAssembly.instantiate(array, imports).then(wasm =>
    wasm.instance.exports.main()
).catch(reason =>
    console.log(reason)
);