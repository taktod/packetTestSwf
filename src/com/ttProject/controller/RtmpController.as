package com.ttProject.controller
{
	import com.ttProject.model.AppendDataModel;
	
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	
	/**
	 * Rtmpからデータを受け取る場合
	 */
	public class RtmpController extends NetConnection
	{
		/** データ操作モデル */
		private var appendDataModel:AppendDataModel;
		/**
		 * コンストラクタ
		 */
		public function RtmpController(appendDataModel:AppendDataModel)
		{
			super();
			this.appendDataModel = appendDataModel;
		}
		/**
		 * header情報取得
		 */
		public function flvHeader(data:*):void
		{
			appendDataModel.flvHeader(data);
		}
		/**
		 * meta情報取得
		 */
		public function flvMetaData(data:*):void
		{
			appendDataModel.flvMetaData(data);
		}
		/**
		 * flvデータ取得
		 */
		public function flvData(data:*):void {
			appendDataModel.flvData(data);
		}
		/**
		 * flv完了通知
		 */
		public function flvEnd():void {
			appendDataModel.flvEnd();
		}
	}
}