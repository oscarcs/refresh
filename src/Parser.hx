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
            return this.parent.children[this.parent.children.length - 1] == this;
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
    private var precedenceTable = new Map<String, Int>();

    public function new(tokens:Array<Token>) 
    {
        this.tokens = tokens;

        // register the grammar:
        register(
            "IDENTIFIER",
            function(token:Token, left:Node) { 
                return new IdentNode(token.lexeme);
            }, 
            "none",
            0
        );
        registerPrefix("ADD", 60);
        registerPrefix("SUBTRACT", 60);
        registerPrefix("COMPLEMENT", 60);
        registerPrefix("NOT", 60);
        registerInfix("ADD", 30);
        registerInfix("SUBTRACT", 30);
        registerInfix("MULTIPLY", 40);
        registerInfix("DIVIDE", 40);
    }

    public function parse():Node
    {
        return expression(0);
    }

    private function register(type:String, f:Parselet, affix:String, precedence:Int)
    {
        if (affix == "infix")
        {
            infixFuncs[type] = f;
        }
        else
        {
            prefixFuncs[type] = f;
        }
        this.precedenceTable[type] = precedence;
    }

    private function registerPrefix(type:String, precedence:Int)
    {  
        var f = function(token:Token, left:Node)
        {
            var precedence = this.precedenceTable[token.type];
            var operand:Node = expression(precedence);
            return new PrefixNode(token.type, operand);
        };
        register(type, f, "prefix", precedence);
    }

    private function registerInfix(type:String, precedence:Int)
    {
        var f = function(token:Token, left:Node)
        {
            var precedence = this.precedenceTable[token.type];
            var right:Node = expression(precedence);
            return new InfixNode(token.type, left, right);
        };
        register(type, f, "infix", precedence);
    }

    private function registerPostfix(type:String, precedence:Int)
    {
        var f = function(token:Token, left:Node)
        {
            return new PostfixNode(token.type, left);
        };
        // postfix ops are actually 'infix':
        register(type, f, "infix", precedence);
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

    private function expression(precedence:Int):Node
    {
        advance();
        if (prefixFuncs.exists(c.type))
        {
            var prefix = prefixFuncs[c.type];

            var left = prefix(c, null);

            trace(c.type + ", " + precedence + ", " + getPrecedence());
            while (precedence < getPrecedence())
            {
                advance();
                var infix = infixFuncs[c.type];
                if (infix == null)
                {
                    break;
                }
                else
                {
                    left = infix(c, left);
                }
            }

            trace(left.value + ' (${left.children.length})');
            return left;
        }
        return null;
    }

    private function getPrecedence()
    {
        if (this.precedenceTable.exists(lookahead().type))
        {
            return this.precedenceTable[lookahead().type];
        }
        return 0;
    }
}