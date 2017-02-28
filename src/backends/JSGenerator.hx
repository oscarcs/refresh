package backends;

import Node;

class JSGenerator implements IGenerator
{
    private var rootNode:Node;
    private var outputPath:String;

    public function new(rootNode:Node, outputPath:String)
    {
        this.rootNode = rootNode;
        this.outputPath = outputPath;
    }

    public function generate():String
    {
        var string = '';

        string += generateNode(rootNode);

        Files.write(outputPath, string);

        return string;
    }

    private function generateNode(node:Node):String
    {
        //@@CLEANUP: can we do this w/o casting?
        var str:String = '';
        switch(Type.getClass(node))
        {
            case RootNode:
                var n = cast(node, RootNode);
                str = n.children.map(generateNode).join('\n');

            case AssignNode:
                var n = cast(node, AssignNode);
                str = generateNode(n.left) + ' = ' + generateNode(n.right) + ';';

            case IdentNode:
                var n = cast(node, IdentNode);
                str = n.value;

            case IntNode:
                var n = cast(node, IntNode);
                str = n.value + '';
        }

        return str;
    }
}