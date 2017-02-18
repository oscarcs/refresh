package ;

import Lexer.Token;

class Node
{
    public var value:String;
    public var children:Array<Node> = [];
    public var parent:Node;

    public function new(value:String)
    {
        this.value = value;
    }

    public function hasChildren():Bool
    {
        return this.children.length != 0;
    }

    public function isLastChild():Bool
    {
        if (this.parent != null)
        {
            return this.parent.children[this.parent.children.length] == this;
        }
        return true;
    }
}

class IdentNode extends Node
{
    override public function new(value:String)
    {
        super(value);
    }
}

class PrefixNode extends Node
{
    public var child:Node;
    override public function new(value:String, operand:Node)
    {
        super(value);
        this.children.push(operand);
        operand.parent = this;
        this.child = this.children[0];
    }
}

class Parser
{
    private var tokens:Array<Token>;
    private var pos = -1;
    private var c:Token;

    private var parseFuncs = new Map<String, Token->Node>();

    public function new(tokens:Array<Token>) 
    {
        this.tokens = tokens;

        // register the grammar:
        register("IDENTIFIER", function(token) { 
            return new IdentNode(token.lexeme);
        });
        registerPrefix("ADD");
        registerPrefix("SUBTRACT");
        registerPrefix("COMPLEMENT");
        registerPrefix("NOT");


    }

    public function parse():Node
    {
        return expression();
    }

    private function register(type:String, f:Token->Node)
    {
        parseFuncs[type] = f;
    }

    private function registerPrefix(type:String)
    {  
        var f = function(token) {
            var operand:Node = expression();
            return new PrefixNode(token.type, operand);
        };
        register(type, f);
    }

    private function advance()
    {
        pos += 1;
        c = tokens[pos];
    }

    private function expression():Node
    {
        advance();
        var prefix = parseFuncs[c.type];
        
        //@@ERROR

        return prefix(c);
    }
}