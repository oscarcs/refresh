package backends;

class WASMGenerator
{
    private var rootNode:Node;

    public function new(rootNode:Node)
    {
        this.rootNode = rootNode;
    }

    public function generate():String
    {
        var string = '';

        return string;
    }

    private function generateNode(node:Node):String
    {
        var string = '';

        if (node == null)
        {
            throw "Node can't be null!";
        }

        switch(Type.getClass(node))
        {
            default:
        }

        return string;
    }

}