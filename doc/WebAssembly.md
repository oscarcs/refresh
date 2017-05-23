## WebAssembly

The compiler features a WebAssembly backend. This document provides some notes on basic WebAssembly concepts which may be generally useful.

## Modules and functions

WebAssembly code is divided into modules, which are compiled and run inside the wrapping interface (we are developing using Node). These modules contain functions, which can be defined and called in a manner similar to a high-level programming language:
``` WebAssembly
(module
    (func $add (param $lhs i32) (param $rhs i32) (result i32)
        get_local $lhs
        get_local $rhs
        i32.add
    )
)
```
However, WebAssembly is internally a stack machine, and so functions must be defined before they are used, like so:
``` WebAssembly
(func $getAnswer (result i32)
    i32.const 42
)
(func $main (result i32)
    call $getAnswer
    i32.const 1
    i32.add
)
```
Because WebAssembly operates on a stack, there are no explicit return values at the end of functions. Instead, the values remaining on the stack are the return from a function.

### Imports and exports

We can import functions from the wrapping interface -- in this case, JavaScript -- and we can export WebAssembly programs so they can be accessed from the outside.

To start with, it is probably useful if we have a way to access the console.log function, so we can report the results of WebAssembly code outside of the WebAssembly sandbox:
``` WebAssembly
(module
    (import "console" "log" (func $log (param i32)))
)
```
This code imports the `log` function from the `console` object, and allows access to it by defining `$log` function. Unlike in JavaScript, the WebAssembly function must have a typed parameter, so here we use `i32` so we can print numbers.