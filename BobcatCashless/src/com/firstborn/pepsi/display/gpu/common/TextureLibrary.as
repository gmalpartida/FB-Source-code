package com.firstborn.pepsi.display.gpu.common {
import com.firstborn.pepsi.assets.ImageLibrary;

import flash.display.Bitmap;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.IOErrorEvent;
import flash.net.URLRequest;

import starling.display.Image;

import starling.textures.Texture;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.assets.FontLibrary;
	import com.firstborn.pepsi.data.AnimationDefinition;
	import com.firstborn.pepsi.data.TextureProfile;
	import com.firstborn.pepsi.data.home.MenuItemDefinition;
	import com.firstborn.pepsi.data.home.MetaballItemDefinition;
	import com.firstborn.pepsi.data.home.SequenceItemDefinition;
	import com.firstborn.pepsi.data.inventory.Beverage;
	import com.firstborn.pepsi.data.inventory.Flavor;
	import com.firstborn.pepsi.display.gpu.common.blobs.BlobShape;
	import com.firstborn.pepsi.display.gpu.common.blobs.ImageLoaderTiledBitmap;
	import com.firstborn.pepsi.display.gpu.common.blobs.MultiBlobBitmap;
	import com.firstborn.pepsi.display.gpu.common.blobs.TiledBitmapData;
	import com.zehfernando.data.BitmapDataPool;
	import com.zehfernando.display.BitmapFillBox;
	import com.zehfernando.display.components.text.TextSprite;
	import com.zehfernando.display.components.text.TextSpriteAlign;
	import com.zehfernando.localization.StringList;
	import com.zehfernando.utils.RandomGenerator;
	import com.zehfernando.utils.console.error;
	import com.zehfernando.utils.console.info;
	import com.zehfernando.utils.getTimerUInt;

	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.display.Shape;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filters.GlowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	/**
	 * @author zeh fernando
	 */
	public class TextureLibrary extends EventDispatcher {

		// Common textures
		// All in one instance so it's easier to manage

		// Event enums
		public static const EVENT_READY:String = "onReady";							// Everything loaded and created
		public static const EVENT_PROGRESS:String = "onProgress";					// Progress on loading/creating stuff

		// Constants
		public static const TEXTURE_ID_GENERIC_TEXT:String = "generic-text";
		public static const TEXTURE_ID_GENERIC_NOISE:String = "generic-noise";
		public static const TEXTURE_ID_BLOB_SHAPES_FOCUS:String = "blob-shapes-focus";
		public static const TEXTURE_ID_BLOB_SHAPES_STROKE:String = "blob-shapes-stroke";
		public static const TEXTURE_ID_BLOB_SHAPES_GRADIENT:String = "blob-shapes-gradient";
		public static const TEXTURE_ID_BLOB_LOGOS:String = "blob-logos";
		public static const TEXTURE_ID_BLOB_LOGOS_BIG:String = "blob-logos-big";
		public static const TEXTURE_ID_BLOB_LOGOS_SPONSORS:String = "blob-logos-sponsors";
		public static const TEXTURE_ID_BLOB_PARTICLES:String = "blob-particles";
		public static const TEXTURE_ID_BRAND_LIQUID_BACKGROUND:String = "brand-liquid-background";
		public static const ANIMATION_ID_BUBBLES:String = "menu_bubbles";

		private static const LOGO_DIMENSIONS:int = 256;							// Dimensions used by the ORIGINAL logo images
		private static var   LOGO_DIMENSIONS_BIG:int = 512;						// Dimensions used by the ORIGINAL logo images (big version)
		private static const LOGO_DIMENSIONS_SPONSORS:int = 128;				// Dimensions used by the sponsor logos
		private static const GRADIENT_DIMENSIONS:int = 256;						// Dimensions used by the ORIGINAL gradient images
		private static const BUBBLE_DIMENSIONS:int = 186;						// Dimensions used by the bubble animation tiles (ugh, hardcoded)
		private static const UNIQUE_BLOB_FOCUS_TEXTURES:int = 2;				// Number of different textures
		private static const UNIQUE_BLOB_PARTICLE_TEXTURES:int = 8;				// Number of different textures
		private static const UNIQUE_BLOB_STROKE_TEXTURES:int = 4;				// Number of different textures
		//private static const UNIQUE_BLOB_FILL_TEXTURES:int = 4;				// Number of different textures
		public static const BLOB_TEXTURE_MARGIN:int = 1;						// Margin per image for proper antialias
		private static const BLOB_TEXTURE_STROKE_WIDTH:Number = 1;				// Width for the stroke (assuming a texture of 256w)

		// Instances
		private var _textureNoise:Texture;
		private var _textureBlobFocus:Texture;
		private var _textureBlobStrokes:Texture;
		private var _textureBlobGradients:Texture;
		private var _textureBlobGradientsBitmap:ImageLoaderTiledBitmap;
		private var _textureBlobLogos:Texture;
		private var _textureBlobLogosBig:Texture;
		private var _textureBlobLogosSponsors:Texture;
		private var _textureBlobLogosBitmap:ImageLoaderTiledBitmap;
		private var _textureBlobLogosBitmapRectanglesCache:Object;
		private var _textureBlobLogosBigBitmap:ImageLoaderTiledBitmap;
		private var _textureBlobLogosSponsorsBitmap:ImageLoaderTiledBitmap;
		private var _textureBlobParticles:Texture;
		private var _blobBubbleTextureResolution:int;
		private var _blobParticleTextureResolution:int;
		private var _blobFocusTextureResolution:int;
		private var _blobStrokeTextureResolution:int;
		private var _blobGradientTextureResolution:int;
		private var _blobLogoTextureResolution:int;
		private var _blobLogoBigTextureResolution:int;
		private var _blobLogoSponsorsTextureResolution:int;

		private var _animationDefinitionBlobBubbles:AnimationDefinition;

		private var _textureLiquidBlob:Texture;
		private var _textureLiquidStroke:Texture;

		private var _customTextureLoaders:Object;				// Textures with text id (URL to the files really) and a TextureLoader instance

		private var inited:Boolean;
		private var finished:Boolean;

		private var ti:uint;

		private var allCustomTexturesLoaded:Boolean;
		private var allLogosLoaded:Boolean;
		private var allGradientsLoaded:Boolean;

		//Generate the textures for the language selection when there's no drinks
		private var _textureBlobMessageUnavailableTitle: Vector.<Texture> = new Vector.<Texture>();
		private var _textureBlobMessageUnavailableSubtitle: Vector.<Texture> = new Vector.<Texture>();
        private var _textureBlobMessagePayment: Vector.<Texture> = new Vector.<Texture>();

        private var _textureAquafinaLogoThanks : Texture;
        private var _textureAuthorizePending : Texture;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function TextureLibrary() {
			_customTextureLoaders = {};
			_textureBlobLogosBitmapRectanglesCache = {};

			allLogosLoaded = false;
			allGradientsLoaded = false;
			allCustomTexturesLoaded = false;

            if(FountainFamily.platform.id.toLowerCase() == "bobcat") {
                LOGO_DIMENSIONS_BIG = 1024;
                trace("Changed the Logos big dimension to 1024 for Bobcat platform");
            }
		}

		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function createTextureNoise():void {
			// Create a noise texture that can be re-used
			var noiseDef:TextureProfile = FountainFamily.platform.getTextureProfile(TEXTURE_ID_GENERIC_NOISE);

			// Draw noise
			var bitmap:BitmapData = BitmapFillBox.getPatternNoise(noiseDef.resolution, noiseDef.resolution);
			_textureNoise = Texture.fromBitmapData(bitmap, true, false, 1, noiseDef.format, true);
			if (!FountainFamily.FLAG_PREVENT_LOST_CONTEXT) bitmap.dispose();
		}

		private function createTextureBlobGradient():void {
			// Loads all needed gradients into a bitmap

			var menuItems:Vector.<MenuItemDefinition> = MenuItemDefinition.getMenuItems();
			var beverage:Beverage;
			var i:int;
			var urls:Vector.<String> = new Vector.<String>();

			// Lists all needed gradients
			for (i = 0; i < menuItems.length; i++) {
				beverage = FountainFamily.inventory.getBeverageById(menuItems[i].beverageId);
				if (urls.indexOf(beverage.getDesign().imageGradient) < 0) urls.push(beverage.getDesign().imageGradient);
			}

			info("Loading " + urls.length + " gradient images for a total of " + menuItems.length + " menu items.");

			// Create bitmap
			if (urls.length > 0) {
				_textureBlobGradientsBitmap = new ImageLoaderTiledBitmap(FountainFamily.platform.gpuTextureMaximumDimensions, _blobGradientTextureResolution, urls.length, _blobGradientTextureResolution/GRADIENT_DIMENSIONS);
				_textureBlobGradientsBitmap.addEventListener(ImageLoaderTiledBitmap.EVENT_IMAGE_LOADED, onBlobGradientLoaded);

				// Start loading all gradients
				for (i = 0; i < urls.length; i++) {
					_textureBlobGradientsBitmap.addImage(urls[i]);
				}
			} else {
				allGradientsLoaded = true;
			}
		}

		private function createTextureBlobGradientsFinal():void {
			// Finish creating the textures
			info("Loaded all gradients");

			// Adds a little bit of noise
			drawNoise(_textureBlobGradientsBitmap, 0.06);

			if (FountainFamily.DEBUG_BEVERAGES_USE_GENERIC_DATA) {
				// Just fill it with a solid color
				_textureBlobGradientsBitmap.fillRect(_textureBlobGradientsBitmap.rect, 0xffaaaaaa);
			}

			// Apply shape mask to gradients
			var newGradientsBitmap:BitmapData = BitmapDataPool.getPool().get(_textureBlobGradientsBitmap.width, _textureBlobGradientsBitmap.height, true, 0x00000000);
			for (var i:int = 0; i < _textureBlobGradientsBitmap.numTiles; i++) {
				copyShapeMasked(_textureBlobGradientsBitmap, newGradientsBitmap, _textureBlobGradientsBitmap.getTileRect(i), 0);
			}
			_textureBlobGradientsBitmap.copyPixels(newGradientsBitmap, newGradientsBitmap.rect, new Point(0, 0));
			BitmapDataPool.getPool().put(newGradientsBitmap);
			newGradientsBitmap = null;

			// Finally, create the texture
			_textureBlobGradients = Texture.fromBitmapData(_textureBlobGradientsBitmap, true, false, 1, FountainFamily.platform.getTextureProfile(TEXTURE_ID_BLOB_SHAPES_GRADIENT).format);

			allGradientsLoaded = true;

			checkCompletion();
		}

		private function createTextureBlobStroke():void {
			// Create stroke blobs; use custom mipmaps to maintain stroke width regardless of size

			// Create bitmap
			var blobStrokeWidth:Number = BLOB_TEXTURE_STROKE_WIDTH * (_blobStrokeTextureResolution / 256);

			var maxTextureWidth:int = FountainFamily.platform.gpuTextureMaximumDimensions;
			var tileWidth:int = _blobStrokeTextureResolution;
			var bitmap:MultiBlobBitmap;
			var bitmaps:Array = [];
			var margin:Number = 10; // BLOB_TEXTURE_MARGIN;
			while (tileWidth >= 1) {
				bitmap = new MultiBlobBitmap(maxTextureWidth, tileWidth, UNIQUE_BLOB_STROKE_TEXTURES, margin - blobStrokeWidth * 0.5);
				//bitmap = new MultiBlobBitmap(maxTextureWidth, tileWidth, UNIQUE_BLOB_STROKE_TEXTURES, margin);
				bitmap.fillWithBlobs(0x000000, 0, 0xffffff, 1, blobStrokeWidth, 1, false, null, true);
				bitmaps.push(bitmap);
				margin /= 2;
				tileWidth = tileWidth >> 1;
				maxTextureWidth = maxTextureWidth >> 1;

				blobStrokeWidth *= 0.8; // Actually scale it down a bit
			}

			// Create texture
			_textureBlobStrokes = Texture.fromBitmapDatas(bitmaps, true, 1, FountainFamily.platform.getTextureProfile(TEXTURE_ID_BLOB_SHAPES_STROKE).format);
			if (!FountainFamily.FLAG_PREVENT_LOST_CONTEXT) {
				for each (var bmp:BitmapData in bitmaps) bmp.dispose();
				bitmaps = null;
			}
		}

		private function createTextureBlobFocus():void {
			// Create focus blobs

			// Create bitmap
			var bitmap:MultiBlobBitmap = new MultiBlobBitmap(FountainFamily.platform.gpuTextureMaximumDimensions, _blobFocusTextureResolution, UNIQUE_BLOB_FOCUS_TEXTURES, BLOB_TEXTURE_MARGIN);
			bitmap.fillWithBlobs(FountainFamily.adaInfo.hardwareFocusFillColor.toRRGGBB(), FountainFamily.adaInfo.hardwareFocusFillColor.a, FountainFamily.adaInfo.hardwareFocusBorderColor.toRRGGBB(), 1, FountainFamily.adaInfo.hardwareFocusBorderWidth * (_blobFocusTextureResolution / 256), FountainFamily.adaInfo.hardwareFocusScaleNoise, false, FountainFamily.adaInfo.hardwareFocusFilters);

			// Create texture
			_textureBlobFocus = Texture.fromBitmapData(bitmap, true, false, 1, FountainFamily.platform.getTextureProfile(TEXTURE_ID_BLOB_SHAPES_FOCUS).format);
			if (!FountainFamily.FLAG_PREVENT_LOST_CONTEXT) bitmap.dispose();
		}

		private function createTexturesLiquidView():void {
			// Create all textures needed by the brand view's liquid view

			var tpf:TextureProfile;
			var bitmap:MultiBlobBitmap;

			// Blob mask
			tpf = FountainFamily.platform.getTextureProfile("blob-huge-mask");

			bitmap = new MultiBlobBitmap(tpf.resolution, tpf.resolution, 1, 2);
			bitmap.addBlob(0xffffff, 1, 0x000000, 0, 2, 0.275, false, null, false, true);

			_textureLiquidBlob = Texture.fromBitmapData(bitmap, true, false, 1, tpf.format);
			if (!FountainFamily.FLAG_PREVENT_LOST_CONTEXT) bitmap.dispose();

			// Stroke
			tpf = FountainFamily.platform.getTextureProfile("blob-huge-stroke");
			bitmap = new MultiBlobBitmap(tpf.resolution, tpf.resolution, 1, 2);
			bitmap.addBlob(0x000000, 0, 0xffffff, 1, 2.9, 0.275, false, null, false, true);

			_textureLiquidStroke = Texture.fromBitmapData(bitmap, true, false, 1, tpf.format);
			if (!FountainFamily.FLAG_PREVENT_LOST_CONTEXT) bitmap.dispose();
		}

		private function createTextureBlobBubbles():void {
			// Create the texture for the bubbles

			_animationDefinitionBlobBubbles = AnimationDefinition.getAnimationDefinition(ANIMATION_ID_BUBBLES, FountainFamily.animationDefinitions);
			addLoadedTexture(_animationDefinitionBlobBubbles.image, _animationDefinitionBlobBubbles.format);
		}

		private function createTextureBlobLogos():void {
			// Loads all needed logos into a bitmap

			var menuItems:Vector.<MenuItemDefinition> = MenuItemDefinition.getMenuItems();
			var beverage:Beverage;
			var i:int;
			var urls:Vector.<String> = new Vector.<String>();
			var urlsBig:Vector.<String> = new Vector.<String>();
			var urlsSponsors:Vector.<String> = new Vector.<String>(); // 128x128

			// Lists all needed logos
			for (i = 0; i < menuItems.length; i++) {
				beverage = FountainFamily.inventory.getBeverageById(menuItems[i].beverageId);
				if (!beverage.getDesign().imageLogoIsBig && urls.indexOf(beverage.getDesign().imageLogo) < 0) urls.push(beverage.getDesign().imageLogo);
				if (!beverage.getDesign().imageLogoBrandIsBig && urls.indexOf(beverage.getDesign().imageLogoBrand) < 0) urls.push(beverage.getDesign().imageLogoBrand);
				if (beverage.getDesign().imageLogoIsBig && urlsBig.indexOf(beverage.getDesign().imageLogo) < 0) urlsBig.push(beverage.getDesign().imageLogo);
				if (beverage.getDesign().imageLogoBrandIsBig && urlsBig.indexOf(beverage.getDesign().imageLogoBrand) < 0) urlsBig.push(beverage.getDesign().imageLogoBrand);
				if (beverage.isMix) {
					// Since it's a mix, need to load the related recipe id's brand logo too
					if (beverage.getRelatedBrandImageLogoIsBig()) {
						if (urlsBig.indexOf(beverage.getRelatedBrandImageLogo()) < 0) urlsBig.push(beverage.getRelatedBrandImageLogo());
					} else {
						if (urls.indexOf(beverage.getRelatedBrandImageLogo()) < 0) urls.push(beverage.getRelatedBrandImageLogo());
					}
				}

				// Sponsor logos
				if (beverage.getDesign().imageLogoFlavorSponsor.length > 0 && urlsSponsors.indexOf(beverage.getDesign().imageLogoFlavorSponsor) < 0) urlsSponsors.push(beverage.getDesign().imageLogoFlavorSponsor);
			}

			info("Loading " + urls.length + " small, " + urlsBig.length + " big logo images for a total of " + menuItems.length + " menu items.");

			// Create bitmap and start loading logos
			if (urls.length > 0) {
				_textureBlobLogosBitmap = new ImageLoaderTiledBitmap(FountainFamily.platform.gpuTextureMaximumDimensions, _blobLogoTextureResolution, urls.length, _blobLogoTextureResolution/LOGO_DIMENSIONS);
				_textureBlobLogosBitmap.addEventListener(ImageLoaderTiledBitmap.EVENT_IMAGE_LOADED, onBlobLogoLoaded);

				for (i = 0; i < urls.length; i++) _textureBlobLogosBitmap.addImage(urls[i]);
			}

			if (urlsBig.length > 0) {
				_textureBlobLogosBigBitmap = new ImageLoaderTiledBitmap(FountainFamily.platform.gpuTextureMaximumDimensions, _blobLogoBigTextureResolution, urlsBig.length, _blobLogoBigTextureResolution/LOGO_DIMENSIONS_BIG);
				_textureBlobLogosBigBitmap.addEventListener(ImageLoaderTiledBitmap.EVENT_IMAGE_LOADED, onBlobLogoLoaded);

				for (i = 0; i < urlsBig.length; i++) _textureBlobLogosBigBitmap.addImage(urlsBig[i]);
			}

			if (urlsSponsors.length > 0) {
				_textureBlobLogosSponsorsBitmap = new ImageLoaderTiledBitmap(FountainFamily.platform.gpuTextureMaximumDimensions, _blobLogoSponsorsTextureResolution, urlsSponsors.length, _blobLogoSponsorsTextureResolution/LOGO_DIMENSIONS_SPONSORS);
				_textureBlobLogosSponsorsBitmap.addEventListener(ImageLoaderTiledBitmap.EVENT_IMAGE_LOADED, onBlobLogoLoaded);

				for (i = 0; i < urlsSponsors.length; i++) _textureBlobLogosSponsorsBitmap.addImage(urlsSponsors[i]);
			}

			if (urls.length == 0 && urlsBig.length == 0 && urlsSponsors.length == 0) {
				// Should never happen in practice, but allows execution
				allLogosLoaded = true;
			}
		}

		private function createTextureBlobLogosFinal():void {
			// Finish creating the textures
			info("Loaded all logos");

			if (FountainFamily.DEBUG_BEVERAGES_USE_GENERIC_DATA) {
				// Fill the texture with numbers instead
				createDebugDataOnTopOfBitmapTiles(_textureBlobLogosBitmap, _blobLogoTextureResolution);
				createDebugDataOnTopOfBitmapTiles(_textureBlobLogosBigBitmap, _blobLogoBigTextureResolution);
				createDebugDataOnTopOfBitmapTiles(_textureBlobLogosSponsorsBitmap, _blobLogoSponsorsTextureResolution);
			}

			if (_textureBlobLogosBitmap != null) _textureBlobLogos = Texture.fromBitmapData(_textureBlobLogosBitmap, true, false, 1, FountainFamily.platform.getTextureProfile(TEXTURE_ID_BLOB_LOGOS).format);
			if (_textureBlobLogosBigBitmap != null) _textureBlobLogosBig = Texture.fromBitmapData(_textureBlobLogosBigBitmap, true, false, 1, FountainFamily.platform.getTextureProfile(TEXTURE_ID_BLOB_LOGOS_BIG).format);
			if (_textureBlobLogosSponsorsBitmap != null) _textureBlobLogosSponsors = Texture.fromBitmapData(_textureBlobLogosSponsorsBitmap, true, false, 1, FountainFamily.platform.getTextureProfile(TEXTURE_ID_BLOB_LOGOS_SPONSORS).format);

			allLogosLoaded = true;

			checkCompletion();
		}

		private function createDebugDataOnTopOfBitmapTiles(__bitmap:ImageLoaderTiledBitmap, __tileDimensions:int):void {
			if (__bitmap == null) return;

			// Create numbers on top of a bitmap's tiles, for debugging
			var bmp:BitmapData = new BitmapData(__tileDimensions, __tileDimensions, true, 0x00000000);
			var txt:TextSprite = new TextSprite(FontLibrary.BOOSTER_NEXT_FY_BOLD, FountainFamily.DEBUG_BEVERAGES_USE_XYZW_GROUPS ? 160 : 200, 0xeeeeee, 1);
			txt.filters = [new GlowFilter(0x000000, 1, 4, 4, 4)];
			var mtx:Matrix = new Matrix();
			var i:int;
			for (i = 0; i < __bitmap.numTiles; i++) {
				txt.text = (i + 1).toString(10) + (FountainFamily.DEBUG_BEVERAGES_USE_XYZW_GROUPS ? FountainFamily.inventory.getBeverages()[i].groupId : "");
				mtx.identity();
				mtx.translate(__tileDimensions * 0.5, __tileDimensions * 0.5);
				mtx.translate(-txt.width * 0.5, -txt.height * 0.5);
				bmp.fillRect(bmp.rect, 0x00000000);
				bmp.draw(txt, mtx);
				__bitmap.setTileFromBitmapData(bmp, i);
			}
			bmp.dispose();
		}

		private function createTextureMessages():void {

			for(var i : uint = 0; i < FountainFamily.LOCALE_ISO.length; i++) {

				// Unavailable title ("Out of stock") on every language
				_textureBlobMessageUnavailableTitle.push(TextBitmap.createTextures(
						new <TextBitmap>[
							new TextBitmap(StringList.getList(FountainFamily.LOCALE_ISO[i]).getString("home/brand-unavailable-title-1"), FontLibrary.BOOSTER_FY_REGULAR, null, 36.87, NaN, 0xffffff, -1, 1, 1, -20, -20, TextSpriteAlign.CENTER, LOGO_DIMENSIONS),
							new TextBitmap(StringList.getList(FountainFamily.LOCALE_ISO[i]).getString("home/brand-unavailable-title-2"), FontLibrary.BOOSTER_FY_REGULAR, null, 59.91, NaN, 0xffffff, -1, 1, 1, -40, -40, TextSpriteAlign.CENTER, LOGO_DIMENSIONS),
						], -4, true, true
				));

				// Unavailable subtitle ("Please choose another drink") on every language
				_textureBlobMessageUnavailableSubtitle.push(TextBitmap.createTextures(
						new <TextBitmap>[
							new TextBitmap(StringList.getList(FountainFamily.LOCALE_ISO[i]).getString("home/brand-unavailable-subtitle"), FontLibrary.BOOSTER_FY_REGULAR, null, 17.28, NaN, 0xffffff, -1, 1, 1, 60, 60, TextSpriteAlign.CENTER, LOGO_DIMENSIONS),
						], 0, true, true
				));

                //"Free of charge" copy for the cashless prototype
                _textureBlobMessagePayment.push(TextBitmap.createTextures(
                        new <TextBitmap>[
                            new TextBitmap(StringList.getList(FountainFamily.LOCALE_ISO[i]).getString("home/payment-free"), FontLibrary.BOOSTER_NEXT_FY_BOLD, null, 60, NaN, 0xffffff, -1, 1, 1, 60, 60, TextSpriteAlign.CENTER, LOGO_DIMENSIONS),
                        ], 0, true, true
                ));

			}
		}

		private function loadNextTextureCustom():void {
			var nextTexture:TextureLoader = null;
			for (var iis:String in _customTextureLoaders) {
				if (!(_customTextureLoaders[iis] as TextureLoader).isLoaded() && !(_customTextureLoaders[iis] as TextureLoader).isLoading()) {
					nextTexture = _customTextureLoaders[iis];
					break;
				}
			}

			if (nextTexture == null) {
				// All loaded? End prematurely
				createLoadedTexturesFinal();
			} else {
				nextTexture.load();
			}
		}

		private function createLoadedTexturesBackgrounds():void {
			// Creates textures for the brand liquids, adding them to the custom texture list

			var menuItems:Vector.<MenuItemDefinition> = MenuItemDefinition.getMenuItems();
			var beverage:Beverage;
			var numItems:int = 0;
			var i:int;

			// Lists all needed background
			for (i = 0; i < menuItems.length; i++) {
				beverage = FountainFamily.inventory.getBeverageById(menuItems[i].beverageId);
				numItems += addLoadedTexture(beverage.getDesign().imageLiquidBackground, FountainFamily.platform.getTextureProfile(TEXTURE_ID_BRAND_LIQUID_BACKGROUND).format) ? 1 : 0;
			}

			info("Loading " + numItems + " background images for a total of " + menuItems.length + " menu items.");
		}

		private function createLoadedTexturesFlavorAnimations():void {
			// Creates textures for the flavor animations, adding them to the custom texture list

			var flavors:Vector.<Flavor> = FountainFamily.inventory.getFlavors();
			var flavor:Flavor;
			var numItems:int = 0;
			var animationDef:AnimationDefinition;
			var i:int;

			// Lists all needed background
			for (i = 0; i < flavors.length; i++) {
				flavor = flavors[i];
				if (flavor.design.animationIntro.length > 0) {
					animationDef = AnimationDefinition.getAnimationDefinition(flavor.design.animationIntro, FountainFamily.animationDefinitions);
					if (animationDef != null) numItems += addLoadedTexture(animationDef.image, animationDef.format) ? 1 : 0;
				}
				if (flavor.design.animationSelect.length > 0) {
					animationDef = AnimationDefinition.getAnimationDefinition(flavor.design.animationSelect, FountainFamily.animationDefinitions);
					if (animationDef != null) numItems += addLoadedTexture(animationDef.image, animationDef.format) ? 1 : 0;
				}
				if (flavor.design.animationDeselect.length > 0) {
					animationDef = AnimationDefinition.getAnimationDefinition(flavor.design.animationDeselect, FountainFamily.animationDefinitions);
					if (animationDef != null) numItems += addLoadedTexture(animationDef.image, animationDef.format) ? 1 : 0;
				}
			}

			info("Loading " + numItems + " flavor animations for a total of " + flavors.length + " flavor items.");
		}

		private function createLoadedTexturesBrandAnimations():void {
			// Creates textures for the brand view animations, adding them to the custom texture list

			var menuItems:Vector.<MenuItemDefinition> = MenuItemDefinition.getMenuItems();
			var beverage:Beverage;
			var i:int;
			var numItems:int = 0;
			var animationId:String;
			var animationDef:AnimationDefinition;

			// Lists all needed animations
			for (i = 0; i < menuItems.length; i++) {
				beverage = FountainFamily.inventory.getBeverageById(menuItems[i].beverageId);
				animationId = beverage.getDesign().animationId;
				if (animationId != null && animationId.length > 0) {
					animationDef = AnimationDefinition.getAnimationDefinition(animationId, FountainFamily.animationDefinitions);
					if (animationDef != null) numItems += addLoadedTexture(animationDef.image, animationDef.format) ? 1 : 0;
				}
			}

			info("Loading " + numItems + " brand animations for a total of " + menuItems.length + " brands.");
		}

		private function createLoadedTexturesMenuSequenceAnimations():void {
			// Creates textures for the menu sequence animations, adding them to the custom texture list

			var i:int;
			var numItems:int = 0;
			var animationId:String;
			var animationDef:AnimationDefinition;

			// Adds all sequences
			var allSequences:Vector.<SequenceItemDefinition> = SequenceItemDefinition.getSequenceItems().concat();
			var sequence:SequenceItemDefinition;

			for (i = 0; i < allSequences.length; i++) {
				sequence = allSequences[i];
				animationId = sequence.animationId;
				if (sequence.frequency > 0 && animationId != null && animationId.length > 0) {
					animationDef = AnimationDefinition.getAnimationDefinition(animationId, FountainFamily.animationDefinitions);
					if (animationDef != null) numItems += addLoadedTexture(animationDef.image, animationDef.format) ? 1 : 0;
				}
			}

			// Adds all metaballs
			var allMetaballs:Vector.<MetaballItemDefinition> = MetaballItemDefinition.getMetaballItems().concat();
			var metaball:MetaballItemDefinition;

			for (i = 0; i < allMetaballs.length; i++) {
				metaball = allMetaballs[i];
				animationId = metaball.animationId;
				if (metaball.frequency > 0 && animationId != null && animationId.length > 0) {
					animationDef = AnimationDefinition.getAnimationDefinition(animationId, FountainFamily.animationDefinitions);
					if (animationDef != null) numItems += addLoadedTexture(animationDef.image, animationDef.format) ? 1 : 0;
				}
			}

			info("Loading " + numItems + " animation/metaball animations for a total of " + allSequences.length + " sequences and " + allMetaballs.length + " metaballs.");
		}

		private function addLoadedTexture(__url:String, __textureFormat:String):Boolean {
			if (!hasLoadedTexture(__url)) {
				var textureLoader:TextureLoader;
				textureLoader = new TextureLoader(__url, 1, __textureFormat, false);
				_customTextureLoaders[__url] = textureLoader;
				textureLoader.onLoaded.add(onCustomTextureLoaderLoaded);
				//textureLoader.load();
				return true;
			}
			return false;
		}

		private function createLoadedTexturesFinal():void {
			// Finished loading all the custom loaded textures
			var textures:Vector.<String> = new Vector.<String>();
			for (var iis:String in _customTextureLoaders) {
				textures.push(iis);
			}
			info("Loaded all custom loaded textures (" + textures.length + ")");// + textures.join(","));

			allCustomTexturesLoaded = true;

			checkCompletion();
		}

		private function checkCompletion():void {
			// Check if everything was created
			if (allLogosLoaded && allGradientsLoaded && allCustomTexturesLoaded) {
				info("Finished creating and loading all textures in " + (getTimerUInt() - ti) + "ms.");
				finished = true;
				System.gc();
				System.pauseForGCIfCollectionImminent(0);
				dispatchEvent(new Event(EVENT_PROGRESS));
				dispatchEvent(new Event(EVENT_READY));
			}
		}

		private function drawNoise(__bitmapData:BitmapData, __alpha:Number):void {
			// Draws a layer of overlay noise on a bitmap data
			var noise:BitmapData = BitmapDataPool.getPool().get(__bitmapData.width, __bitmapData.height, false, 0xffffff);
			var noisePattern:BitmapData = BitmapFillBox.getPatternNoise(128, 128);
			for (var row:int = 0; row < noise.height; row += noisePattern.height) {
				for (var col:int = 0; col < noise.width; col += noisePattern.width) {
					noise.copyPixels(noisePattern, noisePattern.rect, new Point(col, row));
				}
			}
			__bitmapData.draw(noise, null, new ColorTransform(1, 1, 1, __alpha), BlendMode.OVERLAY, null, false);
			//__bitmapData.drawWithQuality(noise, null, new ColorTransform(1, 1, 1, __alpha), BlendMode.OVERLAY, null, true, StageQuality.HIGH_16X16);
			BitmapDataPool.getPool().put(noise);
			noise = null;
			noisePattern.dispose();
			noisePattern = null;
		}

		private function copyShapeMasked(__sourceBitmap:BitmapData, __targetBitmap:BitmapData, __sourceRect:Rectangle, __shapeMargin:Number):void {
			// Copies a shape from a BitmapData to another, applying a shape mask

			// Dimensions HAVE to be square
			var tileDimensions:Number = __sourceRect.width;
			var radius:Number = (tileDimensions / 2) - __shapeMargin;

			// Draw gradient
			__targetBitmap.copyPixels(__sourceBitmap, __sourceRect, new Point(__sourceRect.x, __sourceRect.y));

			// Clip to blob mask
			var bmpMask:BitmapData = BitmapDataPool.getPool().get(tileDimensions, tileDimensions, true, 0xffffff);
			var mtx:Matrix = new Matrix();
			mtx.translate(tileDimensions * 0.5, tileDimensions * 0.5);
			var shape:Shape = new BlobShape(radius, 0x000000, 1, 0x000000, 0, 0);
			bmpMask.drawWithQuality(shape, mtx, null, null, null, true, StageQuality.HIGH_16X16);
			__targetBitmap.copyChannel(bmpMask, bmpMask.rect, new Point(__sourceRect.x, __sourceRect.y), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
			BitmapDataPool.getPool().put(bmpMask);
			bmpMask = null;
			shape = null;
		}

		private function getBlobLogoTiledBitmapContainer(__url:String):ImageLoaderTiledBitmap {
			// Returns which of the multi-logo tile bitmaps actually contains a given logo (by URL)
			if (_textureBlobLogosBitmap != null && _textureBlobLogosBitmap.hasTile(__url)) {
				// Normal logo
				return _textureBlobLogosBitmap;
			} else if (_textureBlobLogosBigBitmap != null && _textureBlobLogosBigBitmap.hasTile(__url)) {
				// Big logo
				return _textureBlobLogosBigBitmap;
			} else if (_textureBlobLogosSponsorsBitmap != null && _textureBlobLogosSponsorsBitmap.hasTile(__url)) {
				// Sponsors logo
				return _textureBlobLogosSponsorsBitmap;
			} else {
				error("Error! URL [" + "] is not a loaded logo, so no bitmap could be found!");
				return null;
			}
		}

        private function createAquafinaThanksTexture() : void {
            if(FountainFamily.PAYMENT_ENABLED) {
                var loader:Loader = new Loader();

                loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e : Event) : void {
                    _textureAquafinaLogoThanks = Texture.fromBitmap(Bitmap(LoaderInfo(e.target).content));
                });

                loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e: Event) : void {
                    trace("image not found");
                });

                loader.load(new URLRequest("./assets/beverages/aquafinaThanksLogo.png"));
            }
        }

        private function createAuthorizePendingTexture() : void {
            if(FountainFamily.PAYMENT_ENABLED) {
                var loader:Loader = new Loader();

                loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e : Event) : void {
                    _textureAuthorizePending = Texture.fromBitmap(Bitmap(LoaderInfo(e.target).content));
                });

                loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e: Event) : void {
                    trace("image not found");
                });

                loader.load(new URLRequest("./assets/cashless/waitingCircle.png"));
            }
        }


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onBlobGradientLoaded(__e:Event):void {
			dispatchEvent(new Event(EVENT_PROGRESS));
			if (!_textureBlobGradientsBitmap.isStillLoading()) {
				createTextureBlobGradientsFinal();
			}
		}

		private function onBlobLogoLoaded(__e:Event):void {
			dispatchEvent(new Event(EVENT_PROGRESS));
			if ((_textureBlobLogosBitmap == null || !_textureBlobLogosBitmap.isStillLoading()) && (_textureBlobLogosBigBitmap == null || !_textureBlobLogosBigBitmap.isStillLoading()) && (_textureBlobLogosSponsorsBitmap == null || !_textureBlobLogosSponsorsBitmap.isStillLoading())) {
				createTextureBlobLogosFinal();
			}
		}

		private function onCustomTextureLoaderLoaded(__textureLoader:TextureLoader):void {
			// Check if all loaded

			var allLoaded:Boolean = true;
			var needsLoading:Boolean = false;

			for (var iis:String in _customTextureLoaders) {
				if (!(_customTextureLoaders[iis] as TextureLoader).isLoaded()) allLoaded = false;
				if (!(_customTextureLoaders[iis] as TextureLoader).isLoaded() && !(_customTextureLoaders[iis] as TextureLoader).isLoading()) needsLoading = true;
			}

			dispatchEvent(new Event(EVENT_PROGRESS));

			// All loaded
			if (needsLoading) {
				loadNextTextureCustom();
			} else if (allLoaded) {
				createLoadedTexturesFinal();
			}
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function init():void {
			// Creates textures

			inited = true;

			ti = getTimerUInt();

			_blobFocusTextureResolution = Math.round(FountainFamily.platform.getTextureProfile(TEXTURE_ID_BLOB_SHAPES_FOCUS).resolution);
			_blobStrokeTextureResolution = Math.round(FountainFamily.platform.getTextureProfile(TEXTURE_ID_BLOB_SHAPES_STROKE).resolution);
			_blobGradientTextureResolution = Math.round(FountainFamily.platform.getTextureProfile(TEXTURE_ID_BLOB_SHAPES_GRADIENT).resolution);
			_blobLogoTextureResolution = Math.round(FountainFamily.platform.getTextureProfile(TEXTURE_ID_BLOB_LOGOS).resolution);
			_blobLogoBigTextureResolution = Math.round(FountainFamily.platform.getTextureProfile(TEXTURE_ID_BLOB_LOGOS_BIG).resolution);
			_blobLogoSponsorsTextureResolution = Math.round(FountainFamily.platform.getTextureProfile(TEXTURE_ID_BLOB_LOGOS_SPONSORS).resolution);
			_blobParticleTextureResolution = Math.round(FountainFamily.platform.getTextureProfile(TEXTURE_ID_BLOB_PARTICLES).resolution);
			_blobBubbleTextureResolution = BUBBLE_DIMENSIONS;

			// Noise
			createTextureNoise();

			// Particle blobs
			var bitmap:MultiBlobBitmap = new MultiBlobBitmap(FountainFamily.platform.gpuTextureMaximumDimensions, _blobParticleTextureResolution, UNIQUE_BLOB_PARTICLE_TEXTURES, BLOB_TEXTURE_MARGIN);
			while (bitmap.numTiles < UNIQUE_BLOB_PARTICLE_TEXTURES) bitmap.addBlob(0xffffff, 1, 0x000000, 0, 2, RandomGenerator.getInRange(0.2, 2.4), false, null, true);
			_textureBlobParticles = Texture.fromBitmapData(bitmap, true, false, 1, FountainFamily.platform.getTextureProfile(TEXTURE_ID_BLOB_PARTICLES).format);
			if (!FountainFamily.FLAG_PREVENT_LOST_CONTEXT) bitmap.dispose();

			// Gradient blobs
			createTextureBlobGradient();

			// Blob strokes
			createTextureBlobStroke();

			// Blob focus strokes
			createTextureBlobFocus();

			// Liquid view
			createTexturesLiquidView();

			// Bubbles movie
			createTextureBlobBubbles();

			// Brand logos
			createTextureBlobLogos();

			// Message textures
			createTextureMessages();

			// Custom
			// Custom: Brand liquid backgrounds
			createLoadedTexturesBackgrounds();

			// Custom: Flavor animations
			createLoadedTexturesFlavorAnimations();

			// Custom: Brand animations
			createLoadedTexturesBrandAnimations();

			// Custom: Menu sequence animations
			createLoadedTexturesMenuSequenceAnimations();

            //Load and create the texture for the aquafina thanks logo
            createAquafinaThanksTexture();

            //Load the authorization pending texture
            createAuthorizePendingTexture();


            dispatchEvent(new Event(EVENT_PROGRESS));

			// Start loading custom textures
			loadNextTextureCustom();
		}

		public function dispose():void {
			_textureNoise.dispose();
			_textureNoise = null;

			_textureBlobParticles.dispose();
			_textureBlobParticles = null;

			_textureBlobGradients.dispose();
			_textureBlobGradients = null;
			_textureBlobGradientsBitmap.dispose();
			_textureBlobGradientsBitmap = null;

			_textureBlobStrokes.dispose();
			_textureBlobStrokes = null;

			_textureBlobFocus.dispose();
			_textureBlobFocus = null;

			_textureLiquidBlob.dispose();
			_textureLiquidBlob = null;

			_textureLiquidStroke.dispose();
			_textureLiquidStroke = null;

			_textureBlobLogos.dispose();
			_textureBlobLogos = null;
			_textureBlobLogosBig.dispose();
			_textureBlobLogosBig = null;
			_textureBlobLogosSponsors.dispose();
			_textureBlobLogosSponsors = null;

			_textureBlobLogosBitmap.dispose();
			_textureBlobLogosBitmap = null;
			_textureBlobLogosBigBitmap.dispose();
			_textureBlobLogosBigBitmap = null;
			_textureBlobLogosSponsorsBitmap.dispose();
			_textureBlobLogosSponsorsBitmap = null;

			var texture:TextureLoader;
			for (var iis:String in _customTextureLoaders) {
				texture = _customTextureLoaders[iis];
				texture.dispose();
			}
			_customTextureLoaders = null;
		}

//		public function resetGradientTexture():void {
//			_textureBlobGradientsBitmap.reset();
//		}
//
//		public function resetLogosTexture():void {
//			_textureBlobLogosBitmap.reset();
//		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

        public function getAquafinaLogoThanks() : Texture {
            return _textureAquafinaLogoThanks
        }

        public function getAuthorizationPending() : Texture {
            return _textureAuthorizePending
        }

		public function get debug_textureBlobStroke():Texture {
			return _textureBlobStrokes;
		}

		public function getNoiseTexture():Texture {
			return _textureNoise;
		}

		public function getBlobGradientTexture(__id:String):Texture {
			var tileIndex:int = _textureBlobGradientsBitmap.getTileIndex(__id);
			var rect:Rectangle = TiledBitmapData.getTileRectangle(_textureBlobGradients.width, _textureBlobGradients.height, _blobGradientTextureResolution, tileIndex);
			return Texture.fromTexture(_textureBlobGradients, rect);
		}

		public function getBlobLogoTexture(__url:String):Texture {
			var tileIndex:int;
			if (_textureBlobLogosBitmap != null && _textureBlobLogosBitmap.hasTile(__url)) {
				// Normal tile
				tileIndex = _textureBlobLogosBitmap.getTileIndex(__url);
				return Texture.fromTexture(_textureBlobLogos, TiledBitmapData.getTileRectangle(_textureBlobLogos.width, _textureBlobLogos.height, _blobLogoTextureResolution, tileIndex));
			} else if (_textureBlobLogosBigBitmap != null && _textureBlobLogosBigBitmap.hasTile(__url)) {
				// Not found in normal logo tile set, use the big one
				tileIndex = _textureBlobLogosBigBitmap.getTileIndex(__url);
				return Texture.fromTexture(_textureBlobLogosBig, TiledBitmapData.getTileRectangle(_textureBlobLogosBig.width, _textureBlobLogosBig.height, _blobLogoBigTextureResolution, tileIndex));
			} else {
				// Not found in normal or big logo tile set, use sponsors one
				tileIndex = _textureBlobLogosSponsorsBitmap.getTileIndex(__url);
				return Texture.fromTexture(_textureBlobLogosSponsors, TiledBitmapData.getTileRectangle(_textureBlobLogosSponsors.width, _textureBlobLogosSponsors.height, _blobLogoSponsorsTextureResolution, tileIndex));
			}
		}

		public function getBlobLogoRectangle(__url:String):Rectangle {
			return getBlobLogoTiledBitmapContainer(__url).getImageRect(__url);
		}

		public function getBlobLogoRectangleUsed(__url:String, __validWidthPercentage:Number = 1, __validHeightPercentage:Number = 1):Rectangle {
			// Return a rectangle with the area of the logo that is actually being used (that is, non transparent). This is useful when aligning elements with the logo (kerning style)
			// The rectangle returned is INSIDE the logo rectangle area

			var rectangleCacheId:String = __url + "_" + __validWidthPercentage + "_" + __validHeightPercentage;

			if (!_textureBlobLogosBitmapRectanglesCache.hasOwnProperty(rectangleCacheId)) {
				// Not found in the cache, need to create first
				var targetBitmap:ImageLoaderTiledBitmap = getBlobLogoTiledBitmapContainer(__url);
				var tileIndex:int = targetBitmap.getTileIndex(__url);

				// Find tile area
				var tileRect:Rectangle = targetBitmap.getTileRect(tileIndex);

				// Find logo area in tile
				var logoRect:Rectangle = targetBitmap.getImageRectInTile(tileIndex);

				var desiredRect:Rectangle = new Rectangle(
					logoRect.x + Math.round(logoRect.width * (1-__validWidthPercentage) * 0.5),
					logoRect.y + Math.round(logoRect.height * (1-__validHeightPercentage) * 0.5),
					Math.round(logoRect.width * __validWidthPercentage),
					Math.round(logoRect.height * __validHeightPercentage)
				);

				// Create temporary bitmap with just the logo
				var bmp:BitmapData = new BitmapData(desiredRect.width, desiredRect.height, true, 0x00000000);
				bmp.copyPixels(targetBitmap, tileRect, new Point(- desiredRect.x, - desiredRect.y));

				// Find actual useful area in tile
				var usedRect:Rectangle = bmp.getColorBoundsRect(0xff000000, 0x00000000, false);
				//log("original = " + bmp.rect + ", crop = " + usedRect);

				// To test
//				AppUtils.getStage().addChild(new Bitmap(bmp));
//				bmp.fillRect(new Rectangle(0, 0, bmp.width, 1), 0x99ff0000);
//				bmp.fillRect(new Rectangle(0, bmp.height-1, bmp.width, 1), 0x99ff0000);
//				bmp.fillRect(new Rectangle(usedRect.x, usedRect.y, usedRect.width, 1), 0x990000ff);
//				bmp.fillRect(new Rectangle(usedRect.x, usedRect.y + usedRect.height-1, usedRect.width, 1), 0x990000ff);

				usedRect.x += desiredRect.x - logoRect.x;
				usedRect.y += desiredRect.y - logoRect.y;

				bmp.dispose();
				bmp = null;

				_textureBlobLogosBitmapRectanglesCache[rectangleCacheId] = usedRect;
			}

			return _textureBlobLogosBitmapRectanglesCache[rectangleCacheId] as Rectangle;
		}

		public function getBlobStrokeTexture():Texture {
			var tileIndex:int = Math.floor(Math.random() * UNIQUE_BLOB_STROKE_TEXTURES);
			var rect:Rectangle = TiledBitmapData.getTileRectangle(_textureBlobStrokes.width, _textureBlobStrokes.height, _blobStrokeTextureResolution, tileIndex);
			return Texture.fromTexture(_textureBlobStrokes, rect);
		}

		public function getBlobFocusTexture():Texture {
			var tileIndex:int = Math.floor(Math.random() * UNIQUE_BLOB_FOCUS_TEXTURES);
			var rect:Rectangle = TiledBitmapData.getTileRectangle(_textureBlobFocus.width, _textureBlobFocus.height, _blobFocusTextureResolution, tileIndex);
			return Texture.fromTexture(_textureBlobFocus, rect);
		}

		public function getBlobBubblesTexture():Texture {
			return getLoadedTexture(_animationDefinitionBlobBubbles.image);
		}

		public function getBlobBubblesAnimationDefinition():AnimationDefinition {
			return _animationDefinitionBlobBubbles;
		}

		public function getLiquidBlob():Texture {
			return _textureLiquidBlob;
		}

		public function getLiquidStroke():Texture {
			return _textureLiquidStroke;
		}

		public function getBlobParticlesTexture():Texture {
			var tileIndex:int = Math.floor(Math.random() * UNIQUE_BLOB_PARTICLE_TEXTURES);
			var rect:Rectangle = TiledBitmapData.getTileRectangle(_textureBlobParticles.width, _textureBlobParticles.height, _blobParticleTextureResolution, tileIndex);
			return Texture.fromTexture(_textureBlobParticles, rect);
		}

		public function hasLoadedTexture(__id:String):Boolean {
			return _customTextureLoaders.hasOwnProperty(__id);
		}

		public function getLoadedTexture(__id:String):Texture {
			var texture:TextureLoader = _customTextureLoaders[__id];
			if (texture != null) return texture.getTexture();
			error("Error! Trying to get a custom texture [" + __id + "] that doesn't exist!");
			return null;
		}

		public function getMessageUnavailableTitleTexture(): Vector.<Texture> {
			return _textureBlobMessageUnavailableTitle;
		}

        public function getMessagePayment() : Vector.<Texture> {
            return _textureBlobMessagePayment;
        }

		public function getMessageUnavailableSubtitleTexture():Vector.<Texture> {
			return _textureBlobMessageUnavailableSubtitle;
		}

		public function get blobBubbleTextureResolution():int {
			return _blobBubbleTextureResolution;
		}

		public function get blobParticleTextureResolution():int {
			return _blobParticleTextureResolution;
		}

		public function get blobStrokeTextureResolution():int {
			return _blobStrokeTextureResolution;
		}

		public function get blobGradientTextureResolution():int {
			return _blobGradientTextureResolution;
		}

		/*
		public function get blobLogoTextureResolution():int {
			return _blobLogoTextureResolution;
		}
		*/

		public function getBlobLogoTextureResolution(__isBig:Boolean):int {
			return __isBig ? _blobLogoBigTextureResolution : _blobLogoTextureResolution;
		}

		public function getBlobLogoSponsorTextureResolution():int {
			return _blobLogoSponsorsTextureResolution;
		}

		/*
		public function isLogoBig(__url:String):Boolean {
			// This might be needed in the future?
		}
		*/

		public function getReadyPhase():Number {
			// 0-1 of percentage of loading/ready phase

			if (!inited) return 0;
			if (finished) return 1;

			// Count custom textures
			var val:Number = 0;
			var texturesLoaded:int = 0;
			var texturesTotal:int = 0;
			for (var iis:String in _customTextureLoaders) {
				texturesTotal++;
				if ((_customTextureLoaders[iis] as TextureLoader).isLoaded()) texturesLoaded++;
			}

			val += 0.6 * (texturesLoaded/texturesTotal);
			val += 0.15 * (_textureBlobLogosBitmap == null ? 1 : _textureBlobLogosBitmap.getLoadingPhase());
			val += 0.05 * (_textureBlobLogosBigBitmap == null ? 1 : _textureBlobLogosBigBitmap.getLoadingPhase());
			val += 0.05 * (_textureBlobLogosSponsorsBitmap == null ? 1 : _textureBlobLogosSponsorsBitmap.getLoadingPhase());
			val += 0.15 * (_textureBlobGradientsBitmap == null ? 1: _textureBlobGradientsBitmap.getLoadingPhase());

			return val;
		}
	}
}
