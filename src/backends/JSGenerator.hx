package backends;

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
        return "";
    }
}