package com.ttProject.model
{
	import com.ttProject.library.Logger;
	
	import flash.net.NetGroup;
	import flash.utils.ByteArray;
	
	/**
	 * rtmfp上の動画パケットの管理用モデル
	 */
	public class FlvDataModel
	{
		// クラスの中にうめこんでもっていると、複数のnetGroupにまたがっているときに動作がうまくいかないのでなんとかしておく。
		private var flvHeader:ByteArray; // flvHeader情報
		private var metaCount:int; // メタ情報数
		private var metaDataArray:Array; // メタデータ情報

		private var skipDataModel:SkipDataModel = null;
		private var nextPosition:Number;
		/**
		 * コンストラクタ
		 */
		public function FlvDataModel()
		{
			clear();
		}
		/**
		 * すべてのデータを消去する。
		 */
		public function clear():void
		{
			flvHeader = null;
			metaCount = 0;
			metaDataArray = new Array();
			nextPosition = -1;
			skipDataModel = null;
		}
		/**
		 * flvHeaderを設置する。
		 */
		public function setFlvHeader(data:ByteArray):void
		{
			clear(); // FlvEndがこない状態でFlvHeaderが呼ばれることがあるので、初期化されていないときがある。
			flvHeader = new ByteArray();
			flvHeader.writeBytes(data);
		}
		/**
		 * メタデータ数を設置する。
		 */
		public function setMetaCount(count:int):void
		{
			Logger.info("getMetaCount:" + count);
			metaCount = count;
		}
		/**
		 * メタデータを設置する。
		 */
		public function setMetaData(index:Number, data:ByteArray):void
		{
			Logger.info("getMetaData:" + index);
			if(metaDataArray.length == metaCount) {
				// すでにメタデータダウンロード済みなので処理しない。
				return;
			}
			var ba:ByteArray = new ByteArray();
			ba.writeBytes(data);
			metaDataArray[index] = ba;
		}
		public function isReadyToPlay():Boolean {
			// flvヘッダ情報は取得済みか？
			if(!(flvHeader is ByteArray)) {
				return false;
			}
			// メタ情報は取得済みか？
			if(metaCount == 0) {
				return false;
			}
			var counter:int = 0;
			for(var i:int;i < metaDataArray.length && i < metaCount;i ++) {
				if(metaDataArray[i] is ByteArray) {
					counter ++;
				}
			}
			return counter == metaCount;
		}
		/**
		 * flvパケットを設置する。
		 */
		public function setFlvData(index:Number, data:ByteArray):Array
		{
			if(nextPosition == -1) {
				nextPosition = index;
			}
			if(index == nextPosition) {
				nextPosition ++;
				var result:Array = new Array;
				if(skipDataModel == null) {
					result[0] = data;
				}
				else {
					Logger.info("flipがおきました。");
					skipDataModel.setData(index, data);
					result = skipDataModel.getData();
				}
				return result;
			}
			if(skipDataModel == null) {
				skipDataModel = new SkipDataModel(nextPosition);
			}
			skipDataModel.setData(index, data);
			return null;
		}

		public function getFlvHeader():ByteArray
		{
			return flvHeader;
		}
		public function getMetaCount():int
		{
			return metaCount;
		}
		public function getMetaData():Array
		{
			return metaDataArray;
		}
	}
}