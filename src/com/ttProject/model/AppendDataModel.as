package com.ttProject.model
{
	import com.ttProject.library.Logger;
	import com.ttProject.view.AppendPlayerView;
	
	import flash.net.NetConnection;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	/**
	 * Red5サーバーから追記データを取得するモデル
	 */
	public class AppendDataModel
	{
		/** flvのヘッダ情報 */
		private var header:ByteArray = null;
		/** flvのメタ情報(H.264やAACの初期パケットも含む) */
		private var metaData:Array = null;
		/** 開始タイムスタンプ時刻 */
		private var videoStartPosition:int = -1;
		private var player:AppendPlayerView;
		/**
		 * コンストラクタ
		 */
		public function AppendDataModel(player:AppendPlayerView)
		{
			this.player = player;
		}
		/**
		 * flvヘッダ情報をうけとる。
		 */
		public function flvHeader(data:*):void
		{
			Logger.info("getHeaderMessage");
			header = makeByteArray(data);
			metaData = new Array;
			player.resetup();
			player.appendBytes(header);
		}
		/**
		 * flvメタデータをうけとる。
		 */
		public function flvMetaData(data:*):void
		{
			Logger.info("getMetaData");
			var ba:ByteArray = makeByteArray(data);
			metaData.push(ba);
			player.appendBytes(ba);
		}
		/**
		 * flvデータを受け取る
		 */
		public function flvData(data:*):void
		{
			player.appendBytes(makeByteArrayWithTimestampInjection(data));
		}
		/**
		 * flvデータの送信完了を取得する。
		 */
		public function flvEnd():void {
			player.end();
		}
		/**
		 * 送られてきたデータをByteArrayに変換する。
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
		/**
		 * タイムスタンプをずらしたflv命令を再構成するプログラム
		 */
		private function makeByteArrayWithTimestampInjection(data:Array):ByteArray
		{
			var ba:ByteArray = makeByteArray(data);
			try {
				ba.position = 0;
				var dataType:int = ba.readByte();
				ba.position = 4;
				// タイムスタンプを取得する。
				var timestamp:int = ((ba.readByte() + 0x0100) & 0xFF) * 0x010000
					+ ((ba.readByte() + 0x0100) & 0xFF) * 0x0100
					+ ((ba.readByte() + 0x0100) & 0xFF) * 0x01
					+ ((ba.readByte() + 0x0100) & 0xFF) * 0x01000000;
				var newTimestamp:int = 0;
				switch(dataType) {
					case 8: // audio情報
						newTimestamp = timestamp - videoStartPosition;
						break;
					case 9: // video情報
						if(videoStartPosition == -1) {
							videoStartPosition = timestamp;
						}
						newTimestamp = timestamp - videoStartPosition;
						break;
					case 18: // メタ情報
						ba.position = 0;
						return ba;
					default: // その他
						return ba;
				}
				newTimestamp = newTimestamp / 1.2;
				ba.position = 4;
				ba.writeByte((newTimestamp / 0x010000) & 0xFF);
				ba.writeByte((newTimestamp / 0x0100) & 0xFF);
				ba.writeByte((newTimestamp / 0x01) & 0xFF);
				ba.writeByte((newTimestamp / 0x01000000) & 0xFF);
				ba.position = 0;
			}
			catch(e:Error) {
				;
			}
			return ba;
		}
	}
}