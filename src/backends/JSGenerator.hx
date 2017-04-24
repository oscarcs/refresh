package backends;

import Node;
import Symtab;

class JSGenerator implements IGenerator
{
    private var rootNode:Node;

    private var symtab = new Symtab();
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
        "EQUALITY" => '===',
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

    private var indentLevel:Int = 0;

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
        if (node == null)
        {
            throw "Node can't be null!";
        }

        switch(Type.getClass(node))
        {
            case RootNode:
                str += generateChildren(node.children);

            case AssignNode:
                var n = cast(node, AssignNode);
                if (!symtab.exists(n.left.value))
                {
                    // generate variable declaration
                    str += 'let ${generateNode(n.left)} ${operators[n.value]} ${generateNode(n.right)}';
                    
                    symtab.put(n.left.value, { type:'Dynamic' });
                }
                else {
                    str += '${generateNode(n.left)} ${operators[n.value]} ${generateNode(n.right)}';
                }

            case FunctionNode:
                var n = cast(node, FunctionNode);
                
                // get the arguments:
                var argstr = '';
                for (arg in n.args)
                {
                    argstr += '${arg.value}, ';
                }
                argstr = argstr.substring(0, argstr.length - 2);

                // declaration header:
                str += line('function ${generateNode(n.name)}(${argstr}) {\n');
                
                indent();
                str += generateChildren(n.body);
                unindent();
                str += line('}\n'); 

            case IdentNode:
                var n = cast(node, IdentNode);
                str += n.value;

            case IntNode:
                var n = cast(node, IntNode);
                str += n.value;

            case BooleanNode:
                var n = cast(node, BooleanNode);
                str += n.value;

            case WhileNode:
                var n = cast(node, WhileNode);
                str += 'while (${generateNode(n.condition)}) {\n';
                indent();
                str += generateChildren(n.body);
                unindent();
                str += line('}\n');

            case BreakNode:
                str += 'break;\n';

            case IfNode:
                var n = cast(node, IfNode);
                str += 'if (${generateNode(n.condition)}) {\n';
                indent();
                str += generateChildren(n.body);
                unindent();
                str += line('}\n');

            case BlockNode:
                var n = cast(node, BlockNode);
                str += '{\n';
                indent();
                str += generateChildren(n.children);        
                unindent();  
                str += line('}\n');

            case InfixNode:
                var n = cast(node, InfixNode);
                str += '${generateNode(n.left)} ${operators[n.value]} ${generateNode(n.right)}';

            case PrefixNode:
                var n = cast(node, PrefixNode);
                str += '${operators[n.value]}${generateNode(n.child)}';

            case PostfixNode:
                var n = cast(node, PostfixNode);
                str += '${generateNode(n.child)}${operators[n.value]}';

            case CallNode:
                var n = cast(node, CallNode);
                var name = resolveFunction(n.name);
                var call = '';
                call += '${name}(';
                for (arg in n.args)
                {
                    call += '${generateNode(arg)}, ';
                }
                call = call.substring(0, call.length - 2);
                call += ')';
                str += call;
        }

        return str;
    }

    //@@TODO: move some of this logic to the front-end.
    private function resolveFunction(node:Node):String
    {
        switch (node.value)
        {
            case "print":
                return "console.log";
        }
        return node.value;
    }

    //@@TODO: probably refactor this info into the front-end.
    private function isStatement(node:Node):Bool
    {
        var type = Type.getClassName(Type.getClass(node));
        var statements:Array<String> = [
            "BlockNode",
            "IfNode",
            "WhileNode",
            "FunctionNode",
            "BreakNode"
        ];
        return (statements.indexOf(type) == -1);
    }

    private function generateChildren(children:Array<Node>):String
    {
        var str = '';
        for (child in children)
        {
            if (isStatement(child))
            {
                str += line('${generateNode(child)};\n');
            }
            else
            {
                str += line('${generateNode(child)}');
            }
        }
        return str;
    }

    private function line(line:String):String
    {
        var str = '';
        for (i in 0...indentLevel)
        {
            str += '    ';
        }
        str += line;
        return str;
    }

    private function indent():Void
    {
        indentLevel++;
    }

    private function unindent():Void
    {
        indentLevel--;
    }
}