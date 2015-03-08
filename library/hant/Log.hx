package hant;
import stdlib.Exception;

using StringTools;

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
	public static var instance = new Log();
	
    public static function start(message:String, level=1)
    {
        if (instance != null) instance.startInner(message, level);
    }
    
    public static function finishSuccess(text="OK")
    {
		if (instance != null) instance.finishSuccessInner(text);
    }
    
    public static function finishFail(text="FAIL")
    {
		if (instance != null) instance.finishFailInner(text);
    }
	
	public static function echo(message:String, level=1)
	{
		if (instance != null) instance.echoInner(message, level);
	}
	
	public static function process(message:String, level=1, procFunc:Void->Void) : Void
	{
		start(message, level);
		try
		{
			procFunc();
		}
		catch (e:Dynamic)
		{
			finishFail();
			Exception.rethrow(e);
		}
		finishSuccess();
	}
	
	public static function processResult<T>(message:String, level=1, procFunc:Void->T) : T
	{
		start(message, level);
		var r : T = null;
		try
		{
			r = procFunc();
		}
		catch (e:Dynamic)
		{
			finishFail();
			Exception.rethrow(e);
		}
		finishSuccess();
		return r;
	}
	
	//{ instance fields ====================================================================================
	
    public var depthLimit : Int;
    public var levelLimit : Int;
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
    
    function startInner(message:String, level:Int)
    {
        depth++;
        if (depth < depthLimit)
        {
            if (level <= levelLimit)
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
    
    function finishSuccessInner(text:String)
    {
        if (depth < depthLimit)
        {
            if (shown.pop())
			{
				text = Std.string(text);
				if (!inBlock) print(indent(ind));
				ind--;
				if (text.indexOf("\n") < 0)	println("[" + text + "]");
				else						println("\n" + indent(ind + 1) + "[\n" + indent(ind + 2) + text.replace("\n", "\n" + indent(ind + 2)) + "\n" + indent(ind + 1) + "]");
				inBlock = false;
			}
        }
        depth--;
    }
    
    function finishFailInner(text:String)
    {
		if (depth < depthLimit)
        {
			if (shown.pop())
			{
				text = Std.string(text);
				if (!inBlock) print(indent(ind));
				ind--;
				if (text.indexOf("\n") < 0)	println("[" + text + "]");
				else						println("\n" + indent(ind + 1) + "[\n" + indent(ind + 2) + text.replace("\n", "\n" + indent(ind + 2)) + "\n" + indent(ind + 1) + "]");
				inBlock = false;
			}
        }
        depth--;
    }
	
	function echoInner(text:String, level:Int)
	{
		if (depth < depthLimit)
		{
            if (level <= levelLimit)
			{
				text = Std.string(text);
				if (inBlock) println("");
				println(indent(ind) + text.replace("\n", "\n" + indent(ind)));
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
		Sys.print(s);
	}
	
	function println(s:String)
	{
		Sys.println(s);
	}
	
	//}
}
