package;

import neko.HaqNative;

class TestsA extends haxe.unit.TestCase
{
    public function testBasic()
    {
		HaqNative.copyFilePreservingAttributes("������.txt", "������2.txt");
		this.assertTrue(true);
    }
}
