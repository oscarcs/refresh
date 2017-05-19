package ;

import Lexer;
import Node;

typedef Parselet = Token->Node->Node;

class ExpressionParser
{
    private var tokens:Array<Token>;
    private var pos = -1;
    private var c:Token;

    private var prefixFuncs = new Map<String, Parselet>();
    private var infixFuncs = new Map<String, Parselet>();
    private var precedenceTable = new Map<String, Int>();

    private var symtab:Symtab;

    public function new(tokens:Array<Token>) 
    {
        this.tokens = tokens;
        this.symtab = new Symtab();

        // register identifier type:
        register(
            "IDENTIFIER",
            function(token:Token, left:Node) { 
                return new IdentNode(token.lexeme);
            }, 
            "none",
            0
        );

        // register integer literal type:
        register(
            "INTEGER",
            function(token:Token, left:Node) { 
                return new IntNode(token.lexeme);
            }, 
            "none",
            0
        );

        // register string literal type:
        register(
            "STRING",
            function(token:Token, left:Node) {
                var value = token.lexeme.substring(1, token.lexeme.length - 1);
                return new StringNode(value);
            },
            "none",
            0
        );

        // register boolean literal type:
        register(
            "BOOLEAN",
            function(token:Token, left:Node) {
                var value = token.lexeme;
                return new BooleanNode(value);
            },
            "none",
            0
        );

        // register grouping parens:
        register(
            "L_PAREN",
            function(token:Token, left:Node) {
                var expression = expression(0);
                advance("R_PAREN");
                return expression;
            },
            "prefix",
            60
        );

        // register function-calling parens:
        register(
            "L_PAREN",
            function(token:Token, left:Node) {
                var args:Array<Node> = [];

                // check the function is in the symtab:
                if (!symtab.exists(left.value))
                {
                    //@@ERROR
                    throw 'Function ${left.value} not found.';
                }

                if (lookahead().type != "R_PAREN")
                {
                    while (true)
                    {
                        args.push(expression(0));
                        if (lookahead().type != "COMMA") break;
                        advance();
                    }
                    advance("R_PAREN");
                }
                return new CallNode(left, args);
            },
            "infix",
            80
        );

        var assign = function(token:Token, left:Node) {
            var right = expression(10 - 1);
            if (!Std.is(left, IdentNode))
            {
                //@@ERROR
                trace('The left-hand side of an assignment must be an identifier');
            }
            //@@TODO: check whether the left hand side is valid.
            return new AssignNode(token.type, left, right);
        }

        register("ASSIGN", assign, "infix", 10);
        register("ADD_ASSIGN", assign, "infix", 10);
        register("SUBTRACT_ASSIGN", assign, "infix", 10);

        // simple prefix operators:
        registerPrefix("ADD", 60);
        registerPrefix("SUBTRACT", 60);
        registerPrefix("COMPLEMENT", 60);
        registerPrefix("NOT", 60);

        // arithmetic operators:
        registerInfix("ADD", 30);
        registerInfix("SUBTRACT", 30);
        registerInfix("MULTIPLY", 40);
        registerInfix("DIVIDE", 40);

        // comparison operators:
        registerInfix("LESS_THAN", 55);
        registerInfix("LESS_OR_EQUAL", 55);
        registerInfix("GREATER_THAN", 55);
        registerInfix("GREATER_OR_EQUAL", 55);
        registerInfix("EQUALITY", 55);
        registerInfix("INEQUALITY", 55);
        registerInfix("LESS_THAN", 55);
        registerInfix("GREATER_THAN", 55);
        registerInfix("LESS_OR_EQUAL", 55);
        registerInfix("GREATER_OR_EQUAL", 55);
        registerInfix("OR", 55);
        registerInfix("AND", 55);

        // simple postfix operators:
        registerPostfix("INCREMENT", 70);
        registerPostfix("DECREMENT", 70);

        //@@TODO: Handle this more elegantly?
        // Add symtab defaults:
        symtab.put("print", { type: "Dynamic->Dynamic" });
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

        // register the precedence of this token type:
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
            // return AST node with two children:
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
        // postfix ops are actually 'infix', i.e not 'prefix':
        register(type, f, "infix", precedence);
    }

    private function advance(?expect:String=null)
    {
        pos++;
        c = tokens[pos];
        // skip comment tokens (which we leave in for debugging):
        while (c != null && c.type == 'COMMENT')
        {
            pos++;
            c = tokens[pos];
        }

        if (expect != null)
        {
            if (c.type != expect)
            {
                //@@ERROR
                trace('Expected ${expect}, but got ${c.type}');
            }
        }
    }

    private function lookahead()
    {
        var next_pos = pos + 1;
        var next = tokens[next_pos];
        // skip comment tokens (which we leave in for debugging):
        while (next != null && next.type == 'COMMENT')
        {
            next_pos++;
            next = tokens[next_pos];
        }
        return next;
    }

    // get the precedence of the next token:
    private function getPrecedence()
    {
        if (this.precedenceTable.exists(lookahead().type))
        {
            return this.precedenceTable[lookahead().type];
        }
        return 0;
    }

    public function parse():Node
    {
        return expression(0);
    }

    private function expression(precedence:Int):Node
    {
        advance();
        if (prefixFuncs.exists(c.type))
        {
            var prefix = prefixFuncs[c.type];

            var left = prefix(c, null);

            // continue consuming tokens while the next token
            // has greater precedence than the current token 'c'.
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

            return left;
        }
        return null;
    }
}