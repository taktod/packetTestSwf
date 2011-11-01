package com.ttProject.controller
{
	import com.ttProject.library.Logger;
	import com.ttProject.model.AppendDataModel;
	import com.ttProject.model.FlvDataModel;
	
	import flash.events.NetStatusEvent;
	import flash.net.GroupSpecifier;
	import flash.net.NetConnection;
	import flash.net.NetGroup;
	import flash.net.NetGroupReplicationStrategy;
	import flash.utils.ByteArray;

	public class RtmfpController
	{
		/*
		 * まずやっておかないとだめなこと。
		 * netGroupのObject共有で前からの指定にしている状態で、前のオブジェクトをだれももっていない場合、そこを無視してデータを取得するのか？
		 * 1:状態フラグ、視聴前のユーザーはこのフラグを問い合わせる。
		 *  視聴中のユーザーはこのフラグをつねにhasObjectにしておき、要求がきたら自分の再生ポインタを応答する。
		 *  配信がおわった番組に関してはこのフラグの問い合わせ状態にしておく。
		 * 2:FLVヘッダ情報
		 * 3:メタ情報数
		 *  2,3の情報は状態フラグを取得する前に実行する。
		 * 4:メタ情報
		 * 5:メタ情報
		 *  以下メタ情報は3のメタ情報数だけおくられてくる。
		 * 7:再生キュー7から始まる場合はここが再生キューの１番になる。
		 * 8:以下フレームデータ
		 * 
		 * フレームデータは自分の再生位置からある程度上をwaitObjectで要求
		 * ある程度下をHasObjectで共有
		 * あまりに古いデータは共有せず。とする。
		 */
		private var netConn:NetConnection;
		private var netGroup:NetGroup;
		private var rtmfpPath:String;
		private var groupName:String;
		private var appendDataModel:AppendDataModel;
		private var flvDataModel:FlvDataModel;
		public function RtmfpController(rtmfpPath:String, groupName:String,
					appendDataModel:AppendDataModel, flvDataModel:FlvDataModel)
		{
			this.rtmfpPath = rtmfpPath;
			this.groupName = groupName;
			this.appendDataModel = appendDataModel;
			this.flvDataModel = flvDataModel;
			// rtmfpの接続を構築する。
			netConn = new NetConnection();
			netConn.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusEvent);
		}
		/**
		 * 接続を実行する。
		 */
		public function connect():void
		{
			netConn.connect(rtmfpPath);
		}
		public function close():void
		{
			netGroup.close();
			netConn.close();
		}
		public function sendData():void
		{
			
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
				onGroupConnected();
				break;
			case "NetGroup.Neighbor.Connect":
				Logger.info(event.target); // こいつはobjectNetGroupになる。
				break;
			case "NetGroup.Replication.Fetch.SendNotify": // e.info.index(データ受け取りしたいという要求をおくった場合？)
				onReplicationSendNotify(event.info.index);
				break;
			case "NetGroup.Replication.Fetch.Failed": // e.info.index(データ受け取りに失敗した場合)
				onReplicationFailed(event.info.index);
				break;
			case "NetGroup.Replication.Fetch.Result": // e.info.index, e.info.object(データ受け取りに成功した場合)
				onReplicationResult(event.info.index, event.info.object);
				break;
			case "NetGroup.Replication.Request": // e.info.index, e.info.requestID(データを要求された場合)
				onReplicationRequest(event.info.index, event.info.requestID);
				break;
			default:
				break;
			}
		}
		/**
		 * 接続時
		 */
		private function onNetConnected():void {
			Logger.info("onNetConnected....");
			// ネットグループに参加
			createNetGroup();
		}
		/**
		 * グループに参加時
		 */
		private function onGroupConnected():void {
			Logger.info("group Connected...");
			// データコピーの方法を昇順に設定
			netGroup.replicationStrategy = NetGroupReplicationStrategy.LOWEST_FIRST;
			
			flvDataModel.addNetGroup(netGroup); // netGroupを登録しておく。

			Logger.info("add Want Objects");
			netGroup.addWantObjects(1,2);
		}
		/**
		 * データを受け取る要求をだしたとき処理？
		 */
		private function onReplicationSendNotify(index:Number):void {
			
		}
		/**
		 * データ受信失敗時
		 */
		private function onReplicationFailed(index:Number):void {
			
		}
		private var counter:int = 0;
		private var startTime:Number;
		/**
		 * データ受信成功時
		 */
		private function onReplicationResult(index:Number, data:Object):void {
			// ここのあとでなんかするという処理がある。
			switch(index) {
			case 0:
				// 再生カウントを受け取った場合
				flvDataModel.setPlayPosition(data as Number);
				return;
			case 1:
				// flvヘッダー
				flvDataModel.setFlvHeader(data as ByteArray);
				appendDataModel.flvHeader(data as ByteArray);
				return;
			case 2:
				// メタデータの数
				flvDataModel.setMetaCount(data as int);
				return;
			}
			// メタデータ
			if(index >= 3 && index < 3 + flvDataModel.getMetaCount()) {
				flvDataModel.setMetaData(index, data as ByteArray);
				appendDataModel.flvMetaData(data as ByteArray);
				if(flvDataModel.isReadyToPlay()) {
					flvDataModel.wantPlayPosition();
				}
				return;
			}
//			counter ++;
//			if(counter == 10) {
//				startTime = new Date().time;
//			}
//			else if(counter == 1010) {
//				Logger.info("bench:" + (1000 / (new Date().time - startTime)));
//			}
//			Logger.info((data as ByteArray).length);
			// 0.057920648711265565
			// 0.05942829975634397
			// その他のデータはすべてflvData
			flvDataModel.setFlvData(index, data as ByteArray);
			appendDataModel.flvData(data as ByteArray);
		}
		/**
		 * データ要求をうけとった時
		 */
		private function onReplicationRequest(index:Number, requestId:int):void {
			// リクエストをうけとったらリクエストインデックスのデータを応答する。
			netGroup.writeRequestedObject(
				requestId, 
				flvDataModel.getRequestedData(index));
		}
		/**
		 * ネットグループ作成
		 */
		private function createNetGroup():void
		{
			var groupSpec:GroupSpecifier = new GroupSpecifier(groupName);
			groupSpec.serverChannelEnabled = true;
			groupSpec.objectReplicationEnabled = true;
			
			netGroup = new NetGroup(netConn, groupSpec.groupspecWithAuthorizations());
			netGroup.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusEvent);
		}
	}
}