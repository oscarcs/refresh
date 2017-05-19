package ;

import Lexer;
import Node;

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

    // consisting of "statement-list END":
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

    // consisting of "block | declaration | expression":
    private function statement():Node
    {
        var node:Node = null;
        if (lookahead().type == "L_BRACE")
        {
            node = block();
            advance("R_BRACE");
        }
        else if (lookahead().type == "IDENTIFIER")
        {
            node = expression(0);
            advance("SEMICOLON");
        }   
        else if (lookahead().type == "DECLARATION")
        {
            node = declaration();
            advance("SEMICOLON");
        }
        else if (lookahead().type == "FUNCTION")
        {
            node = functionDeclaration();
            advance();
        }
        else if (lookahead().type == "WHILE")
        {
            node = whileLoop();
            advance();
        }
        else if (lookahead().type == "IF")
        {
            node = ifStatement();
            advance();
        }
        else if (lookahead().type == "BREAK")
        {
            advance("BREAK");
            node = new BreakNode();
            advance("SEMICOLON");
        }
        else
        {
            //@@ERROR
            throw 'Invalid statement, can\'t start with ${lookahead().type}';
        }

        // check symbol table if we just parsed an assignment:
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

    // consistion of 'let identifier = expression':
    private function declaration():Node
    {
        advance("DECLARATION");
        var expr = expression(0);

        // add to symbol table:
        var n = cast(expr, AssignNode);
        if (!symtab.exists(n.left.value))
        {
            symtab.put(n.left.value, { type:"Dynamic" });
        }
        else
        {
            throw 'Identifier ${n.left.value} has already been defined.';
        }

        return expr;
    }

        // consisting of "{ statement-list }":
    private function block():Node
    {
        symtab.push();

        advance("L_BRACE");
        var statements:Array<Node> = [];
        while (lookahead().type != "R_BRACE")
        {
            statements.push(statement());
        }

        symtab.pop();

        return new BlockNode(statements);
    }

    private function functionDeclaration():Node
    {
        advance("FUNCTION");
        advance("IDENTIFIER");
        var name = new IdentNode(c.lexeme);

        advance("L_PAREN");
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
        advance("R_PAREN");
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

        // add to the symtab:
        symtab.put(name.value, { type: type });
        
        return new FunctionNode(name, args, body);
    }

    private function whileLoop():Node
    {
        advance("WHILE");
        advance("L_PAREN");
        var condition = expression(0);
        advance("R_PAREN");
        
        var body = block().children;

        return new WhileNode(condition, body);
    }

    private function ifStatement():Node
    {
        advance("IF");
        advance("L_PAREN");
        var condition = expression(0);
        advance("R_PAREN");
        
        var body = block().children;

        return new IfNode(condition, body);
    }
}