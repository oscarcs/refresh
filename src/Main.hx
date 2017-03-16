package ;

import Parser;
import Node;
import backends.BFGenerator;

class Main
{    
    static function main()
    {   
        // Override default trace function.
        var _trace = haxe.Log.trace;

        haxe.Log.trace = function(v:Dynamic, ?info:haxe.PosInfos) 
        {    
            if (v == null)
            {
                _trace('null', null);
            }
            else if (Std.is(v, Node))
            {
                _trace(stringifyNodeRecurse(v), null);
            }
            else if (Std.is(v, { isPointer:Bool, value:Int }))
            {
                _trace(stringifyBFVar(v), null);
            }
            else if (Std.is(v, BFLinearExpr))
            {
                _trace(stringifyBFLinearExpr(v), null);
            }
            else
            {
                _trace(v, null);
            }
        }

        var data = Files.read("test/lex.prog");
        var lexer = new Lexer(data);
        var tokens = lexer.lex();
        for (token in tokens)
        {
            trace('Ln ${token.line}, Col ${token.pos}: ${token.type} (${token.lexeme})');
        }
        
        trace('');

        var parser = new Parser(tokens);
        var root = parser.parse();
        trace(root);
        
        var outPath = "test/out.bf";
        trace('_______ \'${outPath}\': ________________________________________');

        var generator = new backends.BFGenerator(root, outPath);
        var output = generator.generate();
        trace(output);
    }

    static function stringifyBFVar(bfvar:BFVar):String
    {
        var str = '';
        str += bfvar.isPointer ? '*' : '';
        str += bfvar.value;
        return str;
    }

    static function stringifyBFLinearExpr(expr:BFLinearExpr):String
    {
        var str = '';
        str += '${stringifyBFVar(expr.lvalue)} = ${stringifyBFVar(expr.left)} ${expr.op} ${stringifyBFVar(expr.right)};';
        return str;
    }

    static function stringifyNodeRecurse(root:Node):String
    {
        var str = "";

        var nodes:Array<Node> = [root];
        var depths:Array<Int> = [0];
        while (nodes.length > 0)
        {
            var cur = nodes.shift();
            var curDepth = depths.shift();

            // prepend the current children:
            nodes = cur.children.concat(nodes);
            
            // update the virtual indent queue:
            for (i in cur.children)
            {
                depths.unshift(curDepth + 1);
            }

            var indent = '';
            for (i in 0...curDepth) indent += '    ';
            str += indent + stringifyNode(cur);
            str += "\n";
        }

        return str;
    }

    static function stringifyNode(node:Node)
    {
        var className:String = Type.getClassName(Type.getClass(node));
        var plural = node.children.length == 1 ? 'child' : 'children';
        return '${node.value} (${className}, ${node.children.length} ${plural})';
    }
}