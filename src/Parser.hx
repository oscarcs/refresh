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
    override public function new(value:String, child:Node)
    {
        super(value);
        this.children.push(child);
        this.child = this.children[0];
        this.child.parent = this;
    }
}

class InfixNode extends Node
{
    public var left:Node;
    public var right:Node;
    override public function new(value:String, left:Node, right:Node)
    {
        super(value);
        this.children.push(left);
        this.children.push(right);
        this.left = this.children[0];
        this.right = this.children[1];
        this.left.parent = this;
        this.right.parent = this;        
    }
}

class PostfixNode extends Node
{
    public var child:Node;
    override public function new(value:String, child:Node)
    {
        super(value);
        this.children.push(child);
        this.child = this.children[0];
        this.child.parent = this;
    }
}

typedef Parselet = Token->Node->Node;

class Parser
{
    private var tokens:Array<Token>;
    private var pos = -1;
    private var c:Token;

    private var prefixFuncs = new Map<String, Parselet>();
    private var infixFuncs = new Map<String, Parselet>();

    public function new(tokens:Array<Token>) 
    {
        this.tokens = tokens;

        // register the grammar:
        register(
            "IDENTIFIER",
            function(token:Token, left:Node) { 
                return new IdentNode(token.lexeme);
            }, 
            "none"
        );
        registerPrefix("ADD");
        registerPrefix("SUBTRACT");
        registerPrefix("COMPLEMENT");
        registerPrefix("NOT");
        registerInfix("ADD");
        registerInfix("SUBTRACT");
        registerInfix("MULTIPLY");
        registerInfix("DIVIDE");
    }

    public function parse():Node
    {
        return expression();
    }

    private function register(type:String, f:Parselet, affix:String)
    {
        if (affix == "infix")
        {
            infixFuncs[type] = f;
        }
        else
        {
            prefixFuncs[type] = f;
        }
    }

    private function registerPrefix(type:String)
    {  
        var f = function(token:Token, left:Node) {
            var operand:Node = expression();
            return new PrefixNode(token.type, operand);
        };
        register(type, f, "prefix");
    }

    private function registerInfix(type:String)
    {
        var f = function(token:Token, left:Node) {
            var right = expression();
            return new InfixNode(token.type, left, right);
        };
        register(type, f, "infix");
    }

    private function registerPostfix(type:String)
    {
        var f = function(token:Token, left:Node) {
            return new PostfixNode(token.type, left);
        };
        // postfix ops are actually 'infix':
        register(type, f, "infix");
    }

    private function advance()
    {
        pos += 1;
        c = tokens[pos];
    }

    private function lookahead()
    {
        return tokens[pos + 1];
    }

    private function expression():Node
    {
        advance();
        if (prefixFuncs.exists(c.type))
        {
            var prefix = prefixFuncs[c.type];

            var left = prefix(c, null);

            var token = lookahead();

            if (infixFuncs.exists(token.type))
            {
                var infix = infixFuncs[token.type];
                
                advance();
                return infix(token, left);
            }
            else 
            {
                return left;
            }
        }
        else
        {
            return null;
        }

        return null;
    }
}