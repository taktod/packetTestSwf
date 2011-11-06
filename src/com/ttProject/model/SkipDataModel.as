package com.ttProject.model
{
	import com.ttProject.library.Logger;
	
	import flash.utils.ByteArray;

	/**
	 * 通信速度の性でデータが飛んでいる部分を補完するモデル
	 * 本来あるべき番のデータがくるまで、蓄えるモデルです。
	 */
	public class SkipDataModel
	{
		private var startPosition:Number; // 飛びがはじまった位置
		private var dataArray:Array; // 飛んでいる間に届いたデータ
		private var loadedPosition:Number; // 読み込み済みの位置
		/**
		 * コンストラクタ
		 */
		public function SkipDataModel(startPosition:Number)
		{
			Logger.info("createSkipDataModel");
			this.startPosition = startPosition;
			this.loadedPosition = 0;
			dataArray = new Array();
		}
		/**
		 * データを追加する。
		 */
		public function setData(index:Number, data:*):void
		{
			if(index >= startPosition) {
				dataArray[index - startPosition] = data;
			}
		}
		/**
		 * データを取得する。(ただしいデータとして取得できる場合は応答する。そうでない場合はnull)
		 */
		public function getData():Array
		{
//			Logger.info("a:" + dataArray.length);
			var result:Array = new Array;
//			Logger.info("a:" + loadedPosition);
//			Logger.info(dataArray[0].toString());
//			Logger.info(dataArray[1].toString());
			var length:int = dataArray.length - loadedPosition;
			for(var i:int = 0;i < length;i ++) {
				if(dataArray[loadedPosition] != null) {
					Logger.info("not null");
					result[i] = dataArray[loadedPosition];
					loadedPosition ++;
				}
				else {
					Logger.info("null");
					break;
				}
			}
			Logger.info(result.length);
			return result;
		}
		public function haveSomeData():Boolean
		{
			Logger.info(dataArray.length);
			return loadedPosition != dataArray.length;
		}
	}
}