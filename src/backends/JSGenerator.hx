package backends;

import Node;
import Parser;

class JSGenerator implements IGenerator
{
    private var rootNode:Node;
    private var outputPath:String;

    private var symbols = new Map<String, Symbol>();
    private var operators:Map<String, String> = [
        "ASSIGN" => '=',
        "ADD_ASSIGN" => '+=',
        "SUBTRACT_ASSIGN" => '-=',
        "EQUALITY" => '==',
        "INEQUALITY" => '!=',
        "LESS_THAN" => '<',
        "GREATER_THAN" => '>',
        "GREATER_OR_EQUAL" => '>=',
        "LESS_OR_EQUAL" => '<=',
        "OR" => '||',
        "AND" => '&&'
    ];

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
                str += n.children.map(generateNode).join('\n');

            case AssignNode:
                var n = cast(node, AssignNode);
                if (!symbols.exists(n.left.value))
                {
                    // generate variable declaration
                    str += 'let ${n.left.value};\n';
                    //@@TODO: use a more appropriate value for symtab.
                    symbols[n.left.value] = { type:'DYNAMIC' };
                }
                str += '${generateNode(n.left)} ${operators[n.value]} ${generateNode(n.right)};';

            case IdentNode:
                var n = cast(node, IdentNode);
                str += n.value;

            case IntNode:
                var n = cast(node, IntNode);
                str += n.value + '';

            case WhileNode:
                var n = cast(node, WhileNode);
                str += 'while (${generateNode(n.condition)}) {\n';
                for (child in n.body) {
                    str += '${generateNode(child)}\n';
                }
                str += '\n}';

            case IfNode:
                var n = cast(node, IfNode);
                str += 'if (${generateNode(n.condition)}) {\n';
                for (child in n.body) {
                    str += '${generateNode(child)}\n';
                }
                str += '\n}';            

            case InfixNode:
                var n = cast(node, InfixNode);
                str += '${generateNode(n.left)} ${operators[n.value]} ${generateNode(n.right)}';
        }

        return str;
    }
}