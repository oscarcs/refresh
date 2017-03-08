package backends;

import Node;
import Parser;

typedef BFSymbol = {
    var start:Int;
    var length:Int;
};

class BFGenerator implements IGenerator
{
    private var rootNode:Node;
    private var outputPath:String;

    private var symbols = new Map<String, BFSymbol>();

    //bf-specific vars:
    private var currentCell:Int = 0;
    private var dataStart:Int;
    private var dataLast:Int;
    
    public function new(rootNode:Node, outputPath:String)
    {
        this.rootNode = rootNode;
        this.outputPath = outputPath;

        dataStart = 3;
        dataLast = dataStart - 1;
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
                // add the symbol:
                //@@TODO: type checking so we can do strings
                if (!symbols.exists(n.left.value))
                {
                    dataLast++; // get the next data slot.
                    symbols[n.left.value] = {start:dataLast, length:1};
                }
                str += emitMove(dataLast);
                str += emitAssignment(n);

            case IdentNode:
                var n = cast(node, IdentNode);
                str += emitMove(symbols[n.value].start);

            case InfixNode:
                var n = cast(node, InfixNode);
                str += emitInfix(n);
        }

        return str;
    }

    private function emitMove(cell:Int):String
    {
        var str:String = '';
        if (currentCell > cell)
        {
            for (i in cell...currentCell)
            {
                str += '<';
            }
        }
        else if (cell > currentCell)
        {
            for (i in currentCell...cell)
            {
                str += '>';
            }
        }
        currentCell = cell;
        return str;
    }

    private function emitValue(value:Int):String
    {
        var str = '';
        if (value > 0)
        {
            for (i in 0...value)
            {
                str += '+';
            }
        }
        else if (value < 0)
        {
            for (i in 0...value)
            {
                str += '-';
            }
        }
        return str;
    }

    private function emitClear(cell:Int):String
    {
        // assumes wrapping implementation:
        return '${emitMove(cell)}[-]\n';
    }

    private function emitAssignment(node:AssignNode):String
    {
        var str = '';
        switch(Type.getClass(node.right))
        {
            case IntNode:
                var n = cast(node.right, IntNode);
                str += emitMove(symbols[node.left.value].start);
                str += emitValue(Std.parseInt(n.value));

            case IdentNode:
                var n = cast(node.right, IdentNode);
                var left = symbols[node.left.value].start;
                var right = symbols[n.value].start;
                var temp = 0;
                str += emitClear(temp);
                str += emitClear(left);
                // right[left+temp+right-]
                str += '${emitMove(right)}[${emitMove(left)}+${emitMove(temp)}+${emitMove(right)}-]\n';
                // temp[right+temp-]
                str += '${emitMove(temp)}[${emitMove(right)}+${emitMove(temp)}-]\n';

            case InfixNode:
                str += generateNode(node.right);
        }
        return str;
    }

    private function emitInfix(node:InfixNode):String
    {
        var str = '';
        switch(node.value)
        {
            case 'ADD':
                str += generateNode(node.left);
                str += generateNode(node.right);
                
            default:
                throw 'Operation ${node.value} unsupported.';
        }
        return str;
    }
}