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
		private var netGroupArray:Array; // 所属NetGroup
		private var flvHeader:ByteArray; // flvHeader情報
		private var metaCount:int; // メタ情報数
		private var metaDataArray:Array; // メタデータ情報
		private var dataArray:Array; // 保持データ

		private var dataStartPos:Number; // データ保持インデックスの頭
		private var loadingPos:Number; // ローディング中のデータ位置
		private var waitingPos:Number; // データ未要求のデータ位置
		/**
		 * コンストラクタ
		 */
		public function FlvDataModel()
		{
			netGroupArray = new Array();
			clear();
		}
		/**
		 * やらないといけないステータスは
		 * ヘッダ情報とメタ数の取得
		 * メタ情報のダウンロード
		 * パケットデータの受信
		 * 
		 * データはすべて即共有可能にする必要がある。
		 * パケットデータはある程度たまったら共有からはずしてもよい。(メモリーエラー対策)
		 * 
		 * まずは古いデータを消すことを考えずにDownload共有について考慮しておく。
		 */
		public function getRequestedData(index:Number):* {
			if(index == 0) {
				Logger.info(loadingPos); // ここがNanになる。
				return loadingPos; // 現在の再生ポス応答
			}
			else if(index == 1) {
				return flvHeader; // flvHeader応答
			}
			else if(index == 2) {
				return metaCount; // メタデータの数応答
			}
			else if(index >= 3 && index < 3 + metaDataArray.length) {
				return metaDataArray[index - 3]; // メタデータ応答
			}
			else if(index >= dataStartPos && index < loadingPos) {
				return dataArray[index - dataStartPos]; // フレームデータ応答
			}
			return null; // nullの場合は存在しないので、このデータの受信を拒否する。
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
			waitingPos = 0;
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
				// netGroupにデータ要求を書き込まないとだめ。
				// 巻き戻した分は、保持リストにあるわけないので、WantObjectにしておく。
				addWantObjects(position, dataStartPos - 1);
			}
			else {
				// 現行より後に移る場合
				dataArray.reverse();
				for(i = 0;i < position - dataStartPos;i ++) {
					dataArray.pop();
				}
				dataArray.reverse();
				// netGroupにデータ要求を書き込まないとだめ。
				// すすめた分は保持リストから取り去る
				removeHaveObjects(dataStartPos, position - 1);
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
			// netGroupの要求queueから1番をはずす。
			removeWantObjects(1, 1);
			// もってるよオブジェクトに追加
			addHaveObjects(1, 1);
		}
		/**
		 * メタデータ数を設置する。
		 */
		public function setMetaCount(count:int):void
		{
			Logger.info("getMetaCount:" + count);
			metaCount = count;
			// データ保持のはじめの位置を取得する。
			// netGroupの要求queueから1番をはずす。
			removeWantObjects(2, 2);
			// もってるよオブジェクトに追加
			addHaveObjects(2, 2);
			// 要求Queueにメタデータを追加する。
			addWantObjects(3, 3 + count);
		}
		public function getMetaCount():int {
			return metaCount;
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
			metaDataArray[index - 3] = ba;
			// netGroupの要求queueから1番をはずす。
			removeWantObjects(index, index);
			// もってるよオブジェクトに追加
			addHaveObjects(index, index);
		}
		public function wantPlayPosition():void {
			try {
				// 再生ポジションを問い合わせる。
				removeHaveObjects(0, 0);
				addWantObjects(0, 0);
			}
			catch(e:Error) {
				Logger.info(e.toString());
			}
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
			if(counter == metaCount) {
				// 開始場所をセットする。
				removeWantObjects(0, 0);
				addHaveObjects(0, 0);
				return true;
			}
			else {
				return false;
			}
		}
		public function setPlayPosition(pos:Number):void {
			// 開始場所決定
			dataStartPos = pos;
			// waitingPosは現状意味をなさない。すべてのObjectを要求させることにする。
			addWantObjects(pos, 9007199254740990);
			waitingPos = 9007199254740990;
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
			// netGroupの要求queueから1番をはずす。
			removeWantObjects(index, index);
			// もってるよオブジェクトに追加
			addHaveObjects(index, index);
			// 再生ポイントを更新する。(本当は連番できているか確認する必要があるが、とりあえずはぶいておく。)
			if(loadingPos < index) {
				loadingPos = index;
			}
		}
		
		// 以下ネットグループの管理
		/**
		 * 処理ネットグループを追加
		 * (あとから追加された場合は、必要なwantObject、haveObjectをつけてやらないとだめ。)
		 */
		public function addNetGroup(netGroup:NetGroup):void {
			var i:int;
			var empty:int = -1;
			for(i = 0;i < netGroupArray.length;i ++) {
				if(netGroupArray[i] === netGroup) { // すでに登録済みならそのままおわる。
					return;
				}
				if(netGroupArray[i] == null && empty == -1) {
					empty = i;
				}
			}
			setupObjectState(netGroup); // オブジェクトの状態を設定しておく
			if(empty == -1) {
				netGroupArray.push(netGroup);
			}
			else {
				netGroupArray[empty] = netGroup;
			}
		}
		/**
		 * 処理ネットグループを削除
		 */
		public function removeNetGroup(netGroup:NetGroup):void {
			var i:int;
			for(i = 0;i < netGroupArray.length;i ++) {
				if(netGroupArray[i] === netGroup) {
					// そんなに増えないだろうということを顧慮して、単にnullにするだけにしておく。
					netGroupArray[i] = null;
				}
			}
		}
		private function setupObjectState(netGroup:NetGroup):void
		{
			// flvHeaderの取得済みか？
			if(flvHeader == null) {
				addWantObjects(1,2); // flvHeaderとMetaDataの数を要求する状態にしておく。
				return;
			}
			else {
				addHaveObjects(1,1);
			}
			// メタ数は取得済みか？
			if(metaCount == 0) {
				addWantObjects(2,2);
				return;
			}
			else {
				addHaveObjects(2,2);
			}
			// メタ情報は取得済みか？
			for(var i:int = 0;i < metaDataArray.length && i < metaCount;i ++) {
				if(metaDataArray is ByteArray) {
					addHaveObjects(3+i, 3+i);
				}
				else {
					addWantObjects(3+i, 3+i);
				}
			}
			// 再生オブジェクトは管理外にしておく。(グループに属してから追加されたデータに適応される・・・といった感じ)
		}
		private function addHaveObjects(start:Number, end:Number):void
		{
			for(var i:int = 0;i < netGroupArray.length;i ++) {
				(netGroupArray[i] as NetGroup).addHaveObjects(start, end);
			}
		}
		private function addWantObjects(start:Number, end:Number):void
		{
			for(var i:int = 0;i < netGroupArray.length;i ++) {
				(netGroupArray[i] as NetGroup).addWantObjects(start, end);
			}
		}
		private function removeHaveObjects(start:Number, end:Number):void
		{
			for(var i:int = 0;i < netGroupArray.length;i ++) {
				(netGroupArray[i] as NetGroup).removeHaveObjects(start, end);
			}
		}
		private function removeWantObjects(start:Number, end:Number):void
		{
			for(var i:int = 0;i < netGroupArray.length;i ++) {
				(netGroupArray[i] as NetGroup).removeWantObjects(start, end);
			}
		}
	}
}