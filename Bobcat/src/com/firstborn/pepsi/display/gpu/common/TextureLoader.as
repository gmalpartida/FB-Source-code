package com.firstborn.pepsi.display.gpu.common {
	import starling.textures.Texture;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.assets.FontLibrary;
	import com.zehfernando.display.components.text.TextSprite;
	import com.zehfernando.signals.SimpleSignal;
	import com.zehfernando.utils.console.error;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ImageDecodingPolicy;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	/**
	 * @author zeh fernando
	 */
	public class TextureLoader {

		// Instances
		private var urlLoader:URLLoader;
		private var _url:String;
		private var scale:Number;
		private var texture:Texture;
		private var textureFormat:String;
		private var generateMipMaps:Boolean;
		private var _onLoaded:SimpleSignal;
		private var _isLoading:Boolean;
		private var _isLoaded:Boolean;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function TextureLoader(__url:String, __scale:Number, __textureFormat:String, __generateMipMaps:Boolean) {
			_url = __url;
			scale = __scale;
			textureFormat = __textureFormat;
			generateMipMaps = __generateMipMaps;
			_isLoading = false;
			_isLoaded = false;
			_onLoaded = new SimpleSignal();

			urlLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.addEventListener(Event.OPEN, onLoadOpen);
			urlLoader.addEventListener(Event.COMPLETE, onLoadComplete);
			urlLoader.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function destroyLoader():void {
			if (urlLoader != null) {
				urlLoader.removeEventListener(Event.OPEN, onLoadOpen);
				urlLoader.removeEventListener(Event.COMPLETE, onLoadComplete);
				urlLoader.removeEventListener(ProgressEvent.PROGRESS, onLoadProgress);
				urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
				try {
					urlLoader.close();
				} catch (__e:Error) {
				}
				urlLoader = null;
			}
			_isLoading = false;
			_isLoaded = false;
		}

		private function createTexture():void {
			var extension:String = url.substr(-3, 3);
			if (extension == "atf") {
				texture = Texture.fromAtfData(urlLoader.data as ByteArray, scale, false);
				finishLoading();
			} else {
				var bmpLoader:Loader = new Loader();
				bmpLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(__e:Event):void {
					// Hack
					var bmp:Bitmap = __e.currentTarget["content"] as Bitmap;
					texture = Texture.fromBitmapData(bmp.bitmapData, generateMipMaps, true, scale, textureFormat);
					if (!FountainFamily.FLAG_PREVENT_LOST_CONTEXT) bmp.bitmapData.dispose(); // This is necessary to get rid of memory use quickly, but prevents context restoration!
					bmp = null;
					finishLoading();
				});
				var loaderContext:LoaderContext = new LoaderContext();
				loaderContext.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
				bmpLoader.loadBytes(urlLoader.data as ByteArray, loaderContext);
			}
		}

		private function createTexturePlaceholder():void {
			// Create en empty texture
			// TODO: use right size?
			var bmp:BitmapData = new BitmapData(256, 256, true, 0x33ff00ff);

			var text:TextSprite = new TextSprite(FontLibrary.BOOSTER_NEXT_FY_REGULAR, 20, 0x000000);
			var txt:String = "IMAGE NOT FOUND: " + _url + " ";
			for (var i:int = 0; i < 10; i++) txt = txt + txt;
			text.text = txt;
			text.width = bmp.width;

			bmp.draw(text);

			texture = Texture.fromBitmapData(bmp, generateMipMaps, true, scale, textureFormat);
			if (!FountainFamily.FLAG_PREVENT_LOST_CONTEXT) bmp.dispose(); // This is necessary to get rid of memory use quickly, but prevents context restoration!
			bmp = null;
			text = null;

			finishLoading();
		}

		private function destroyTexture():void {
			if (texture != null) {
				texture.root.onRestore = null;
				texture.dispose();
				texture = null;
			}
		}

		private function finishLoading():void {
			destroyLoader();
			_isLoading = false;
			_isLoaded = true;
			_onLoaded.dispatch(this);
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		protected function onLoadOpen(__e:Event = null):void {
		}

		protected function onLoadProgress(__e:ProgressEvent = null):void {
			//trace ("ImageContainer :: onLoadProgress :: " + e);
		}

		protected function onLoadError(__e:IOErrorEvent = null):void {
			error("Could not load image! I/O error: " + __e);
			createTexturePlaceholder();
		}

		protected function onLoadComplete(__e:Event = null):void {
			createTexture();
			// Done later, on finishLoading()
			//destroyLoader();
			//_isLoading = false;
			//_isLoaded = true;
			//_onLoaded.dispatch(this);
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function getTexture():Texture {
			return texture;
		}

		public function load():void {
			_isLoading = true;

			urlLoader.load(new URLRequest(_url));
		}

		public function dispose():void {
			destroyLoader();
			destroyTexture();
			_onLoaded.removeAll();
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function isLoaded():Boolean {
			return _isLoaded;
		}

		public function isLoading():Boolean {
			return _isLoading;
		}

		public function get onLoaded():SimpleSignal {
			return _onLoaded;
		}

		public function get url():String {
			return _url;
		}
	}
}
