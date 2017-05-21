package backends;

import Node;

typedef WasmParam = {
    name:String,
    type:WasmType
};

typedef WasmExport = {
    // Name of the export, i.e. the name that
    // will be exposed to the calling environment.
    name:String,
    
    // Internal reference name for the export; the
    // $-prefixed name.
    reference:String
};

typedef WasmImport = {
    // List of string representing name-parts for
    // the inputs JavaScript name. console.log would
    // become ["console", "log"]. **Must have at least two
    // name-parts**.
    name: Array<String>,

    // Internal reference name for the import; the
    // $-prefixed name.
    reference: String,

    // A list of WebAssembly parameters that are passed
    // to the JavaScript implementation and used for
    // type-checking.
    params: Array<WasmParam>
};

enum WasmType {
    I32;
}

class WASMGenerator implements IGenerator
{
    private var programNode:Node;

    // Array of exported functions.
    // We defer exporting to the end of the
    // textual representation.
    private var exports:Array<WasmExport> = [];

    // Array of predefined imported functions.
    private var imports:Array<WasmImport> = [
        {
            name: ["js", "printInt"],
            reference: "print_int",
            params: [
                {
                    name: "x",
                    type: I32
                }
            ]
        },
        {
            name: ["js", "printString"],
            reference: "print_string",
            params: [
                {
                    name: "offset",
                    type: I32
                },
                {
                    name: "length",
                    type: I32
                }
            ]
        }
    ];

    public function new(programNode:Node)
    {
        this.programNode = programNode;
    }

    public function generate():String
    {
        var str = '';
        str += generateModule(cast programNode);
        return str;
    }

    /**
     *  In the WebAssembly backend, generateNode()
     *  generates expressions for linear WebAssembly instructions
     *  inside of functions and so forth. 
     *  @param node - 
     *  @return String
     */
    private function generateNode(node:Node):String
    {
        var str:String = '';

        if (node == null)
        {
            throw "Node can't be null!";
        }

        switch(Type.getClass(node))
        {
            default:
        }

        return str;
    }

    private function generateModule(n:ProgramNode):String
    {
        var str = "";
        str += '(module \n'; 

        for (i in imports)
        {
            str += generateImport(i) + '\n';
        }

        str += generateFunction("main", []) + '\n';
        
        //@@TODO: generate other functions


        // Generate exports
        for (e in exports)
        {
            str += generateExport(e) + '\n';
        }

        str += ')';
        return str;
    }

    /**
     *  Generate the code for a function.
     *  @param name Internal name of a function.
     *  @param args Array of arguments to a function.
     *  @return String
     */
    private function generateFunction(name:String, args:Array<WasmParam>):String
    {
        //@@TODO: Determine whether this function needs to be exported:
        var isExport:Bool = name == "main";

        //@@TODO: Determine the export name:
        var exportName:String = name;

        var str = "";
        str += '(func $' + name; 
        for (arg in args)
        {
            str += '('; 
        }
        str += '\n';

        //@@TODO: generate function body

        str += ")";

        if (isExport)
        {
            addExport(name, exportName);
        }

        return str;
    }

    private function generateImport(i:WasmImport):String
    {
        var str = "";
        str += '(import ';
        for (namepart in i.name)
        {
            str += '"${namepart}" ';
        }
        str += '(func $' + i.reference;
        for (param in i.params)
        {
            str += ' (param ' + Std.string(param.type).toLowerCase() + ')';
        }
        str += '))';
        return str;
    }

    /**
     *  Add an export to the list of exports for
     *  later code generation.
     *  @param name Name of export.
     *  @param reference Internal reference to export. 
     */
    private function addExport(name:String, reference:String):Void
    {
        this.exports.push({ name: name, reference: reference });
    }

    /**
     *  Generate an export for a function.
     *  @param name Name of exported function.
     */
    private function generateExport(e:WasmExport):String
    {
        var str = "";
        str += '(export "' + e.name + '" (func $' + e.reference + '))';
        return str;
    }

}