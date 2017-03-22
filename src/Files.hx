package ;

#if (python || neko || java || cpp || lua || php)

import sys.io.FileInput;
import sys.FileSystem;
import haxe.io.Eof;

#elseif (js && !node)

import js.html.XMLHttpRequest;
import js.html.Event;

#end

/*
 * Class for opening and managing files in a cross-platform way.
*/
class Files
{
    /**
     *  Read in a file.
     *  @param path Path to the file. 
     *  @return String containing file contents.
     */
    public static function read(path:String):String
    {
        var output:String = "";

        //@@TEST: Crossplaform file reading
        #if (python || neko || java || cpp || lua || php)

            // Use native file loading & read line-by-line.
            var handle:FileInput = File.read(path, false);
            try
            {
                while (true)
                {
                    var str = handle.
                    // Add newlines to resulting string.
                    output += str + "\n";
                }
            }
            catch (e:Eof) {   }
            handle.close();

        #elseif (js && !node)

            // Use XHR requests.
            var request = new XMLHttpRequest();
            request.open("GET", path, false);
            request.onload = function(e:Event) {
                output = request.response;
            };

            // if there's an error, handle it:
            request.onerror = function(e:Event) {
                trace(e);
            };
            request.send();

        #elseif node

            output = FS.readFileSync(path).toString();

        #end

        return output;
    }

    /**
     *  Write out a file.
     *  @param path Path to the file. 
     *  @param data String containing file contents.
     */
    public static function write(path:String, data:String)
    {
        //@@TEST: Crossplatform file writing.
        #if (python || neko || java || cpp || lua || php)

            try
            {
                File.saveContent(path, data);
            }
            catch(e:Dynamic) { trace(e); }

        #elseif (js && !node)

            //@@TODO: output files using XHR.

        #elseif node

            FS.writeFileSync(path, data);

        #end
    }

    /**
     *  Check if a file exists.
     *  @param path Path to the file.
     *  @return Bool
     */
    public static function exists(path:String):Bool
    {
        //@@TEST: Crossplatform existence checking.
        #if (python || neko || java || cpp || lua || php)

            return FileSystem.exists(path);

        #elseif (js && !node)

            //@@TODO: check file existence using XHR.

        #elseif node

            return FS.existsSync(path);

        #end  

        return false;
    }
}


#if node

/*
 * Node externs
 */
@:jsRequire("fs")
extern class FS {
  static function readFileSync(path:String):String;
  static function writeFileSync(path:String, data:String):Void;
  static function existsSync(path:String):Bool;
}

#end