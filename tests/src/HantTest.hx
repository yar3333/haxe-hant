package;

import hant.FileSystemTools;
import hant.CmdOptions;
import hant.NdllTools;

class HantTest extends haxe.unit.TestCase
{
    public function testSimple()
    {
		var fs = new FileSystemTools(new hant.Log(5));
		assertTrue(fs != null);
    }
	
	public function testCmdOptions()
	{
		var parser = new CmdOptions();
		parser.add("isRecursive", false, [ "-r", "--recursive"]);
		parser.add("count", 0, [ "-c", "--count"]);
		parser.add("path", "bin");
		parser.parse([ "testpath", "-c", "10", "-r" ]);
		
		assertEquals(10, parser.get("count"));
		assertEquals(true, parser.get("isRecursive"));
		assertEquals("testpath", parser.get("path"));
	}
	
	public function testNdllHant()
	{
		var lib = "hant";
		var path = NdllTools.getPath(lib);
		print("\n\tPath to ndll '" + lib + "' is '" + path + "'\n");
		assertTrue(path != null);
	}
	
	public function testNdllCurl()
	{
		var lib = "curl";
		var path = NdllTools.getPath(lib);
		print("\n\tPath to ndll '" + lib + "' is '" + path + "'\n");
		assertTrue(path != null);
	}
}
