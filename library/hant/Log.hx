package hant;

#if neko
import neko.Lib;
#elseif php
import php.Lib;
#end

class Log 
{
    var verboseLevel : Int;
    var level : Int;
    
    var inBlock : Bool;
    
    var messages : IntHash<String>;
    
    public function new(verboseLevel:Int) 
    {
        this.verboseLevel = verboseLevel;
        level = -1;
        inBlock = false;
        messages = new IntHash<String>();
    }
    
    public function start(message:String)
    {
        level++;
        if (level < verboseLevel)
        {
            if (inBlock) println("");
            print(indent(level) + message + ": ");
            inBlock = true;
        }
        messages.set(level, message);
    }
    
    public function finishOk()
    {
        if (level < verboseLevel)
        {
            if (!inBlock) print(indent(level + 1));
            println("[OK]");
            inBlock = false;
        }
        
        level--;
    }
    
    public function finishFail(message:String)
    {
        if (level < verboseLevel)
        {
            if (!inBlock) print(indent(level + 1));
            println("[FAIL]");
            inBlock = false;
        }
        
        level--;
        throw level + 1 < verboseLevel
            ? message 
            : messages.get(level + 1) + " (" + message + ")";
    }
	
	public function trace(message:String)
	{
		if (level < verboseLevel)
		{
			if (inBlock) println("");
			println(indent(level) + message);
			inBlock = false;
		}
	}
	
    function indent(level:Int) : String
    {
        return StringTools.rpad("", " ", level * 2);
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
