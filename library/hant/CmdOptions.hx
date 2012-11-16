package hant;

private typedef Option = 
{
	var name : String;
	var defaultValue : Dynamic;
	var switches : Array<String>;
	var help : String;
}

/**
 * Usage example:
 * var parser = new CommandLineOptions();
 * parser.addOption('isRecursive', false, [ '-r', '--recursive']);
 * parser.addOption('count', 0, [ '-c', '--count']);
 * parser.addOption('file', 'bin');
 * parser.parse([ 'test', '-c', '10', '-r' ]);
 * // now: 
 * // parser.params = { 'c' => 10, 'r' => true, file => 'test' }
 */
class CmdOptions
{
	var options : Array<Option>;
	var args : Array<String>;
	
	var paramWoSwitchesIndex : Int;
	
	var params : Hash<Dynamic>;

	public function new()
	{
		options = [];
	}
	
	public function get(name:String) : Dynamic
	{
		return params.get(name);
	}
	
	public function add(name:String, defaultValue:Dynamic, ?switches:Array<String>, help="")
	{
		options.push({ name:name, defaultValue:defaultValue, switches:switches, help:help });
	}

	public function getHelpMessage() : String
	{
		var s = "";
		for (a in options)
		{
			s += a.switches.join(", ");
			if (a.switches.length > 1)
			{
				s += "\n";
			}
			if (a.help != null) 
			{
				s += "\t" + a.help;
			}
			s += "\n";
		}
		s += "\n";
		return s;
	}

	public function parse(args:Array<String>) : Hash<Dynamic>
	{
		this.args = args.copy();
		
		params = new Hash<Dynamic>();
		for (opt in options)
		{
			params.set(opt.name, opt.defaultValue);
		}
		
		
		while (this.args.length > 0)
		{
			parseElement();
		}
		
		return params;
	}

	function parseElement()
	{
		var arg = args.shift();
		
		if (arg.substr(0, 1) == "-")
		{
			arg = ~/^(--?.+)=(.+)$/.customReplace(arg, function(r)
			{
				args.unshift(r.matched(2));
				return r.matched(1);
			});
			
			for (opt in options)
			{
				if (opt.switches != null)
				{
					for (s in opt.switches)
					{
						if (s == arg)
						{
							resolveSwitch(opt.name, arg, opt.defaultValue);
							return;
						}
					}
				}
			}
			
			throw "Unknow switch '" + arg + "'.";
		}
		else
		{
			for (opt in options)
			{
				if (opt.switches == null)
				{
					for (s in opt.switches)
					{
						if (s == arg)
						{
							resolveSwitch(opt.name, arg, opt.defaultValue);
							return;
						}
					}
				}
			}
		}
	}

	function resolveSwitch(name:String, s:String, defaultValue:Dynamic) : Void
	{
		switch (Type.typeof(defaultValue))
		{
			case ValueType.TInt:
				ensureValueExist(s);
				params.set(name, Std.parseInt(args.shift()));
			
			case ValueType.TFloat:
				ensureValueExist(s);
				params.set(name, Std.parseFloat(args.shift()));
				
			case ValueType.TBool:
				params.set(name, !defaultValue);
			
			case ValueType.TNull:
				ensureValueExist(s);
				params.set(name, true);
			
			case ValueType.TClass(c):
				if (c == String)
				{
					ensureValueExist(s);
					params.set(name, args.shift());
				}
				else
				{
					throw "Option type of class '" + Type.getClassName(c) + "' not supported.";
				}
			
			default:
				throw "Option type '" + Type.typeof(defaultValue) + "' not supported.";
		}
	}
	
	function ensureValueExist(s:String) : Void
	{
		if (args.length == 0)
		{
			throw "Missing value after '" + s + "' switch.";
		}
	}
}