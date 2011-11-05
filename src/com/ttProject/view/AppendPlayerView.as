package com.ttProject.view
{
	import com.ttProject.library.Logger;
	
	import flash.events.NetStatusEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.NetStreamAppendBytesAction;
	import flash.utils.ByteArray;
	
	import mx.controls.TextArea;
	
	import spark.components.TextArea;

	/**
	 * appendBytesで動画を流すプレーヤー
	 */
	public class AppendPlayerView
	{
		/** ステータス定義 */
		public static var STATUS_INIT:int = 0; // 初期化前
		public static var STATUS_READY:int = 1; // 初期化完了
		/** 現在のステータス情報 */
		private var status:int;
		/** ネットコネクション */
		private var nc:NetConnection;
		/** ネットストリーム */
		private var ns:NetStream = null;
		/** 表示先ビデオオブジェクト */
		private var video:Video = null;
		/** 音声制御 */
		private var soundTransform:SoundTransform;
		/**
		 * コンストラクタ
		 */
		public function AppendPlayerView()
		{
			status = STATUS_INIT;
			nc = new NetConnection();
			nc.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			video = new Video(); // videoのサイズはあとで適宜変更しなければいけない。MetaDataによる？
			nc.connect(null);
		}
		/**
		 * NetStatusのイベント
		 */
		private function onNetStatus(event:NetStatusEvent):void
		{
			if(event.info.code == "NetConnection.Connect.Success") {
				// 接続できたら次のステップに進む。
				Logger.info("Connect.Success..", this);
				setup();
			}
		}
		private function setup():void {
			// 再生用のNetStreamを作成
			ns = new NetStream(nc);
			ns.bufferTime = 2;
			ns.bufferTimeMax = 5;
			// メタ情報の取得動作をさせる。
			var customClient:Object = new Object();
			customClient.onMetaData = function(metadata:Object):void {
				for(var propName:String in metadata) {
					Logger.info(propName + ":" + metadata[propName], this);
					if(propName == "width") {
						video.width = metadata[propName];
					}
					if(propName == "height") {
						video.height = metadata[propName];
					}
				}
			};
			ns.client = customClient;
			// イベント取得(取り立てて必要はないが動作をみたい。)
			ns.addEventListener(NetStatusEvent.NET_STATUS, function(event:NetStatusEvent):void {
				Logger.info(event.info.code);
				Logger.info(ns.bytesLoaded);
				Logger.info(ns.bytesTotal);
				Logger.info(ns.decodedFrames);
				Logger.info(ns.liveDelay);
			});
			// 音声操作
			soundTransform = new SoundTransform();
			ns.soundTransform = soundTransform;

			// ビデオを表示させる
			video.attachNetStream(ns);
			status = STATUS_READY;
		}
		/**
		 * 再生成
		 */
		public function resetup():void {
			if(status == STATUS_READY) {
				setup();
				ns.play(null);
				video.clear();
				video.width = 320;
				video.height = 240;
				ns.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
			}
		}
		/**
		 * byteデータ追記
		 */
		public function appendBytes(data:ByteArray):void {
			if(status == STATUS_READY) {
				ns.appendBytes(data);
			}
		}
		/**
		 * 完了イベント
		 */
		public function end():void {
			if(status == STATUS_READY) {
				ns.addEventListener(NetStatusEvent.NET_STATUS, function(event:NetStatusEvent):void {
					if(event.info.code == "NetStream.Buffer.Empty") {
						// データ送信の完了をうけたあとにBufferが空になったら、再生が終わったものとする。
						video.clear();
						ns.close();
						ns = null;
					}
				});
			}
		}
		/**
		 * ボリュームを変更する
		 */
		public function changeVolume(level:int):void {
			soundTransform.volume = level / 100;
			ns.soundTransform = soundTransform;
		}
		/**
		 * ビデオオブジェクト取得
		 */
		public function getVideo():Video
		{
			return this.video;
		}
	}
}