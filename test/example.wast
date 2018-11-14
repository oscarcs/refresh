(module
    (import "js" "import1" (func $i1))
    (func $f (call $i1))
    (func $main
        (call $f)
    )

    (export "main" (func $main))
)