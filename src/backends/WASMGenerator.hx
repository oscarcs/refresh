package backends;

import Node;

typedef W_Param = {
    name:String,
    type:W_Type
};

typedef W_Export = {
    // Name of the export, i.e. the name that
    // will be exposed to the calling environment.
    name:String,
    // Internal reference name for the 
    reference:String
};

enum W_Type {
    I32;
}

class WASMGenerator implements IGenerator
{
    private var rootNode:Node;

    // Array of exported functions.
    // We defer exporting to the end of the
    // textual representation.
    private var exports:Array<W_Export> = [];

    public function new(rootNode:Node)
    {
        this.rootNode = rootNode;
    }

    public function generate():String
    {
        var str = '';
        str += generateModule(cast rootNode);
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

    private function generateModule(n:RootNode):String
    {
        var str = "";
        str += '(module \n'; 
        str += generateFunction("main", []) + '\n';
        
        //@@TODO: generate other functions


        // Generate exports
        for (export in exports)
        {
            str += generateExport(export) + '\n';
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
    private function generateFunction(name:String, args:Array<W_Param>):String
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

    private function addExport(name:String, reference:String):Void
    {
        this.exports.push({ name: name, reference: reference });
    }

    /**
     *  Generate an export for a function.
     *  @param name Name of exported function
     */
    private function generateExport(export:W_Export):String
    {
        var str = "";
        str += '(export "' + export.name + '" (func $' + export.reference + '))';
        return str;
    }

}