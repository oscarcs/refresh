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
                dataLast++; // get the next data slot.
                str += emitCellMove(dataLast);
                // add the symbol:
                //@@TODO: type checking so we can do strings
                symbols[n.left.value] = {start:dataLast, length:1};

            case IdentNode:
                var n = cast(node, IdentNode);

            case InfixNode:
                var n = cast(node, InfixNode);
                str += emitInfix(n.value);

            case IntNode:
                var n = cast(node, IntNode);
                str += emitValue(Std.parseInt(n.value));
        }

        return str;
    }

    private function emitCellMove(cell:Int):String
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

    private function emitInfix(type:String):String
    {
        var str = '';

        switch(type)
        {
            case 'ADD':

            default:
                throw 'Operation ${type} unsupported.';
        }

        return str;
    }
}