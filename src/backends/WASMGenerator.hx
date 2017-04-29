package backends;

import Node;

class WASMGenerator implements IGenerator
{
    private var rootNode:Node;

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
        str += generateFunction("main");
        //@@TODO: generate other functions
        str += ')';
        return str;
    }

    private function generateFunction(name:String):String
    {
        var str = "";
        str += '(func ' + generateExport(name) + '\n';
        //@@TODO: generate function body
        str += ")";
        return str;
    }

    private function generateExport(name:String):String
    {
        var str = "";
        str += "(export \"" + name + "\")";
        return str;
    }

}