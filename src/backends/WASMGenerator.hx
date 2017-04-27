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
        str += generateNode(rootNode);
        return str;
    }

    private function generateNode(node:Node):String
    {
        var str:String = '';

        if (node == null)
        {
            throw "Node can't be null!";
        }

        switch(Type.getClass(node))
        {
            case RootNode:
                str += generateModule();
        }

        return str;
    }

    private function generateModule():String
    {
        var str = "";
        str += '(module (func (export "main")))';
        return str;
    }

}