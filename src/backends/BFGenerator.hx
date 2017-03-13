package backends;

import Node;
import Parser;

typedef BFSymbol = {
    var start:Int;
    var length:Int;
};

class BFVar
{
    public var isPointer:Bool;
    public var value:Int;
    public function new() { }
}

class BFLinearExpr
{
    public var op:String;
    public var lvalue:BFVar;
    public var left:BFVar;
    public var right:BFVar;
    public function new() { }
}

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
                var leftIndex = symbols[node.left.value].start;
                var rightIndex = symbols[node.right.value].start;
                str += emitSimpleAssignment(leftIndex, rightIndex);

            case InfixNode:
                var n = cast(node.right, InfixNode);
                linearizeExpression(n);
        }
        return str;
    }

    private function linearizeExpression(root:Node)
    {
        var val = 0;
        var exprs:Array<BFLinearExpr> = [];

        function linearize(node:Node):BFLinearExpr
        {
            var linearExpr = new BFLinearExpr();
            linearExpr.op = null;
            linearExpr.lvalue = new BFVar();
            linearExpr.left = new BFVar();
            linearExpr.right = new BFVar();
            linearExpr.lvalue.isPointer = true;
            linearExpr.lvalue.value = val;
            
            var n = cast(node, InfixNode);

            // left:
            if (Type.getClass(n.left) == InfixNode)
            {
                linearExpr.left.isPointer = true;
                linearExpr.left.value = (val += 1);
                exprs.push(linearize(n.left));
            }
            else
            {
                linearExpr.left.isPointer = false;
                linearExpr.left.value = Std.parseInt(n.left.value);
            }

            // op:
            linearExpr.op = n.value;

            // right:
            if (Type.getClass(n.right) == InfixNode)
            {
                linearExpr.right.isPointer = true;
                linearExpr.right.value = (val += 1);
                exprs.push(linearize(n.right));
            }
            else
            {
                linearExpr.right.isPointer = false; 
                linearExpr.right.value = Std.parseInt(n.right.value);
            }
    
            var hasOnlyLeaves = n.children.filter(function(n) {
                return Type.getClass(n) == InfixNode; 
            }).length == 0;

            if (!hasOnlyLeaves)
            {
                val++;
            }

            return linearExpr;
        }

        exprs.push(linearize(root));
        for (expr in exprs)
        {
            trace(expr);
        }
    }

    // Constant assignment - add or subtract a constant:
    private function emitConstantAssignment(leftIndex:Int, value:Int, op:String)
    {
        var str = '';
        str += emitMove(leftIndex);
        for (i in 0...value)
        {
            str += op;
        }
        return str;
    }

    // Simple assignment of the form x = y
    private function emitSimpleAssignment(leftIndex:Int, rightIndex:Int):String
    {
        var str = '';
        var temp = 0;
        str += emitClear(temp);
        str += emitClear(leftIndex);

        // right[left+temp+right-]
        str += '${emitMove(rightIndex)}[${emitMove(leftIndex)}+${emitMove(temp)}+${emitMove(rightIndex)}-]\n';

        // temp[right+temp-]
        str += '${emitMove(temp)}[${emitMove(rightIndex)}+${emitMove(temp)}-]\n';

        return str;
    }
}