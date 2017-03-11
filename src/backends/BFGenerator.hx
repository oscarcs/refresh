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

    /**
     * Code to handle statement-level constructs.
     */
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
                // get the memory locations of the left and right operands:
                var left_i = symbols[node.left.value].start;
                var right_i = symbols[node.right.value].start;
                str += emitSimpleAssignment(left_i, right_i);

            case InfixNode:
                var n = cast(node.right, InfixNode);
                generateThreeAddress(n);
        }
        return str;
    }

    private function generateThreeAddress(root:Node)
    {
        function temp(val:Int)
        {
            return "TEMP_" + val;
        }

        function threeAddress(node:Node, val:Int):Int
        {
            if (Type.getClass(node) == InfixNode)
            {
                var str = '';
                var n = cast(node, InfixNode);
                var left_temp = threeAddress(n.left, val+1);
                var right_temp = threeAddress(n.right, val+2);

                // add the left side of the assignment: 
                str += '${temp(val)} = ';

                // add the left operand:
                if (Type.getClass(n.left) != InfixNode)
                {
                    str += '${n.left.value}';
                }
                else
                {
                    str += temp(left_temp);
                }

                // add the operation:
                str += ' ${n.value} ';
                
                // add the right operand:
                if (Type.getClass(n.right) != InfixNode)
                {
                    str += '${n.right.value}';
                }
                else
                {
                    str += temp(right_temp);
                }

                trace(str);
            }
            return val;
        }

        threeAddress(root, 0);
    }

    // Simple assignment of the form x = y
    private function emitSimpleAssignment(left_i:Int, right_i:Int):String
    {
        var str = '';
        var temp = 0;
        str += emitClear(temp);
        str += emitClear(left_i);

        // right[left+temp+right-]
        str += '${emitMove(right_i)}[${emitMove(left_i)}+${emitMove(temp)}+${emitMove(right_i)}-]\n';

        // temp[right+temp-]
        str += '${emitMove(temp)}[${emitMove(right_i)}+${emitMove(temp)}-]\n';

        return str;
    }
}