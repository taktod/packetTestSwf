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
		private var _video:Video = null;
		public function get video():Video {return this._video;};
		/** 音声制御 */
		private var soundTransform:SoundTransform;
		/**
		 * コンストラクタ
		 */
		public function AppendPlayerView()
		{
			// ここでプレーヤーの下地をつくってしまう。
			status = STATUS_INIT;
			nc = new NetConnection;
			nc.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			_video = new Video(); // videoのサイズはあとで適宜変更しなければいけない。MetaDataによる？
		}
		public function connect():void {
			nc.connect(null);
		}
		/**
		 * NetStatusのイベント
		 */
		private function onNetStatus(event:NetStatusEvent):void
		{
			if(event.info.code == "NetConnection.Connect.Success") {
				Logger.info("connect(null)");
				// 接続できたら次のステップに進む。
				setup();
			}
		}
		private function setup():void {
			// 接続できたら次のステップに進む。
			ns = new NetStream(nc);
			ns.bufferTime = 2;
			ns.bufferTimeMax = 5;
			var customClient:Object = new Object();
			customClient.onMetaData = function(metadata:Object):void {
				for(var propName:String in metadata) {
					Logger.info(propName + ":" + metadata[propName]);
					if(propName == "width") {
						video.width = metadata[propName];
					}
					if(propName == "height") {
						video.height = metadata[propName];
					}
				}
			};
			ns.client = customClient;
			ns.addEventListener(NetStatusEvent.NET_STATUS, function(event:NetStatusEvent):void {
				Logger.info(event.info.code);
			});
			soundTransform = new SoundTransform();
			ns.soundTransform = soundTransform;
			
			_video.attachNetStream(ns);
			status = STATUS_READY;
		}
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
		public function appendBytes(data:ByteArray):void {
			if(status == STATUS_READY) {
				ns.appendBytes(data);
			}
		}
		public function end():void {
			if(status == STATUS_READY) {
				ns.addEventListener(NetStatusEvent.NET_STATUS, function(event:NetStatusEvent):void {
					if(event.info.code == "NetStream.Buffer.Empty") {
						// 終了イベント
						_video.clear();
						ns.close();
						ns = null;
					}
				});
			}
		}
		public function changeVolume(level:int):void {
			soundTransform.volume = level / 100;
			ns.soundTransform = soundTransform;
		}
	}
}