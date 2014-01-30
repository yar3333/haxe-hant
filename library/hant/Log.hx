package hant;

#if neko
import neko.Lib;
#elseif php
import php.Lib;
#end

class Log 
{
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
    
    public function start(message:String, level=0)
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
    
    public function finishOk()
    {
        if (depth < depthLimit)
        {
            if (shown.pop())
			{
				if (!inBlock) print(indent(ind));
				ind--;
				println("[OK]");
				inBlock = false;
			}
        }
        
        depth--;
    }
    
    public function finishFail(?exceptionToThrow:Dynamic)
    {
        if (depth < depthLimit)
        {
            if (shown.pop())
			{
				if (!inBlock) print(indent(ind));
				ind--;
				println("[FAIL]");
				inBlock = false;
			}
        }
        
        depth--;
		
		if (exceptionToThrow != null)
		{
			stdlib.Exception.rethrow(exceptionToThrow);
		}
    }
	
	public function trace(message:String, level=0)
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
}
