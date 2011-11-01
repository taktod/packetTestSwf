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
		/** 開始タイムスタンプ時刻 */
		private var startPosition:int = -1; // 追記データのタイムスタンプ操作をするためのデータ
		private var player:AppendPlayerView; // 再生プレーヤービュー
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
		public function flvHeader(data:ByteArray):void
		{
			Logger.info("getHeaderMessage");
			player.resetup();
			player.appendBytes(data);
			startPosition = -1;
		}
		/**
		 * flvメタデータをうけとる。
		 */
		public function flvMetaData(data:ByteArray):void
		{
			Logger.info("getMetaData");
			player.appendBytes(data);
		}
		/**
		 * flvデータを受け取る
		 */
		public function flvData(data:ByteArray):void
		{
			var ba:ByteArray = timestampInjection(data);
			if(ba != null) {
				player.appendBytes(ba);
			}
		}
		/**
		 * flvデータの送信完了を取得する。
		 */
		public function flvEnd():void {
			player.end();
		}
		/**
		 * タイムスタンプをずらしたflv命令を再構成するプログラム
		 */
		private function timestampInjection(data:ByteArray):ByteArray
		{
			var ba:ByteArray = new ByteArray;
			ba.writeBytes(data);
			try {
				ba.position = 0;
				var dataType:int = ba.readByte();
				if(startPosition == -1) {
					switch(dataType) {
						case 8:
							return null;
						case 18:
							ba.position = 0;
							return ba;
						case 9:
							ba.position = 11;
							if(ba.readByte() & 0x10 == 0x00) {
								return null;
							}
							break;
					}
				}
				ba.position = 4;
				// タイムスタンプを取得する。
				var timestamp:int = ((ba.readByte() + 0x0100) & 0xFF) * 0x010000
					+ ((ba.readByte() + 0x0100) & 0xFF) * 0x0100
					+ ((ba.readByte() + 0x0100) & 0xFF) * 0x01
					+ ((ba.readByte() + 0x0100) & 0xFF) * 0x01000000;
				var newTimestamp:int = 0;
				switch(dataType) {
					case 8: // audio情報
						newTimestamp = timestamp - startPosition;
						break;
					case 9: // video情報
						if(startPosition == -1) {
							startPosition = timestamp;
						}
						newTimestamp = timestamp - startPosition;
						break;
					case 18: // メタ情報
						ba.position = 0;
						return ba;
					default: // その他
						return ba;
				}
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