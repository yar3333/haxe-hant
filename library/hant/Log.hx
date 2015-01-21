package hant;

#if neko
import neko.Lib;
#elseif php
import php.Lib;
#end

/**
 * Global log class.
 * Using:
 *		Log.instance = new Log(5); // init log at the start of your application; 5 - nesting level limit (messages with greater nesting level will be ignored)
 * 		...
 *		Log.start("MyProcessStartMessage");
 * 		...
 * 		Log.echo("myMessage");
 * 		...
 * 		if (good) Log.finishSuccess(); // finish Process
 * 		else      Log.finishFail();
 */
class Log
{
	public static var instance : Log;
	
    public static function start(message:String, level=0)
    {
        if (instance != null) instance.startInner(message, level);
    }
    
    public static function finishSuccess(?text:String)
    {
		if (instance != null) instance.finishSuccessInner(text);
    }
    
    public static function finishFail(?text:String, ?exceptionToThrow:Dynamic)
    {
		if (instance != null) instance.finishFailInner(text, exceptionToThrow);
    }
	
	public static function echo(message:String, level=0)
	{
		if (instance != null) instance.echoInner(message, level);
	}
	
	//{ instance fields ====================================================================================
	
    var depthLimit : Int;
    var levelLimit : Int;
    var depth : Int;
	var ind : Int;
    var inBlock : Bool;
	var shown : Array<Bool>;
    
    public function new(depthLimit=2147483647, levelLimit=2147483647)
    {
        this.depthLimit = depthLimit;
        this.levelLimit = levelLimit;
        depth = -1;
		ind = 0;
        inBlock = false;
		shown = [];
    }
    
    function startInner(message:String, level=0)
    {
        depth++;
        if (depth < depthLimit)
        {
            if (level < levelLimit)
			{
				if (inBlock) println("");
				print(indent(ind) + message + ": ");
				inBlock = true;
				shown.push(true);
				ind++;
			}
			else
			{
				shown.push(false);
			}
        }
    }
    
    function finishSuccessInner(text="OK")
    {
        if (depth < depthLimit)
        {
            if (shown.pop())
			{
				if (!inBlock) print(indent(ind));
				ind--;
				println("[" + text + "]");
				inBlock = false;
			}
        }
        
        depth--;
    }
    
    function finishFailInner(text="FAIL", ?exceptionToThrow:Dynamic)
    {
        if (depth < depthLimit)
        {
            if (shown.pop())
			{
				if (!inBlock) print(indent(ind));
				ind--;
				println("[" + text + "]");
				inBlock = false;
			}
        }
        
        depth--;
		
		if (exceptionToThrow != null)
		{
			stdlib.Exception.rethrow(exceptionToThrow);
		}
    }
	
	function echoInner(message:String, level=0)
	{
		if (depth < depthLimit)
		{
            if (level < levelLimit)
			{
				if (inBlock) println("");
				println(indent(ind + 1) + message);
				inBlock = false;
			}
		}
	}
	
    function indent(depth:Int) : String
    {
        return StringTools.rpad("", " ", depth * 2);
    }
	
	function print(s:String)
	{
		Lib.print(s);
	}
	
	function println(s:String)
	{
		Lib.println(s);
	}
	
	//}
}
