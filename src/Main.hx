package ;

import Parser.Node;

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
        trace (root);
    }

    static function stringifyNodeRecurse(root:Node):String
    {
        var str = "";
        var indentLevel = 0;

        var nodes:Array<Node> = [root];
        while (nodes.length > 0)
        {
            var cur = nodes.shift();

            // prepend the current children
            nodes = cur.children.concat(nodes);

            var indentStr = '';
            for (i in 0...indentLevel) indentStr += '    ';
            str += indentStr + stringifyNode(cur);
            str += "\n";

            if (!cur.hasChildren() && cur.isLastChild()) indentLevel--;
            if (cur.hasChildren()) indentLevel++;
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