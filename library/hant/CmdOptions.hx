package hant;

import Type;

private typedef Option = 
{
	var name : String;
	var defaultValue : Dynamic;
	var type : ValueType;
	var switches : Array<String>;
	var help : String;
	var repeatable : Bool;
}

/**
 * Usage example:
 * var parser = new CmdOptions();
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
	var paramWoSwitchIndex : Int;
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
		var type = Type.typeof(defaultValue);
		if (type == ValueType.TNull) type = ValueType.TClass(String);
		addInner(name, defaultValue, type, switches, help, false);
	}
	
	public function addRepeatable(name:String, type:ValueType, ?switches:Array<String>, help="")
	{
		if (type != ValueType.TBool)
		{
			if (type == ValueType.TNull) type = ValueType.TClass(String);
			addInner(name, [], type, switches, help, true);
		}
		else
		{
			throw "Type 'bool' can not be used for repeatable option '" + name + "'.";
		}
	}
	
	function addInner(name:String, defaultValue:Dynamic, type:ValueType, switches:Array<String>, help:String, repeatable:Bool)
	{
		if (!hasOption(name))
		{
			options.push( { name:name, defaultValue:defaultValue, type:type, switches:switches, help:help, repeatable:repeatable } );
		}
		else
		{
			throw "Option '" + name + "' already added.";
		}
	}
	
	public function getHelpMessage() : String
	{
		var s = "";
		for (opt in options)
		{
			if (opt.switches != null)
			{
				s += opt.switches.join(", ");
				if (opt.switches.length > 1)
				{
					s += "\n";
				}
			}
			else
			{
				s += "<" + opt.name + ">";
			}
			if (opt.help != null) 
			{
				s += "\t" + opt.help;
			}
			s += "\n";
		}
		s += "\n";
		return s;
	}

	public function parse(args:Array<String>) : Hash<Dynamic>
	{
		this.args = args.copy();
		paramWoSwitchIndex = 0;
		
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
							resolveSwitch(opt, arg);
							return;
						}
					}
				}
			}
			
			throw "Unknow switch '" + arg + "'.";
		}
		else
		{
			var opt = getNextNoSwitchOption();
			if (opt != null)
			{
				args.unshift(arg);
				resolveSwitch(opt, arg);
			}
			else
			{
				throw "Unexpected argument '" + arg + "'.";
			}
		}
	}

	function resolveSwitch(opt:Option, s:String) : Void
	{
		switch (opt.type)
		{
			case ValueType.TInt:
				ensureValueExist(s);
				if (!opt.repeatable) params.set(opt.name, Std.parseInt(args.shift()));
				else                 params.get(opt.name).push(Std.parseInt(args.shift()));
			
			case ValueType.TFloat:
				ensureValueExist(s);
				if (!opt.repeatable) params.set(opt.name, Std.parseFloat(args.shift()));
				else                 params.get(opt.name).push(Std.parseFloat(args.shift()));
				
			case ValueType.TBool:
				params.set(opt.name, !opt.defaultValue);
			
			case ValueType.TClass(c):
				if (c == String)
				{
					ensureValueExist(s);
					if (!opt.repeatable) params.set(opt.name, args.shift());
					else                 params.get(opt.name).push(args.shift());
				}
				else
				{
					throw "Option type of class '" + Type.getClassName(c) + "' not supported.";
				}
			
			default:
				throw "Option type '" + opt.type + "' not supported.";
		}
	}
	
	function hasOption(name:String) : Bool
	{
		return Lambda.exists(options, function(opt) return opt.name == name);
	}
	
	function ensureValueExist(s:String) : Void
	{
		if (args.length == 0)
		{
			throw "Missing value after '" + s + "' switch.";
		}
	}
	
	function getNextNoSwitchOption() : Option
	{
		for (i in paramWoSwitchIndex...options.length)
		{
			if (options[i].switches == null)
			{
				paramWoSwitchIndex = i + 1;
				return options[i];
			}
		}
		return null;
	}
}