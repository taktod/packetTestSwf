package com.ttProject.model
{
	import com.ttProject.controller.NodeController;
	import com.ttProject.view.AppendPlayerView;
	
	import flash.utils.ByteArray;

	/**
	 * flvデータを総合管理する。
	 */
	public class FlvModel
	{
		private var flvDataModel:FlvDataModel; // flvデータを管理する
		private var appendDataModel:AppendDataModel; // プレーヤーの情報を管理する
		private var nodes:Object; // パケットデータを送信する先リスト
		/**
		 * コンストラクタ
		 */
		public function FlvModel(player:AppendPlayerView)
		{
			// 内部管理用モデルの構築
			this.flvDataModel = new FlvDataModel();
			this.appendDataModel = new AppendDataModel(player);
			// nodeデータを保持する配列
			nodes = new Object;
		}
		/**
		 * flvHeaderを取得したときの動作
		 */
		public function flvHeader(data:ByteArray):void
		{
			flvDataModel.setFlvHeader(data);
			appendDataModel.flvHeader(data);
			for(var name:String in nodes) {
				var node:NodeController = nodes[name] as NodeController;
				if(node != null) {
					node.sendFlvHeader(data);
				}
			}
		}
		/**
		 * メタデータ数を受け取ったときの動作
		 */
		public function flvMetaNum(num:int):void
		{
			flvDataModel.setMetaCount(num);
			for(var name:String in nodes) {
				var node:NodeController = nodes[name] as NodeController;
				if(node != null) {
					node.sendFlvMetaNum(num);
				}
			}
		}
		/**
		 * Metaデータを受け取ったときの動作
		 */
		public function flvMetaData(num:Number, data:ByteArray):void
		{
			flvDataModel.setMetaData(num, data);
			appendDataModel.flvMetaData(data);
			for(var name:String in nodes) {
				var node:NodeController = nodes[name] as NodeController;
				if(node != null) {
					node.sendFlvMetaData(num, data);
				}
			}
		}
		/**
		 * flvDataを受け取ったときの動作
		 */
		public function flvData(num:Number, data:ByteArray):void
		{
//			flvDataModel.setFlvData(num, data); // いまのところためる必要はない。
			for(var name:String in nodes) {
				var node:NodeController = nodes[name] as NodeController;
				if(node != null) {
					node.sendFlvData(num, data);
				}
			}
			if(flvDataModel.isReadyToPlay()) {
				appendDataModel.flvData(data);
			}
		}
		/**
		 * flvの再生完了フラグ取得
		 */
		public function flvEnd():void
		{
			flvDataModel.clear();
			for(var name:String in nodes) {
				var node:NodeController = nodes[name] as NodeController;
				if(node != null) {
					node.sendFlvEnd();
				}
			}
			appendDataModel.flvEnd();
		}
		/**
		 * 処理ノード追加
		 */
		public function addNode(nodeController:NodeController):void
		{
			nodes[nodeController.getNodeID()] = nodeController;
		}
		/**
		 * 処理ノードを削除
		 */
		public function removeNode(nodeController:NodeController):void
		{
			delete nodes[nodeController.getNodeID()];
		}
		/**
		 * flvDataModelを応答
		 */
		public function getFlvDataModel():FlvDataModel
		{
			return flvDataModel;
		}
	}
}