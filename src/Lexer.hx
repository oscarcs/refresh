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

    private var optable:Map<String, String> = [
        '+' => "ADD",
        '-' => "SUBTRACT",
        '*' => "MULTIPLY",
        '/' => "DIVIDE",
        '%' => "MODULO",
        '=' => "ASSIGN",
        '{' => "L_BRACE",
        '}' => "R_BRACE",
        '[' => "L_BRACKET",
        ']' => "R_BRACKET",
        '(' => "L_PAREN",
        ')' => "R_PAREN",
        '"' => "DOUBLE_QUOTE",
        "'" => "SINGLE_QUOTE",
        '.' => "PERIOD",
        '#' => "POUND",
        '?' => "QUESTION",
        ':' => "COLON",
        ';' => "SEMICOLON",
        '++' => "INCREMENT",
        '--' => "DECREMENT",
        '+=' => "ADD_ASSIGN",
        '-=' => "SUBTRACT_ASSIGN",
        '==' => "EQUALITY",
        '!=' => "INEQUALITY",
        '<' => "LESS_THAN",
        '>' => "GREATER_THAN",
        '>=' => "GREATER_OR_EQUAL",
        '<=' => "LESS_OR_EQUAL",
        '||' => "OR",
        '&&' => "AND",
        '!' => "NOT",
        '|' => "BITWISE_OR",
        '&' => "BITWISE_AND",
        '~' => "COMPLEMENT",
        '>>' => "L_SHIFT",
        '<<' => "R_SHIFT"
    ];

    public function new(data:String)
    {
        this.data = data;
        this.pos = 0;
        this.line = 1;
        this.line_pos = 1;
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

        tokens.push({
            type: "END",
            lexeme: "END",
            line: line,
            pos: line_pos - 1
        });

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
            line_pos += 1;
            c = data.charAt(pos); 
        }

        function token(type:String, lexeme:String, pos:Int)
        {
            return {
                type: type, 
                lexeme: lexeme, 
                line: line, 
                pos: pos
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

        function isAlpha(c:String)
        {
            return (c >= 'a' && c <= 'z') ||
                   (c >= 'A' && c <= 'Z') ||
                   (c == '_' || c == '$'); 
        }

        function isNumeric(c:String)
        {
            return c >= '0' && c <= '9';
        }

        function isAlphanumeric(c:String)
        {
            return isNumeric(c) || isAlpha(c);
        }

        if (isSpace(c))
        {
            while (isSpace(c))
            {
                if (isTerminator(c))
                {
                    line += 1;
                    line_pos = 1;
                }
                advance(false);
            }
        }
        
        if (c == '/')
        {
            var next = data.charAt(pos + 1);
            if (next == '/')
            {
                advance();
                // handle comment
                while (!isTerminator(c) && !isNull(c))
                {
                    advance();
                }
                t = token('COMMENT', buf, line_pos - buf.length);
            }
            else
            {
                t = token(optable[c], c, line_pos - 1);
                advance();
            }
        }
        else if (isAlpha(c))
        {
            // identifier or reserved word:
            while (isAlphanumeric(c))
            {
                advance();
            }
            t = token('IDENTIFIER', buf, line_pos - buf.length - 1);
        }
        else if (isNumeric(c))
        {
            //@@TODO: Add floating point, hex, etc support.
            while (isNumeric(c))
            {
                advance();
            }
            t = token('INTEGER', buf, line_pos - buf.length - 1);
        }
        else 
        {
            var next_two:String = c + data.charAt(pos + 1); 
            if (optable.exists(next_two))
            {
                t = token(optable[next_two], next_two, line_pos - 1);
                advance();
            }
            else if (optable.exists(c))
            {
                t = token(optable[c], c, line_pos - 1);
            }
            advance();
        }

        return t;
    }
}