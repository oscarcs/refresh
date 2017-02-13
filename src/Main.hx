package ;

class Main
{    
    static function main()
    {   
        // Override default trace function.
        var _trace = haxe.Log.trace;
        haxe.Log.trace = function(v:Dynamic, ?info:haxe.PosInfos) 
        {    
            _trace(v, null);
        }
    }
}