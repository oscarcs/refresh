package ;

import Lexer;
import Node;

/**
 *  This class contains code to parse 'statements', which under 
 *  the relaxed definition I use here includes the program itself,
 *  blocks of code, and all semicolon-terminated statements including
 *  those which do not contain expressions.
 */
class StatementParser extends ExpressionParser
{
    public function new(tokens:Array<Token>)
    {
        super(tokens);
    }

    override public function parse():Node
    {
        return program();
    }

    /**
     *  This function deals with the program structure,
     *  consisting of a list of statements.
     */
    private function program():Node
    {
        var nodes:Array<Node> = [];
        var node:Node = null;
        while (lookahead() != null && lookahead().type != "END")
        {
            node = statement();
            nodes.push(node);
        };
        return new RootNode(nodes);
    }

    /**
     *  In the grammar for this language, a 'statement' is basically
     *  'anything that isn't an expression'.
     */
    private function statement():Node
    {
        var node:Node = null;
        
        // Check the next token in the stream and determine how to
        // parse the next statement.
        switch (lookahead().type) 
        {
            case "L_BRACE":
                node = block();
                advance("R_BRACE");

            // If the next token is an identifier, the statement must
            // consist of an assignment-expression.
            case "IDENTIFIER":
                node = expression(0);
                advance("SEMICOLON");

            // Here, the DECLARATION type is any keyword that marks the
            // declaration of a new variable.
            case "DECLARATION":
                node = declaration();
                advance("SEMICOLON");

            // Here, the FUNCTION type is any function-declaring keyword.
            case "FUNCTION":
                node = functionDeclaration();
                advance();

            case "WHILE":
                node = whileLoop();
                advance();

            case "IF":
                node = ifStatement();
                advance();

            // Parse a break statement, which should just consist
            // of the keyword followed by a semicolon.
            case "BREAK":
                advance("BREAK");
                node = new BreakNode();
                advance("SEMICOLON");

            default:
                //@@ERROR
                throw 'Invalid statement, can\'t start with ${lookahead().type}';
        }

        // Check symbol table to see if we just parsed an assignment.
        // If we did, we need to check that it's in the symbol table:
        if (Std.is(node, AssignNode))
        {
            var n = cast(node, AssignNode);
            if (!symtab.exists(n.left.value)) 
            {
                //@@ERROR: undefined variable
                throw 'Undefined variable "${n.left.value}" cannot be assigned to.';
            }
        }

        return node;
    }

    /**
     *  Parse a statement containing a variable declaration.
     *  @return Node
     */
    private function declaration():Node
    {
        advance("DECLARATION");
        var expr = expression(0);

        var n = cast(expr, AssignNode);

        // Check if the identifier name exists already in the symbol
        // table. If it doesn't, add it, otherwise throw an error.
        if (!symtab.exists(n.left.value))
        {
            symtab.put(n.left.value, { type:"Dynamic" });
        }
        else
        {
            //@@ERROR
            throw 'Identifier ${n.left.value} has already been defined.';
        }

        return expr;
    }

    /**
     *  A block contains a list of statements. It may possibly be the body of
     *  another type of statement.
     */
    private function block():Node
    {
        // Enter a new scope for the block.
        symtab.push();

        advance("L_BRACE");
        var statements:Array<Node> = [];

        // Parse statements until a block-terminator is reached.
        while (lookahead().type != "R_BRACE")
        {
            statements.push(statement());
        }

        // Exit the block scope.
        symtab.pop();

        return new BlockNode(statements);
    }

    /**
     *  Parse the declaration of a new function.
     *  @return Node
     */
    private function functionDeclaration():Node
    {
        advance("FUNCTION");
        advance("IDENTIFIER");
        var name = new IdentNode(c.lexeme);

        // The start of the argument-list:
        advance("L_PAREN");

        //@@TYPECHECKER
        //@@TODO: better method of representing types
        // The type string
        var type = "";

        var args:Array<Node> = [];
        while (true)
        {
            advance("IDENTIFIER");

            args.push(new IdentNode(c.lexeme));

            advance("COLON");
            advance("IDENTIFIER");

            //@@TYPECHECKER
            // add type data:
            type += '${c.lexeme}->';

            if (lookahead().type == "R_PAREN") break;
            advance("COMMA");
        }

        // Denotes the end of the argument-list
        advance("R_PAREN");

        // Parse the type hint following the function header
        if (lookahead().type == "COLON")
        {
            advance("COLON");
            advance("IDENTIFIER");

            // Explicitly add the type of the function 
            type += c.lexeme;
        }
        else {

            // Infer the type of the function:
            //@@TYPECHECKER: infer rather than use dynamic
            type += 'Dynamic';
        }

        var body = block().children;

        // Add to the symbol table:
        symtab.put(name.value, { type: type });
        
        return new FunctionNode(name, args, body);
    }

    /**
     *  While loop statement parser.
     *  @return Node
     */
    private function whileLoop():Node
    {
        // Parse the header of the while statement:
        advance("WHILE");
        advance("L_PAREN");
        var condition = expression(0);
        advance("R_PAREN");
        
        var body = block().children;

        return new WhileNode(condition, body);
    }

    /**
     *  Conditional statement parser.
     *  @return Node
     */
    private function ifStatement():Node
    {
        // Parse the header of the if statement:
        advance("IF");
        advance("L_PAREN");
        var condition = expression(0);
        advance("R_PAREN");
        
        var body = block().children;

        return new IfNode(condition, body);
    }
}