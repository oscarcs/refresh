package ;

import Lexer;
import Node;

typedef Parselet = Token->Node->Node;

/**
 *  This class contains code for parsing of single expressions,
 *  i.e. only mathematical expressions and so on. Here we use
 *  top-down operator precedence parsing.
 */
class ExpressionParser
{
    private var tokens:Array<Token>;
    private var pos = -1;
    private var c:Token;

    private var prefixFuncs = new Map<String, Parselet>();
    private var infixFuncs = new Map<String, Parselet>();
    private var precedenceTable = new Map<String, Int>();

    /**
     *  The symbol table tracks the registered identifiers and 
     *  their types.
     */
    private var symtab:Symtab;

    public function new(tokens:Array<Token>) 
    {
        this.tokens = tokens;
        this.symtab = new Symtab();

        // Register identifier parselet:
        register(
            "IDENTIFIER",
            function(token:Token, left:Node) { 
                return new IdentNode(token.lexeme);
            }, 
            "none",
            0
        );

        // Register integer literal parselet:
        register(
            "INTEGER",
            function(token:Token, left:Node) { 
                return new IntNode(token.lexeme);
            }, 
            "none",
            0
        );

        // Register string literal parselet:
        register(
            "STRING",
            function(token:Token, left:Node) {
                var value = token.lexeme.substring(1, token.lexeme.length - 1);
                return new StringNode(value);
            },
            "none",
            0
        );

        // Register boolean literal parselet. Takes on either
        // 'true' or 'false' value.
        register(
            "BOOLEAN",
            function(token:Token, left:Node) {
                var value = token.lexeme;
                return new BooleanNode(value);
            },
            "none",
            0
        );

        // Register grouping parentheses parselet.
        // These are the brackets that group mathematical expressions
        // and change precedence etc.
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

        // Left parenthesis for function calls. Occurs between an
        // identifier - the function name - and a list of arguments.
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

        // Function to parse assignment expressions.
        // Checks the validity of LHS and RHS.
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

        // Simple prefix operators:
        registerPrefix("ADD", 60);
        registerPrefix("SUBTRACT", 60);
        registerPrefix("COMPLEMENT", 60);
        registerPrefix("NOT", 60);

        // Arithmetic operators:
        registerInfix("ADD", 30);
        registerInfix("SUBTRACT", 30);
        registerInfix("MULTIPLY", 40);
        registerInfix("DIVIDE", 40);

        // Comparison operators:
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

        // Simple postfix operators:
        registerPostfix("INCREMENT", 70);
        registerPostfix("DECREMENT", 70);

        //@@TODO: Handle this more elegantly?
        // Add default/inbuilt identifiers to the symbol table:
        symtab.put("print", { type: "Dynamic->Dynamic" });
    }

    /**
     *  Register a parselet to be used to parse expressions. Each parselet is
     *  called when a particular type of token is encountered in the token stream,
     *  and allows for parsing to be modular.
     *  @param type - Type name of the Token.
     *  @param f - Parselet function
     *  @param affix - Which table to put this parselet into
     *  @param precedence - Operator precedence of this token type.
     */
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

    /**
     *  'Shortcut' function to make registering prefix operators easier.
     *  Adds a generic prefix-parsing function.
     *  @param type - Type name of the Token.
     *  @param precedence - Operator precedence of this token type.
     */
    private function registerPrefix(type:String, precedence:Int)
    {  
        var f = function(token:Token, left:Node)
        {
            var precedence = this.precedenceTable[token.type];
            var operand:Node = expression(precedence);
            
            // return AST node with a single child:
            return new PrefixNode(token.type, operand);
        };
        register(type, f, "prefix", precedence);
    }

    /**
     *  'Shortcut' function to make registering infix operators easier.
     *  Adds a generic infix-parsing function.
     *  @param type - Type name of the Token.
     *  @param precedence - Operator precedence of this token type.
     */
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

    /**
     *  'Shortcut' function to make registering postfix operators easier.
     *  Adds a generic postfix-parsing function.
     *  @param type - Type name of the Token.
     *  @param precedence - Operator precedence of this token type.
     */
    private function registerPostfix(type:String, precedence:Int)
    {
        var f = function(token:Token, left:Node)
        {
            // Return AST node with a single child -- the preceding
            // part of the parsed expression.
            return new PostfixNode(token.type, left);
        };
        
        // Postfix operators are actually infix-type (i.e 'not prefix'),
        // so we add them to the infix table.
        register(type, f, "infix", precedence);
    }

    /**
     *  Advance through the token stream. We can optionally use a sort of
     *  'inline assert' to provide guarantees for error-checking purposes.
     *  @param expect - Typestring of the token we expect to encounter.
     */
    private function advance(?expect:String=null):Void
    {
        pos++;
        c = tokens[pos];

        // Skip comment tokens. We leave comment tokens in the token
        // stream for debugging purposes.
        while (c != null && c.type == 'COMMENT')
        {
            pos++;
            c = tokens[pos];
        }

        if (expect != null)
        {
            // Check to make sure that the 'expected' token was encountered.
            if (c.type != expect)
            {
                //@@ERROR
                trace('Expected ${expect}, but got ${c.type}');
            }
        }
    }

    /**
     *  Return the Token after the current token in the stream.
     */
    private function lookahead():Token
    {
        var next_pos = pos + 1;
        var next = tokens[next_pos];

        // Skip comment tokens (which we leave in for debugging):
        while (next != null && next.type == 'COMMENT')
        {
            next_pos++;
            next = tokens[next_pos];
        }

        return next;
    }

    /**
     *  Get the precedence of the next token.
     *  @return Int
     */
    private function getPrecedence():Int
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

    /**
     *  Parse an expression.
     *  @param precedence - Operator precedence
     *  @return Node
     */
    private function expression(precedence:Int):Node
    {
        advance();
        if (prefixFuncs.exists(c.type))
        {
            var prefix = prefixFuncs[c.type];

            // Attempt to parse a prefix operator
            var left = prefix(c, null);

            // Continue consuming tokens while the next token
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