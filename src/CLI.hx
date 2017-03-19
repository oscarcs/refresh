package ;

/**
 *   Class for handling CLI input in a cross-platform way.
 */
class CLI
{
    public static function getArgs():Array<String>
    {
        var args:Array<String> = [];

#if node

        args = Process.argv.slice(2);

#end

        return args;
    }
}

#if node

/**
 *  Node externs
 */
 @:native("process")
 extern class Process
 {
     public static var argv:Array<String>;
 }

#end