package com.firstborn.pepsi.data {
	import com.firstborn.pepsi.display.gpu.brand.view.BrandViewOptions;
	import com.firstborn.pepsi.display.gpu.home.view.HomeViewOptions;
	import com.zehfernando.utils.XMLUtils;
	import com.zehfernando.utils.console.error;

	import flash.display3D.Context3DProfile;
	import flash.geom.Point;
	/**
	 * @author zeh fernando
	 */
	public class PlatformProfile {
		// Arbitrary information about the platform, coming from external data

		// Constants

		// Ids for views ("recipes" for creating each view)
		public static const VIEW_PROFILE_HOME:String = "home";
		public static const VIEW_PROFILE_HOME_ADA:String = "home-ada";
		public static const VIEW_PROFILE_BRAND:String = "brand";
		public static const VIEW_PROFILE_BRAND_ADA:String = "brand-ada";

		// Properties
		public var id:String;					// E.g., "tower" or "bridge"
		public var attributeIdOverride:String;	// Allows a different id to be accepted when querying the beverages list for design parameters

		public var width:int;					// Expected width
		public var height:int;					// Expected height
		public var serviceUIScale:Number;

		public var scaleX:Number;
		public var scaleY:Number;

		public var frameRate:int;

		public var softwareADAMessageY:Number;
		public var automaticADAActivation:Boolean;
		public var softwareADAAllowsKeyboardFocus:Boolean;
		public var softwareADAAlwaysShowsFocus:Boolean;

		public var mastheadHeight:int;			// Height taken by masthead video on top of screen

		public var gpuProfile:String;
		public var gpuAntiAliasing:int;

		public var gpuTextureMaximumDimensions:int;
		public var gpuTextureDensity:Number;

		public var supportsLightsAPI:Boolean;

		public var textures:Vector.<TextureProfile>;
		public var viewOptions:Vector.<ViewOptionsProfile>;

		public var maskViewportCompensationY:int;	// This shouldn't be needed, but just so it looks right when testing because it's apparently cropping to the viewport

        public var scanHardwarePosition : Number;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function PlatformProfile() {
			// Set defaults
			id = "";
			attributeIdOverride = "";
			width = 100;
			height = 100;
			serviceUIScale = 1;
			scaleX = 1;
			scaleY = 1;
			frameRate = 30;
			softwareADAMessageY = 0.5;
			automaticADAActivation = true;
			softwareADAAllowsKeyboardFocus = true;
			softwareADAAlwaysShowsFocus = true;
			mastheadHeight = 0;
			gpuProfile = Context3DProfile.BASELINE;
			gpuAntiAliasing = 0;
			gpuTextureMaximumDimensions = 2048;
			gpuTextureDensity = 1;
			supportsLightsAPI = true;
			maskViewportCompensationY = 0;

            //Position for the hardware scan in the unattended machine, centered by default
            scanHardwarePosition = 0.5;

			textures = new Vector.<TextureProfile>();
			viewOptions = new Vector.<ViewOptionsProfile>();
		}


		// ================================================================================================================
		// STATIC INTERFACE -----------------------------------------------------------------------------------------------

		public static function fromXMLList(__xmlList:XMLList, __id:String):PlatformProfile {
			var profileXML:XML;
			var newProfile:PlatformProfile;

			var i:int, j:int, k:int;
			for (i = 0; i < __xmlList.length(); i++) {
				profileXML = __xmlList[i];

				if (XMLUtils.getAttributeAsString(profileXML, "id") == __id) {
					var baseId:String = XMLUtils.getAttributeAsString(profileXML, "base");
					if (baseId != "") {
						// Use other as a base
						newProfile = fromXMLList(__xmlList, baseId);
					} else {
						// New profile
						newProfile = new PlatformProfile();
					}

					newProfile.id								= XMLUtils.getAttributeAsString(profileXML,	"id",								newProfile.id);
					newProfile.attributeIdOverride				= XMLUtils.getNodeAsString(profileXML,		"attributeIdOverride",				newProfile.attributeIdOverride);
					newProfile.width							= XMLUtils.getNodeAsInt(profileXML,			"width",							newProfile.width);
					newProfile.height							= XMLUtils.getNodeAsInt(profileXML,			"height",							newProfile.height);
					newProfile.serviceUIScale					= XMLUtils.getNodeAsFloat(profileXML,		"serviceUIScale",					newProfile.serviceUIScale);
					newProfile.scaleX							= XMLUtils.getNodeAsFloat(profileXML,		"scaleX",							newProfile.scaleX);
					newProfile.scaleY							= XMLUtils.getNodeAsFloat(profileXML,		"scaleY",							newProfile.scaleY);
					newProfile.frameRate						= XMLUtils.getNodeAsInt(profileXML,			"frameRate",						newProfile.frameRate);
					newProfile.softwareADAMessageY				= XMLUtils.getNodeAsFloat(profileXML,		"softwareADAMessageY",				newProfile.softwareADAMessageY);
					newProfile.automaticADAActivation			= XMLUtils.getNodeAsBoolean(profileXML,		"automaticADAActivation",			newProfile.automaticADAActivation);
					newProfile.softwareADAAllowsKeyboardFocus	= XMLUtils.getNodeAsBoolean(profileXML,		"softwareADAAllowsKeyboardFocus",	newProfile.softwareADAAllowsKeyboardFocus);
					newProfile.softwareADAAlwaysShowsFocus		= XMLUtils.getNodeAsBoolean(profileXML,		"softwareADAAlwaysShowsFocus",		newProfile.softwareADAAlwaysShowsFocus);
					newProfile.mastheadHeight					= XMLUtils.getNodeAsInt(profileXML,			"mastheadHeight",					newProfile.mastheadHeight);
					newProfile.gpuProfile						= XMLUtils.getNodeAsString(profileXML,		"gpuProfile",						newProfile.gpuProfile);
					newProfile.gpuAntiAliasing					= XMLUtils.getNodeAsInt(profileXML,			"gpuAntiAliasing",					newProfile.gpuAntiAliasing);

					newProfile.gpuTextureMaximumDimensions		= XMLUtils.getNodeAsInt(profileXML,			"gpuTextureMaximumDimensions",		newProfile.gpuTextureMaximumDimensions);
					newProfile.gpuTextureDensity				= XMLUtils.getNodeAsFloat(profileXML,		"gpuTextureDensity",				newProfile.gpuTextureDensity);
					newProfile.supportsLightsAPI				= XMLUtils.getNodeAsBoolean(profileXML,		"supportsLightsAPI",				newProfile.supportsLightsAPI);
					newProfile.maskViewportCompensationY		= XMLUtils.getNodeAsInt(profileXML,			"maskViewportCompensationY",		newProfile.maskViewportCompensationY);
					newProfile.scanHardwarePosition		        = XMLUtils.getNodeAsFloat(profileXML,       "leftToRightScanPosition",		    newProfile.scanHardwarePosition);


					if (XMLUtils.hasNode(profileXML, "textures")) {
						var newTextures:Vector.<TextureProfile> = TextureProfile.fromXMLList((profileXML.child("textures")[0] as XML).children());
						// Add to the old one, replacing names

						for (j = 0; j < newTextures.length; j++) {
							for (k = 0; k < newProfile.textures.length; k++) {
								if (newProfile.textures[k].id == newTextures[j].id) {
									// Already featured; remove this one
									newProfile.textures.splice(k, 1);
									k--;
								}
							}
							// Add the new one
							newProfile.textures.push(newTextures[j]);
						}
					}

					if (XMLUtils.hasNode(profileXML, "views")) {
						var newViews:Vector.<ViewOptionsProfile> = ViewOptionsProfile.fromXMLList((profileXML.child("views")[0] as XML).children());
						// Add to the old one, replacing names

						for (j = 0; j < newViews.length; j++) {
							for (k = 0; k < newProfile.viewOptions.length; k++) {
								if (newProfile.viewOptions[k].id == newViews[j].id) {
									// Already featured; remove this one
									newProfile.viewOptions.splice(k, 1);
									k--;
								}
							}
							// Add the new one
							newProfile.viewOptions.push(newViews[j]);
						}
					}

					return newProfile;
				}
			}
			return null;
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get heightMinusMasthead():Number {
			return height - mastheadHeight;
		}

		public function getTextureProfile(__id:String):TextureProfile {
			for (var i:int = 0; i < textures.length; i++) {
				if (textures[i].id == __id) return textures[i];
			}
			error("Texture profile with id [" + __id + "] not found!");
			return null;
		}

		public function getHomeViewOptions(__id:String):HomeViewOptions {
			for (var i:int = 0; i < viewOptions.length; i++) {
				if (viewOptions[i].id == __id) return HomeViewOptions.fromViewOptions(viewOptions[i], this);
			}
			error("View profile with id [" + __id + "] not found!");
			return null;
		}

		public function getBrandViewOptions(__id:String):BrandViewOptions {
			for (var i:int = 0; i < viewOptions.length; i++) {
				if (viewOptions[i].id == __id) return BrandViewOptions.fromViewOptions(viewOptions[i], this);
			}
			error("View profile with id [" + __id + "] not found!");
			return null;
		}

		public function get widthScaled():int {
			return Math.round(width * scaleX);
		}

		public function get heightScaled():int {
			return Math.round(height * scaleY);
		}

		public function get mastheadHeightScaled():int {
			return Math.round(mastheadHeight * scaleY);
		}

		public function get idWithOverride():String {
			// Returns the id that should be used for attribute querying, which is the normal id unless there's an "override", in which case the override is used
			return (attributeIdOverride != null && attributeIdOverride.length > 0) ? attributeIdOverride : id;
		}

		public function getScaledPoint(__point:Point):Point {
			return new Point(__point.x * scaleX, __point.y * scaleY);
		}

		public function getUnscaledPoint(__point:Point):Point {
			return new Point(__point.x / scaleX, __point.y / scaleY);
		}
	}
}