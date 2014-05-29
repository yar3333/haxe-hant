package;

import hant.Process;

class ProcessTest extends haxe.unit.TestCase
{
    public function testSimple()
    {
		Process.runDetached("sleep", [ "20s" ]);
		assertTrue(true);
    }
}
