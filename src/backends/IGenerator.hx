package backends;

interface IGenerator
{
    public function generate():String;
    private function generateNode(node:Node):String;
}