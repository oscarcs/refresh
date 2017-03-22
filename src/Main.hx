package ;

import Parser;
import Node;
import backends.BFGenerator;
import backends.JSGenerator;
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
        
        compile();
    }

    static function compile()
    {
        var COMPILE:Bool = true;
        var DEFAULT_INPUT_PATH:String = "test/lex.prog";
        var INPUT_PATH:String = null;
        var DEFAULT_OUTPUT_PATH:String = "test/lex.js";
        var OUTPUT_PATH:String = null;
        var TRACE_LEVEL:Int = 0; // 0-3
        var BACKEND:String = 'js';

        var args = CLI.getArgs();
        if (args != null)
        {
            var hasInputPath:Bool = false;
            for (arg in args)
            {
                if (arg == '-h' || arg == '--help') {
                    printHelp();
                    COMPILE = false;
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
                else if (arg == '-t0' || arg == '-t1' || arg == '-t2' || arg == '-t3')
                {
                    TRACE_LEVEL = Std.parseInt(arg.substring(2));
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
            // use default settings:
            if (Files.exists(DEFAULT_INPUT_PATH))
            {
                INPUT_PATH = DEFAULT_INPUT_PATH;
            }
            OUTPUT_PATH = DEFAULT_OUTPUT_PATH;
            TRACE_LEVEL = 3; // max trace level
            BACKEND = 'js';
        }

        if (INPUT_PATH == null) INPUT_PATH = DEFAULT_INPUT_PATH;
        if (OUTPUT_PATH == null) OUTPUT_PATH = DEFAULT_OUTPUT_PATH;

        if (COMPILE)
        {
            // read in the file:
            var data = Files.read(INPUT_PATH);
            
            // lex the code:
            var lexer = new Lexer(data);
            var tokens = lexer.lex();

            // trace the tokens:
            if (TRACE_LEVEL >= 2)
            {
                for (token in tokens)
                {
                    trace('Ln ${token.line}, Col ${token.pos}: ${token.type} (${token.lexeme})');
                }
                trace('');
            }
            
            // parse the code:
            var parser = new Parser(tokens);
            var root = parser.parse();
            
            // trace the AST:
            if (TRACE_LEVEL >= 2)
            {
                trace(root);
            }

            // generate the code:1
            var generator:IGenerator;
            switch (BACKEND)
            {
                case 'js':
                    generator = new JSGenerator(root);

                case 'bf':
                    generator = new BFGenerator(root);

                default:
                    throw 'backend not found';
            }        
            var output = generator.generate();
            
            // trace the generated code:
            if (TRACE_LEVEL >= 3)
            {
                trace('_______ \'${OUTPUT_PATH}\': ________________________________________');
                trace(output);
            }

            //@@TODO: check the output directory exists
            // output the generated code:
            Files.write(OUTPUT_PATH, output);
        }
    }

    static function printHelp()
    {
        trace("Refresh Compiler");
        trace("(Pre-alpha)\n");
        trace("Usage: refresh [options] file_in file_out");
        trace("Options:");
        trace("--help, -h:\t\t Display help.");
        trace("-t0, -t1, -t2, -t3:\t Set the trace level.");
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