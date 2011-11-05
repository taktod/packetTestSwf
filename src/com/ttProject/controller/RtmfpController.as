package com.ttProject.controller
{
	import com.ttProject.library.Logger;
	import com.ttProject.model.AppendDataModel;
	import com.ttProject.model.FlvDataModel;
	import com.ttProject.model.FlvModel;
	
	import flash.events.NetStatusEvent;
	import flash.events.StatusEvent;
	import flash.net.GroupSpecifier;
	import flash.net.NetConnection;
	import flash.net.NetGroup;
	import flash.net.NetGroupReplicationStrategy;
	import flash.net.NetGroupSendMode;
	import flash.net.NetStream;
	import flash.utils.ByteArray;

	public class RtmfpController
	{
		/**
		 * まずローカルPCの内部でNetStreamで接続できるか知りたい
		 * →できる。
		 * とりあえずモデルをつくって動作が可能なのかやってみないとなにもわからないので、やってみる。
		 * →できた。
		 */
		private var netConn:NetConnection;
		private var netGroup:NetGroup;
		private var flvModel:FlvModel;
		private var nodes:Object = new Object;

		private var groupName:String;
		/**
		 * コンストラクタ
		 */
		public function RtmfpController(flvModel:FlvModel)
		{
			this.flvModel = flvModel;
			// rtmfpの接続を構築する。
			netConn = new NetConnection();
			netConn.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusEvent);
		}
		/**
		 * 接続を実行する。
		 */
		public function connect(rtmfpPath:String, groupName:String):void
		{
			this.groupName = groupName;
			netConn.connect(rtmfpPath);
		}
		public function close():void
		{
			netGroup.close();
			netConn.close();
		}
		/**
		 * イベント処理
		 */
		private function onNetStatusEvent(event:NetStatusEvent):void
		{
			switch(event.info.code) {
			case "NetConnection.Connect.Success":
				onNetConnected();
				break;
			case "NetGroup.Connect.Success":
				break;
			case "NetGroup.Neighbor.Connect":
				onNeighborConnected(event.info.peerID);
				break;
			case "NetGroup.SendTo.Notify":
				Logger.info(event.info.message);
				break;
			default:
				break;
			}
		}
		public function onNeighborConnected(peerID:String):void {
			nodes[peerID] = new NodeController(peerID, netConn, flvModel);
		}
		private var connected:Boolean;
		public function test():void {
			Logger.info("try to send test now...");
			connected = false;
			// 全Nodeに対してデータを送信する。
			for(var peerID:String in nodes)
			{
				if(nodes[peerID] != null) {
					(nodes[peerID] as NodeController).sendFlvConnectQueue(function(node:NodeController):void{
						if(!connected) {
							connected = true;
							Logger.info("connectedID:" + node.getNodeID());
							node.sendFlvQueue("flvHeader");
							node.sendFlvQueue("flvMetaData");
							node.sendFlvQueue("flvData");
						}
					});
				}
			}
		}
		/**
		 * 接続時
		 */
		private function onNetConnected():void {
			Logger.info("onNetConnected....");
			Logger.info("myID:" + netConn.nearID);
			// ネットグループに参加
			createNetGroup();
		}
		/**
		 * ネットグループに接続する。
		 */
		private function createNetGroup():void {
			var groupSpec:GroupSpecifier = new GroupSpecifier(groupName);
			groupSpec.serverChannelEnabled = true;
			groupSpec.ipMulticastMemberUpdatesEnabled = true;
			groupSpec.addIPMulticastAddress("224.0.0.255:30000");
			groupSpec.routingEnabled = true;
			groupSpec.postingEnabled = true;
			
			netGroup = new NetGroup(netConn, groupSpec.groupspecWithAuthorizations());
			netGroup.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusEvent);
		}
	}
}