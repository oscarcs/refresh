package ;

import Node;
import backends.BFGenerator;
import backends.JSGenerator;
import backends.WASMGenerator;
import backends.IGenerator;

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
            else if (Std.is(v, Node))
            {
                _trace(stringifyNodeRecurse(v), null);
            }
            else if (Std.is(v, { isPointer:Bool, value:Int }))
            {
                _trace(stringifyBFVar(v), null);
            }
            else if (Std.is(v, BFLinearExpr))
            {
                _trace(stringifyBFLinearExpr(v), null);
            }
            else
            {
                _trace(v, null);
            }
        }
        
        try
        {
            compile();
        }
        catch (e:Dynamic)
        {
            trace('Error: ${e}');
        }
    }

    static function compile()
    {
        var DEFAULT_INPUT_PATH:String = "test/lex.prog";
        var INPUT_PATH:String = null;
        var DEFAULT_OUTPUT_PATH:String = "test/lex.js";
        var OUTPUT_PATH:String = null;
        var DEBUG_TRACE:Bool = false;
        var BACKEND:String = 'js';

        var args = CLI.getArgs();
        if (args.length > 0)
        {
            var hasInputPath:Bool = false;
            for (arg in args)
            {
                if (arg == '-h' || arg == '--help') {
                    printHelp();
                    return;
                }
                else if (arg == '-js')
                {
                    // use JS backend:
                    BACKEND = 'js';
                }
                else if (arg == '-bf')
                {
                    // use BF backend:
                    BACKEND = 'bf';
                }
                else if (arg == '-wasm') {
                    // use WebAssembly backend:
                    BACKEND = 'wasm';
                }
                else if (arg == '--debug')
                {
                    DEBUG_TRACE = true;
                }
                else if (Files.exists(arg))
                {
                    if (!hasInputPath)
                    {
                        INPUT_PATH = arg;
                        hasInputPath = true;
                    }
                    else
                    {
                        OUTPUT_PATH = arg;
                    }
                }
                else if (hasInputPath)
                {
                    OUTPUT_PATH = arg;
                }
            }
        }
        else {
            trace("Refresh Compiler: refresh --help for help.");
            return;
        }

        if (INPUT_PATH == null) INPUT_PATH = DEFAULT_INPUT_PATH;
        if (OUTPUT_PATH == null) OUTPUT_PATH = DEFAULT_OUTPUT_PATH;

        // Read in the file:
        var data = Files.read(INPUT_PATH);
        
        // Perform lexical analysis on the program text:
        var lexer = new Lexer(data);
        var tokens = lexer.lex();
        
        // Parse the program text:
        var parser = new StatementParser(tokens);
        var root = parser.parse();

        // Generate output:
        var generator:IGenerator;
        switch (BACKEND)
        {
            case 'js':
                generator = new JSGenerator(root);

            case 'bf':
                generator = new BFGenerator(root);

            case 'wasm':
                generator = new WASMGenerator(root);

            default:
                throw 'backend not found';
        }        
        var output = generator.generate();

        // If the 'debug trace' flag is set, trace some of the internal compiler
        // variables for compiler debugging purposes.
        if (DEBUG_TRACE)
        {
            // Output the Tokens:
            trace('TOKENS:\n');
            for (token in tokens)
            {
                trace('Ln ${token.line}, Col ${token.pos}: ${token.type} (${token.lexeme})');
            }
            trace('');
            
            // Output the AST:
            trace('ABSTRACT SYNTAX TREE:\n');
            trace(root);
            trace('');

            // Output the generated code:
            trace('CODE OUTPUT TO ${OUTPUT_PATH}:\n');
            trace(output);
            trace('________________________________________________________________________________');
        }

        //@@TODO: Check the output directory exists
        // Write out the generated code to a file:
        Files.write(OUTPUT_PATH, output);
    }

    static function printHelp()
    {
        trace("Refresh Compiler");
        trace("(Pre-alpha)\n");
        trace("Usage: refresh [options] file_in file_out");
        trace("Options:");
        trace("--help, -h: \t\tDisplay help.");
        trace("--debug: \t\tDump internal compiler variables for debugging the compiler.");
    }

    static function stringifyBFVar(bfvar:BFVar):String
    {
        var str = '';
        str += bfvar.isPointer ? '*' : '';
        str += bfvar.value;
        return str;
    }

    static function stringifyBFLinearExpr(expr:BFLinearExpr):String
    {
        var str = '';
        str += '${stringifyBFVar(expr.lvalue)} = ${stringifyBFVar(expr.left)} ${expr.op} ${stringifyBFVar(expr.right)};';
        return str;
    }

    static function stringifyNodeRecurse(root:Node):String
    {
        var str = "";

        var nodes:Array<Node> = [root];
        var depths:Array<Int> = [0];
        while (nodes.length > 0)
        {
            var cur = nodes.shift();
            var curDepth = depths.shift();

            // prepend the current children:
            nodes = cur.children.concat(nodes);
            
            // update the virtual indent queue:
            for (i in cur.children)
            {
                depths.unshift(curDepth + 1);
            }

            var indent = '';
            for (i in 0...curDepth) indent += '    ';
            str += indent + stringifyNode(cur);
            str += "\n";
        }

        return str;
    }

    static function stringifyNode(node:Node)
    {
        var className:String = Type.getClassName(Type.getClass(node));
        var plural = node.children.length == 1 ? 'child' : 'children';
        return '${node.value} (${className}, ${node.children.length} ${plural})';
    }
}