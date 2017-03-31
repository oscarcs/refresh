package backends;

import Node;
import Parser;

class JSGenerator implements IGenerator
{
    private var rootNode:Node;

    private var symbols = new Map<String, Symbol>();
    private var operators:Map<String, String> = [
        "ASSIGN" => '=',
        "ADD" => '+',
        "SUBTRACT" => '-',
        "MULTIPLY" => '*',
        "DIVIDE" => '/',
        "ADD_ASSIGN" => '+=',
        "SUBTRACT_ASSIGN" => '-=',
        "INCREMENT" => '++',
        "DECREMENT" => '--',
        "EQUALITY" => '==',
        "INEQUALITY" => '!=',
        "LESS_THAN" => '<',
        "GREATER_THAN" => '>',
        "GREATER_OR_EQUAL" => '>=',
        "LESS_OR_EQUAL" => '<=',
        "OR" => '||',
        "AND" => '&&',
        "NOT" => '!',
        "L_SHIFT" => '<<',
        "R_SHIFT" => '>>'
    ];

    public function new(rootNode:Node)
    {
        this.rootNode = rootNode;
    }

    public function generate():String
    {
        var string = '';

        string += generateNode(rootNode);

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

            case BlockNode:
                var n = cast(node, BlockNode);
                str += '{\n';
                for (child in n.children) {
                    str += '${generateNode(child)}';
                }            
                str += '\n}';

            case InfixNode:
                var n = cast(node, InfixNode);
                str += '${generateNode(n.left)} ${operators[n.value]} ${generateNode(n.right)}';

            case PrefixNode:
                var n = cast(node, PrefixNode);
                str += '${operators[n.value]} ${generateNode(n.child)}';

            case PostfixNode:
                var n = cast(node, PostfixNode);
                str += '${generateNode(n.child)} ${operators[n.value]}';
        }

        return str;
    }
}