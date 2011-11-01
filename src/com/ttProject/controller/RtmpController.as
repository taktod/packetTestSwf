package com.ttProject.controller
{
	import com.ttProject.library.Logger;
	import com.ttProject.model.AppendDataModel;
	import com.ttProject.model.FlvDataModel;
	
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
		private var appendDataModel:AppendDataModel;
		private var flvDataModel:FlvDataModel;
		/**
		 * コンストラクタ
		 */
		public function RtmpController(appendDataModel:AppendDataModel, flvDataModel:FlvDataModel)
		{
			super();
			this.appendDataModel = appendDataModel;
			this.flvDataModel = flvDataModel;
		}
		/**
		 * header情報取得
		 */
		public function flvHeader(data:*):void
		{
			var ba:ByteArray = makeByteArray(data);
			flvDataModel.setFlvHeader(ba);
			appendDataModel.flvHeader(ba);
		}
		/**
		 * メタデータの数
		 */
		public function flvMetaNum(data:*):void
		{
			Logger.info("metaDataNum:" + data);
			flvDataModel.setMetaCount(data);
		}
		/**
		 * meta情報取得
		 */
		public function flvMetaData(num:*, data:*):void
		{
			var ba:ByteArray = makeByteArray(data);
			flvDataModel.setMetaData(num + 3, ba); // フレーム位置を絶対位置に変更する必要があるので3たした。
			appendDataModel.flvMetaData(ba);
		}
		private var counter:int = 0;
		private var startTime:Number;
		/**
		 * flvデータ取得
		 */
		public function flvData(num:*, data:*):void {
//			counter ++;
//			if(counter == 10) {
//				startTime = new Date().time;
//			}
//			else if(counter == 1010) {
//				Logger.info("bench:" + (1000 / (new Date().time - startTime)));
//			}
			// 0.0757346258709482
			// 0.07166403898523721
			var ba:ByteArray = makeByteArray(data);
			flvDataModel.setFlvData(num + 3 + flvDataModel.getMetaCount(), ba);
			if(flvDataModel.isReadyToPlay()) { // Metaデータの送信がおわるまでビデオデータを送信しない。
				appendDataModel.flvData(ba);
			}
		}
		/**
		 * flv完了通知
		 */
		public function flvEnd():void {
			appendDataModel.flvEnd();
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