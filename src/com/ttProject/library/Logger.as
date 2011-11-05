package com.ttProject.library
{
	import spark.components.TextArea;

	/**
	 * 半透明ウィンドウ上にログを出す
	 */
	public class Logger
	{
		/** 出力先 */
		private static var console:TextArea;
		/** 出力レベル */
		public static const ERROR:int = 0;
		public static const WARN:int  = 1;
		public static const INFO:int  = 2;
		public static const DEBUG:int = 3;
		private static var level:int;
		/**
		 * 初期化
		 */
		public static function setup(target:TextArea, level:int):void
		{
			console = target;
			Logger.level = level;
		}
		/**
		 * error
		 */
		public static function error(msg:*, object:*=""):void
		{
			if(level >= ERROR) {
				console.appendText(object);
				console.appendText(msg);
				console.appendText("\r\n");
			}
		}
		/**
		 * warn
		 */
		public static function warn(msg:*, object:*=""):void
		{
			if(level >= WARN) {
				console.appendText(object);
				console.appendText(msg);
				console.appendText("\r\n");
			}
		}
		/**
		 * info
		 */
		public static function info(msg:*, object:*=""):void
		{
			if(level >= INFO) {
				console.appendText(object);
				console.appendText(msg);
				console.appendText("\r\n");
			}
		}
		/**
		 * debug
		 */
		public static function debug(msg:*, object:*=""):void
		{
			if(level >= DEBUG) {
				console.appendText(object);
				console.appendText(msg);
				console.appendText("\r\n");
			}
		}
	}
}