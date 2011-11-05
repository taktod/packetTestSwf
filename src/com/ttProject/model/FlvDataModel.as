package com.ttProject.model
{
	import com.ttProject.library.Logger;
	
	import flash.net.NetGroup;
	import flash.utils.ByteArray;
	
	/**
	 * rtmfp上の動画パケットの管理用モデル
	 */
	public class FlvDataModel
	{
		// クラスの中にうめこんでもっていると、複数のnetGroupにまたがっているときに動作がうまくいかないのでなんとかしておく。
		private var flvHeader:ByteArray; // flvHeader情報
		private var metaCount:int; // メタ情報数
		private var metaDataArray:Array; // メタデータ情報
		private var dataArray:Array; // 保持データ

		private var dataStartPos:Number; // データ保持インデックスの頭
		private var loadingPos:Number; // ローディング中のデータ位置
		/**
		 * コンストラクタ
		 */
		public function FlvDataModel()
		{
			clear();
		}
		/**
		 * すべてのデータを消去する。(netGroupは破棄しない。)
		 */
		public function clear():void
		{
			flvHeader = null;
			metaCount = 0;
			metaDataArray = new Array();
			dataArray = new Array();
			loadingPos = 0;
			dataStartPos = 0;
		}
		/**
		 * 保持flvデータの位置を変更する。
		 */
		public function setTaskPos(position:Number):void
		{
			// 新ポジション以前のところにあることになるデータを削除しなくてはならない。
			var i:int;
			/**
			 * 10 11 12 13 14 15 16
			 * 旧          新
			 * だとすると10から13までの配列データをshiftしないといけない。
			 * 
			 * 10 11 12 13 14 15 16
			 *    新           旧
			 * だとすると11から14まで、配列をいれる部分をつくらないといけない。
			 */
			if(position < dataStartPos) {
				// 現行よりうしろに巻き戻される場合
				dataArray.reverse();
				// 個数分先頭に追加
				for(i = 0;i < dataStartPos - position;i ++) {
					dataArray.push(null);
				}
				dataArray.reverse();
			}
			else {
				// 現行より後に移る場合
				dataArray.reverse();
				for(i = 0;i < position - dataStartPos;i ++) {
					dataArray.pop();
				}
				dataArray.reverse();
			}
			dataStartPos = position;
		}
		/**
		 * flvHeaderを設置する。
		 */
		public function setFlvHeader(data:ByteArray):void
		{
			flvHeader = new ByteArray();
			flvHeader.writeBytes(data);
		}
		/**
		 * メタデータ数を設置する。
		 */
		public function setMetaCount(count:int):void
		{
			Logger.info("getMetaCount:" + count);
			metaCount = count;
		}
		/**
		 * メタデータを設置する。
		 */
		public function setMetaData(index:Number, data:ByteArray):void
		{
			Logger.info("getMetaData:" + index);
			if(metaDataArray.length == metaCount) {
				// すでにメタデータダウンロード済みなので処理しない。
				return;
			}
			var ba:ByteArray = new ByteArray();
			ba.writeBytes(data);
			metaDataArray[index] = ba;
		}
		public function isReadyToPlay():Boolean {
			// flvヘッダ情報は取得済みか？
			if(!(flvHeader is ByteArray)) {
				return false;
			}
			// メタ情報は取得済みか？
			if(metaCount == 0) {
				return false;
			}
			var counter:int = 0;
			for(var i:int;i < metaDataArray.length && i < metaCount;i ++) {
				if(metaDataArray[i] is ByteArray) {
					counter ++;
				}
			}
			return counter == metaCount;
		}
		public function setPlayPosition(pos:Number):void {
			// 開始場所決定
			dataStartPos = pos;
			loadingPos = pos;
		}
		/**
		 * flvパケットを設置する。
		 */
		public function setFlvData(index:Number, data:ByteArray):void
		{
			if(index < dataStartPos) {
				return;
			}
			var ba:ByteArray = new ByteArray();
			ba.writeBytes(data);
			dataArray[index - dataStartPos] = ba;
			// 再生ポイントを更新する。(本当は連番できているか確認する必要があるが、とりあえずはぶいておく。)
			if(loadingPos < index) {
				loadingPos = index;
			}
		}
		
		public function getFlvHeader():ByteArray
		{
			return flvHeader;
		}
		public function getMetaCount():int
		{
			return metaCount;
		}
		public function getMetaData():Array
		{
			return metaDataArray;
		}
		public function getFlvData(index:Number):ByteArray
		{
			if(index < dataStartPos) {
				return null;
			}
			return dataArray[index - dataStartPos] as ByteArray;
		}
	}
}