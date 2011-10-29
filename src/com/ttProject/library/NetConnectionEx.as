package com.ttProject.library
{
	import flash.external.ExternalInterface;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.ByteArray;
	
	public class NetConnectionEx extends NetConnection
	{
		public function NetConnectionEx() {
			super();
		}
		public function test(dat:*):void {
			var list:Array = dat;
			var ba:ByteArray = new ByteArray;
//			ba.writeObject(["a","b","c"]);
			// ループでまわしてがんばって書くしかない。
			try {
				ba.writeObject(list);
				ba.position = 0;
			}
			catch (e:Error) {
			}
		}
	}
}