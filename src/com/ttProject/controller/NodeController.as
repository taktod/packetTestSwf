package com.ttProject.controller
{
	import com.ttProject.library.Logger;
	import com.ttProject.model.AppendDataModel;
	import com.ttProject.model.FlvDataModel;
	import com.ttProject.model.FlvModel;
	
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	/**
	 * 特定のノードとのやり取りを実施するモデル
	 */
	public class NodeController
	{
		private var nodeID:String; // 接続相手のPeerID
		private var sendStream:NetStream; // データ送信用
		private var recvStream:NetStream; // データ受信用

		private var flvModel:FlvModel; // データ管理用
		/**
		 * コンストラクタ
		 * 先にplayを開始しておいても、接続先がpublishをはじめたらイベントを拾うことができる。
		 * 先にpublishを開始しておきても、接続先がplayをはじめたらイベントを拾うことができる。
		 * よって通知がきたらつなげりゃいい。
		 * 
		 * なおとりあえず、rtmpと同じくnodeにむかってデータを順次なげる方式でやってみる。
		 */
		public function NodeController(
				nodeID:String,
				netConn:NetConnection,
				flvModel:FlvModel)　{
			// ノードIDを保持しておく。
			this.nodeID = nodeID;
			// appendDataModelとflvDataModelを保持しておく。
			this.flvModel = flvModel;
			// 送信用接続作成
			sendStream = new NetStream(netConn, NetStream.DIRECT_CONNECTIONS);
			sendStream.publish(nodeID);

			// 受信用接続作成
			recvStream = new NetStream(netConn, nodeID);
			recvStream.client = new Object;
			recvStream.client.flvHeader = flvHeader;
			recvStream.client.flvMetaNum = flvMetaNum;
			recvStream.client.flvMetaData = flvMetaData;
			recvStream.client.flvData = flvData;
			recvStream.client.flvEnd = flvEnd;
			recvStream.client.flvQueue = flvQueue;
			recvStream.play(netConn.nearID);
		}
		public function close():void
		{
			sendStream.close();
			recvStream.close();
		}
		/**
		 * flvHeaderを受信する。
		 */
		private function flvHeader(data:*):void
		{
			if(data is ByteArray) {
				flvModel.flvHeader(data);
			}
		}
		/**
		 * flvMeta数を受信する。
		 */
		private function flvMetaNum(data:*):void
		{
			if(data is int) {
				flvModel.flvMetaNum(data);
			}
		}
		/**
		 * flvMetaデータを受信する。
		 */
		private function flvMetaData(num:*, data:*):void
		{
			if(data is ByteArray) {
				flvModel.flvMetaData(num, data);
			}
		}
		/**
		 * flvDataを受信する。
		 */
		private function flvData(num:*, data:*):void
		{
			if(data is ByteArray) {
				flvModel.flvData(num, data);
			}
		}
		/**
		 * flv終了フラグを受信する。
		 */
		private function flvEnd():void
		{
			flvModel.flvEnd();
		}
		/**
		 * 要求命令を受信する。
		 */
		private function flvQueue(order:String):void
		{
			// 特定の指定を受け取った場合に応答を返す・・・
			switch(order) {
				case "flvHeader": // flvHeaderを要求する
					sendFlvHeader(flvModel.getFlvDataModel().getFlvHeader());
					break;
				case "flvMetaData": // flvMetaDataを要求する
					var num:int = flvModel.getFlvDataModel().getMetaCount();
					sendFlvMetaNum(num);
					for(var i:int = 0;i < num;i ++) {
						sendFlvMetaData(i, flvModel.getFlvDataModel().getMetaData()[i]);
					}
					break;
				case "flvData": // flvDataを要求する
					// このデータをうけとったら以降データを取得するたびに、データの送信が行われるようになる。
					flvModel.addNode(this);
					break;
				case "flvEnd": // データ要求を破棄する
					// このデータをうけとったら、データの送信が停止する。
					flvModel.removeNode(this);
					break;
				case "flvCheck": // 自分が放送を送信できるか要求
					// 自分が放送を受信している状況か応答する。
					if(flvModel.getFlvDataModel().isReadyToPlay()) {
						// ついでに自分のところに複数接続がきている場合はNGにしてやりたい。
						sendFlvQueue("flvOK");
					}
					else {
						sendFlvQueue("flvNG");
					}
					break;
				case "flvOK": // flvCheckの応答で問題ない場合
					if(listener != null) {
						listener(this); // 設置されたリスナーに応答を返す。
					}
					break;
				default: // その他不明な命令
					break;
			}
		}
		public function sendFlvHeader(data:*):void
		{
			sendStream.send("flvHeader", data);
		}
		public function sendFlvMetaNum(num:*):void
		{
			sendStream.send("flvMetaNum", num);
		}
		public function sendFlvMetaData(num:*, data:*):void
		{
			sendStream.send("flvMetaData", num, data);
		}
		public function sendFlvData(num:*, data:*):void
		{
			sendStream.send("flvData", num, data);
		}
		public function sendFlvEnd():void
		{
			sendStream.send("flvEnd");
		}
		public function sendFlvQueue(order:String):void
		{
			sendStream.send("flvQueue", order);
		}
		private var listener:Function = null;
		public function sendFlvConnectQueue(listener:Function):void
		{
			this.listener = listener;
			sendFlvQueue("flvCheck");
		}
		public function getNodeID():String
		{
			return nodeID;
		}
	}
}