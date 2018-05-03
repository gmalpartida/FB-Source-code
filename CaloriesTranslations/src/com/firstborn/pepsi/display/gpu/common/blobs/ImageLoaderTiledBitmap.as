package com.firstborn.pepsi.display.gpu.common.blobs {
	import com.zehfernando.data.BitmapDataPool;
	import com.zehfernando.utils.console.error;

	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.system.ImageDecodingPolicy;
	import flash.system.LoaderContext;
	/**
	 * @author zeh fernando
	 */
	public class ImageLoaderTiledBitmap extends TiledBitmapData {

		// A BitmapData with loaded images, as a tile

		// Constants
		public static var EVENT_IMAGE_LOADED:String = "onImageLoaded";

		// Instances
		private var eventDispatcher:EventDispatcher;
		private var loaders:Vector.<Loader>;
		private var urls:Vector.<String>;
		private var _scale:Number;

		private var imageRectangles:Vector.<Rectangle>;					// Position of all actual image rectangles within the tile

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function ImageLoaderTiledBitmap(__maxTextureDimensions:int, __tileDimensions:int, __maxTiles:int, __scale:Number) {
			super(__maxTextureDimensions, __tileDimensions, __maxTiles);

			loaders = new Vector.<Loader>();
			urls = new Vector.<String>();
			_scale = __scale;
			imageRectangles = new Vector.<Rectangle>();

			eventDispatcher = new EventDispatcher();
		}

		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function createTileFromLoader(__loader:Loader):void {
			var w:Number = Math.round(__loader.content.width * _scale);
			var h:Number = Math.round(__loader.content.height * _scale);
			var bmp:BitmapData = BitmapDataPool.getPool().get(w, h, true, 0x00000000);
			var mtx:Matrix = new Matrix();
			mtx.scale(_scale, _scale);
			bmp.draw(__loader, mtx);
			createTileFromBitmapData(bmp, loaders.indexOf(__loader));
			BitmapDataPool.getPool().put(bmp);
		}

		private function createTileFromBitmapData(__bitmapData:BitmapData, __tileIndex:int):void {
			var col:int = __tileIndex % _cols;
			var row:int = Math.floor(__tileIndex / _cols);

			var px:int = Math.round(col * _tileDimensions + _tileDimensions * 0.5 - __bitmapData.width * 0.5);
			var py:int = Math.round(row * _tileDimensions + _tileDimensions * 0.5 - __bitmapData.height * 0.5);

			imageRectangles[__tileIndex] = new Rectangle(px - col * _tileDimensions, py - row * _tileDimensions, __bitmapData.width, __bitmapData.height);

			//log("Adding image of " + __bitmapData.width + "x" + __bitmapData.height + " at " + __tileIndex + " => " + col, row + " ==> " + px, py);

			copyPixels(__bitmapData, __bitmapData.rect, new Point(px, py));
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		protected function onLoadOpen(__e:Event = null):void {
		}

		protected function onLoadProgress(__e:ProgressEvent = null):void {
			//trace ("ImageContainer :: onLoadProgress :: " + e);
		}

		protected function onLoadError(__e:IOErrorEvent = null):void {
			var loader:Loader = (__e.target as LoaderInfo).loader;
			var li:int = loaders.indexOf(loader);
			error("Could not load image [" + (li > -1 ? urls[li] : "??") + "]! I/O error: " + __e);
		}

		protected function onLoadComplete(__e:Event = null):void {
			var loader:Loader = (__e.target as LoaderInfo).loader;
			createTileFromLoader(loader);
			cancelLoad(loader);

			dispatchEvent(new Event(EVENT_IMAGE_LOADED));
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function addEventListener(__type:String, __listener:Function, __useCapture:Boolean = false, __priority:int = 0, __useWeakReference:Boolean = false):void {
			eventDispatcher.addEventListener(__type, __listener, __useCapture, __priority, __useWeakReference);
		}

		public function removeEventListener(__type:String, __listener:Function, __useCapture:Boolean = false):void {
			eventDispatcher.removeEventListener(__type, __listener, __useCapture);
		}

		public function dispatchEvent(__event:Event):Boolean {
			return eventDispatcher.dispatchEvent(__event);
		}

		public function addImage(__url:String):void {
			var loader:Loader = new Loader();

			loaders.push(loader);
			urls.push(__url);
			imageRectangles.push(null);

			loader.contentLoaderInfo.addEventListener(Event.OPEN, onLoadOpen);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);

			var context:LoaderContext = new LoaderContext();
			context.checkPolicyFile = true;
			context.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;

			_numTiles++;

			loader.load(new URLRequest(__url), context);
		}

		public function cancelLoad(__loader:Loader):void {
			__loader.contentLoaderInfo.removeEventListener(Event.OPEN, onLoadOpen);
			__loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadComplete);
			__loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, onLoadProgress);
			__loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			__loader.unload();
			try {
				__loader.close();
			} catch (__e:Error) {
			}
			loaders[loaders.indexOf(__loader)] = null;
		}

		public function cancelAllLoads():void {
			while (loaders.length > 0) {
				if (loaders[0] != null) cancelLoad(loaders[0]);
				loaders.splice(0, 1);
			}
		}

		public function hasTile(__url:String):Boolean {
			return urls.indexOf(__url) > -1;
		}

		public function getTileIndex(__url:String):int {
			return urls.indexOf(__url);
		}

		public function getImageRect(__url:String):Rectangle {
			// Return the image's rectangle INSIDE THE TILE
			return getImageRectInTile(getTileIndex(__url));
		}

		public function getImageRectInTile(__index:int):Rectangle {
			// Returns the image's rectangle INSIDE THE TILE
			return __index >= 0 && __index < imageRectangles.length ? imageRectangles[__index] as Rectangle : null;
		}

		public function isStillLoading():Boolean {
			for each (var loader:Loader in loaders) {
				if (loader != null) return true;
			}
			return false;
		}

		public function getLoadingPhase():Number {
			var loadedItems:int = 0;
			var totalItems:int = 0;
			for each (var loader:Loader in loaders) {
				if (loader == null) loadedItems++;
				totalItems++;
			}
			return loadedItems/totalItems;
		}

		public function reset():void {
			fillRect(rect, 0x00000000);
			cancelAllLoads();
			loaders.length = 0;
			urls.length = 0;
			_numTiles = 0;
		}

		public function setTileFromBitmapData(__bitmapData:BitmapData, __tileIndex:int):void {
			createTileFromBitmapData(__bitmapData, __tileIndex);
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get scale():Number {
			return _scale;
		}
	}
}
