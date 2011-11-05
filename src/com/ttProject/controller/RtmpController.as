package com.ttProject.controller
{
	import com.ttProject.library.Logger;
	import com.ttProject.model.AppendDataModel;
	import com.ttProject.model.FlvDataModel;
	import com.ttProject.model.FlvModel;
	
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	/**
	 * Rtmpからデータを受け取る場合
	 */
	public class RtmpController extends NetConnection
	{
		/** データ操作モデル */
		private var flvModel:FlvModel = null;
		/**
		 * コンストラクタ
		 */
		public function RtmpController(flvModel:FlvModel)
		{
			super();
			this.flvModel = flvModel;
		}
		/**
		 * header情報取得
		 */
		public function flvHeader(data:*):void
		{
			var ba:ByteArray = makeByteArray(data);
			flvModel.flvHeader(ba);
		}
		/**
		 * メタデータの数
		 */
		public function flvMetaNum(data:*):void
		{
			Logger.info("metaDataNum:" + data);
			flvModel.flvMetaNum(data);
		}
		/**
		 * meta情報取得
		 */
		public function flvMetaData(num:*, data:*):void
		{
			var ba:ByteArray = makeByteArray(data);
			flvModel.flvMetaData(num, ba);
		}
		private var counter:int = 0;
		private var startTime:Number;
		/**
		 * flvデータ取得
		 */
		public function flvData(num:*, data:*):void {
			var ba:ByteArray = makeByteArray(data);
			flvModel.flvData(num, ba);
		}
		/**
		 * flv完了通知
		 */
		public function flvEnd():void {
			flvModel.flvEnd();
		}
		/**
		 * 受け取った数値配列オブジェクトをByteArrayに変換する
		 */
		private function makeByteArray(data:Array):ByteArray
		{
			var ba:ByteArray = new ByteArray;
			ba.endian = Endian.BIG_ENDIAN;
			for(var i:int = 0;i < data.length;i ++) {
				ba.writeByte(data[i]);
			}
			ba.position = 0;
			return ba;
		}
	}
}