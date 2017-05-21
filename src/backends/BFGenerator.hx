package backends;

import Node;

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
    private var programNode:Node;

    private var symbols = new Map<String, BFSymbol>();

    //bf-specific vars:
    private var currentCell:Int = 0;
    private var dataStart:Int;
    private var dataLast:Int;
    private var print_comments:Bool = false; 
    
    public function new(programNode:Node)
    {
        this.programNode = programNode;

        dataStart = 6;
        dataLast = dataStart - 1;
    }

    public function generate():String
    {
        var string = '';

        string += generateNode(programNode);

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
            case ProgramNode:
                var n = cast(node, ProgramNode);
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
                str += emitCopyAssignment(leftIndex, rightIndex, 0);

            case InfixNode:
                var n = cast(node.right, InfixNode);
                str += emitAssignmentExpression(n, node.left.value);
        }
        return str;
    }

    private function emitAssignmentExpression(n:InfixNode, name:String):String
    {
        var exprs = linearizeExpression(n);
        var str = '';

        var temp = 0;
        for (expr in exprs)
        {
            if (expr.lvalue.value > temp) temp = expr.lvalue.value;
        }
        temp++;

        for (expr in exprs)
        {

            //trace(expr);

            //@@TODO: clear temporary variables?

            // if the left and right rvalues are values:
            if (!expr.left.isPointer && !expr.right.isPointer)
            {
                var value = expr.left.value; 
                switch(expr.op)
                {
                    case 'ADD':
                        value += expr.right.value;
                    case 'SUBTRACT':
                        value -= expr.right.value;
                    case 'MULTIPLY':
                        value *= expr.right.value;
                    case 'DIVIDE':
                        value = Std.int(value / expr.right.value);

                }
                str += emitStoreAssignment(expr.lvalue.value, value);
            }
            else if (expr.left.isPointer || expr.right.isPointer)
            {
                if (expr.left.isPointer && !expr.right.isPointer)
                {
                    str += emitClear(expr.lvalue.value);
                    str += emitCopyAssignment(expr.lvalue.value, expr.left.value, temp);
                    switch(expr.op)
                    {
                        case 'ADD':
                            str += emitMove(expr.lvalue.value);
                            str += emitValue(expr.right.value);
                            if (print_comments) str += ' # add ${expr.right.value}';
                        case 'SUBTRACT':
                            str += emitMove(expr.lvalue.value);
                            str += emitValue(-expr.right.value);
                        default:
                            throw '${expr.op} not supported.';
                    }
                }
                else if (!expr.left.isPointer && expr.right.isPointer)
                {
                    str += emitClear(expr.lvalue.value);
                    str += emitCopyAssignment(expr.lvalue.value, expr.right.value, temp);
                    switch(expr.op)
                    {
                        case 'ADD':
                            str += emitMove(expr.lvalue.value);
                            str += emitValue(expr.left.value);
                        default:
                            throw '${expr.op} not supported.';
                    }
                }
                else // both
                {
                    str += emitClear(expr.lvalue.value);
                    str += emitCopyAssignment(expr.lvalue.value, expr.left.value, temp);
                    str += emitCopyAssignment(expr.lvalue.value, expr.right.value, temp);
                }
                str += '\n';
            }

            // We reserve *0 as a temp variable always:
            str += emitClear(symbols[name].start);
            str += emitCopyAssignment(symbols[name].start, expr.lvalue.value, temp);
        }

        return str;
    }

    private function linearizeExpression(root:Node):Array<BFLinearExpr>
    {
        var val = 0;
        var exprs:Array<BFLinearExpr> = [];

        // resolve the left and right lvalues of the expressions:
        function resolveRvalue(node:Node, linearize:Node->BFLinearExpr):BFVar
        {
            var bfvar = new BFVar();

            switch(Type.getClass(node))
            {
                case InfixNode:
                    bfvar.isPointer = true;
                    bfvar.value = (val += 1);
                    exprs.push(linearize(node));
                case IntNode:
                    bfvar.isPointer = false;
                    bfvar.value = Std.parseInt(node.value);

                case IdentNode:
                    bfvar.isPointer = true;
                    bfvar.value = symbols[node.value].start;

                default:
            }

            return bfvar;
        }

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

            linearExpr.left = resolveRvalue(n.left, linearize);

            // op:
            linearExpr.op = n.value;

            linearExpr.right = resolveRvalue(n.right, linearize);
    
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
        return exprs;
    }

    // Constant assignment - add or subtract a constant:
    private function emitConstantAssignment(leftIndex:Int, value:Int, op:String)
    {
        var str = '';
        str += emitMove(leftIndex);
        for (i in 0...value)
        {
            switch(op)
            {
                case 'ADD':
                    str += '+';
                case 'SUBTRACT':
                    str += '-';
            }
        }
        if (print_comments) str += ' # ${op.toLowerCase()} ${value} to *${leftIndex}\n'; 
        return str;
    }

    // Store a value in a memory address:
    private function emitStoreAssignment(leftIndex:Int, value:Int):String
    {
        var str = '';
        str += emitClear(leftIndex);
        str += emitValue(value);
        if (print_comments) str += ' # store ${value} at *${leftIndex}\n';
        return str;
    }

    // Simple assignment of the form x = y
    // Copies a value from one mem addr to another:
    private function emitCopyAssignment(leftIndex:Int, rightIndex:Int, temp:Int):String
    {
        var str = '';
        str += emitClear(temp);

        // right[left+temp+right-]
        str += '${emitMove(rightIndex)}[${emitMove(leftIndex)}+${emitMove(temp)}+${emitMove(rightIndex)}-]';

        // temp[right+temp-]
        str += '${emitMove(temp)}[${emitMove(rightIndex)}+${emitMove(temp)}-] ';
        if (print_comments) str += '# copy *${rightIndex} to *${leftIndex} (${temp})';

        return str;
    }
}