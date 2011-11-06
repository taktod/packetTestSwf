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
		public function test(data:ByteArray):Array
		{
			var result:Array = new Array;
			result[0] = data;
			return result;
		}
		/**
		 * flvDataを受け取ったときの動作
		 */
		public function flvData(num:Number, data:ByteArray):void
		{
			// データをうけとったときに順番がずれた場合に対処する必要あり。
			for(var name:String in nodes) {
				var node:NodeController = nodes[name] as NodeController;
				if(node != null) {
					node.sendFlvData(num, data);
				}
			}
			if(flvDataModel.isReadyToPlay()) {
				// 受け取ったデータをいったん順番に合わせる。(ためしたことはない。)
				var dataArray:Array = flvDataModel.setFlvData(num, data);
				if(dataArray != null) {
					for(var i:int = 0;i < dataArray.length;i ++) {
						appendDataModel.flvData(dataArray[0]);
					}
				}
			}
		}
		/**
		 * flvの再生完了フラグ取得
		 */
		public function flvEnd():void
		{
			// モデルをクリアすることで、ほかのnodeから要求がきても動作しなくなる。
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
		 * 準備がおわっているか確認
		 */
		public function isReadyToPlay():Boolean
		{
			if(flvDataModel == null) {
				return false;
			}
			return flvDataModel.isReadyToPlay();
		}
		public function getFlvHeader():ByteArray
		{
			if(flvDataModel == null) {
				return null;
			}
			return flvDataModel.getFlvHeader();
		}
		public function getFlvMetaNum():int
		{
			if(flvDataModel == null) {
				return 0;
			}
			return flvDataModel.getMetaCount();
		}
		public function getFlvMetaData(num:int):ByteArray
		{
			if(flvDataModel == null) {
				return null;
			}
			return flvDataModel.getMetaData()[num];
		}
		/**
		 * flvDataModelを応答
		 */
//		public function getFlvDataModel():FlvDataModel
//		{
//			return flvDataModel;
//		}
	}
}