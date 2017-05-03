const fs = require('fs');
const buf = fs.readFileSync('test/test.wasm');

var array = new Uint8Array(buf); 

var imports = {js: {
    printInt: (x) => console.log(x),
    printString: (offset, length) => {
        var bytes = new Uint8Array(memory.buffer, offset, length);
        var string = new TextDecoder('utf8').decode(bytes);
        console.log(string);
    }
}};

WebAssembly.instantiate(array, imports).then(wasm =>
    wasm.instance.exports.main()
).catch(reason =>
    console.log(reason)
);