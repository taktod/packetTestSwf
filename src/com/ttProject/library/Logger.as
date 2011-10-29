package com.ttProject.library
{
	import spark.components.TextArea;

	public class Logger
	{
		private static var console:TextArea;
		public static function setup(target:TextArea):void {
			console = target;
		}
		public static function info(msg:*):void {
			console.appendText(msg);
			console.appendText("\r\n");
		}
	}
}