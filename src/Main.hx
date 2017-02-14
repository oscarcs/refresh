package ;

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
            trace('Line ${token.line}, pos ${token.pos}: ${token.type} (${token.lexeme})');
        }
    }
}