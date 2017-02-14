package ;

typedef Token = {
    var type:String; // 'class' of token
    var lexeme:String; // actual token content
    var line:Int; // 'y' position
    var pos:Int; // 'x' position
}

class Lexer 
{
    private var pos:Int; // absolute position in the string.
    private var line:Int; // line number.
    private var line_pos:Int; // position in the line.
    private var data:String;
    private var c:String;

    public function new(data:String)
    {
        this.data = data;
        this.pos = 0;
        this.line = 1;
        this.line_pos = 0;
        this.c = data.charAt(pos);
    }

    public function lex():Array<Token>
    {
        var tokens:Array<Token> = [];
        while (true)
        {
            var token = next();
            if (token == null) break;
            tokens.push(token);
        }
        return tokens;
    }

    public function next():Token
    {
        var token:Token = getToken();
        return token;
    }

    private function getToken():Token
    {
        var t:Token = null;
        var buf:String = '';

        function advance(?append:Bool=true):Void
        {
            if (append) { buf = buf + c; }
            pos += 1;
            c = data.charAt(pos);
        }

        function token(type:String, lexeme:String)
        {
            return {
                type: type, 
                lexeme: lexeme, 
                line: line, 
                pos: line_pos
            };
        }

        function isTerminator(c:String)
        {
            return c == '\n' || c == '\r';
        }

        function isSpace(c:String)
        {
            return c == ' ' || c == '\t' || isTerminator(c);
        }

        function isNull(c:String)
        {
            return c == '' || c == null;
        }

        if (isSpace(c))
        {
            while(isSpace(c))
            {
                if (isTerminator(c))
                {
                    line += 1;
                    line_pos = 0;
                }
                advance(false);
            }
        }
        
        if (c == '/')
        {
            advance();
            if (c == '/')
            {
                advance();
                // handle comment
                while (!isTerminator(c) && !isNull(c))
                {
                    advance();
                }
                t = token('COMMENT', buf);
            }
        }

        return t;
    }
}