package com.firstborn.pepsi.data.inventory {
	import com.firstborn.pepsi.application.FountainFamily;
import com.firstborn.pepsi.common.backend.BackendModel;
import com.zehfernando.data.types.Color;
	import com.zehfernando.utils.VectorUtils;
	import com.zehfernando.utils.XMLUtils;
	import com.zehfernando.utils.console.warn;
	/**
	 * @author zeh fernando
	 */
	public class BeverageDesign {

		// Constants
		public static const MIX_LAYOUT_SUPERBOWL:String = "superbowl";
		public static const MIX_LAYOUT_KFC:String = "kfc";

		// Properties
		public var colorStroke:uint;
		public var colorLight:uint;
		public var colorAnimationDark:uint;
		public var colorAnimationLight:uint;
		private var _colorAnimationDarkInstance:Color;
		private var _colorAnimationLightInstance:Color;
		public var colorMessageTitle:uint;
		public var colorMessageSubtitle:uint;
		private var _colorMessageTitleInstance:Color;
		private var _colorMessageSubtitleInstance:Color;
		public var imageLogo:String;
		public var imageLogoIsBig:Boolean;
		public var scaleLogo:Number;
		public var imageGradient:String;
		public var particlesHome:Vector.<ParticleDefinition>;
		public var particlesBrand:Vector.<ParticleDefinition>;

		public var alphaCarbonation:Number;

		public var imageLogoBrand:String;
		public var imageLogoBrandIsBig:Boolean;
		public var scaleLogoBrand:Number;
		public var imageLogoRecipe:String;
		public var imageLogoRecipeIsBig:Boolean;
		public var scaleLogoRecipe:Number;
		public var imageLogoFlavorSponsor:String;
		public var mixLayout:String;
		public var colorStrokeBrand:uint;
		public var colorTextNormalBrand:uint;
		public var colorTextStrongBrand:uint;
		public var colorPourStroke:Vector.<uint>;
		public var colorPourFill:Vector.<uint>;
		public var scalePour:Vector.<Number>;
		public var colorButtonsText:uint;
		public var colorButtonsStroke:uint;
		public var colorButtonsFill:uint;

		public var imageLiquidBackground:String;
		public var noiseLiquidBackground:Number;
		public var videoLiquidIntro:String;
		public var videoLiquidIdle:String;

		public var animationId:String;
		public var animationOffsetX:Number;
		public var animationOffsetY:Number;
		public var animationScale:Number;
		public var animationAlpha:Number;

		public var particlesPerSecond:Number;
		public var particlesSizeScale:Number;
		public var particlesSpeedScale:Number;

        //For the calories text color
        public var caloriesColor : uint;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function BeverageDesign() {
			// Set defaults
			colorStroke = 0xff000000;
			colorLight = 0xff000000;
			colorAnimationDark = 0x000000;
			colorAnimationLight = 0x000000;
			colorMessageTitle = 0x99ffffff;
			colorMessageSubtitle = 0x99000000;
			imageLogo = "";
			imageLogoIsBig = false;
			scaleLogo = 1;
			imageGradient = "";
			particlesHome = new Vector.<ParticleDefinition>();
			particlesBrand = new Vector.<ParticleDefinition>();

			imageLogoBrand = "";
			imageLogoBrandIsBig = false;
			scaleLogoBrand = 1;
			imageLogoRecipe = "";
			imageLogoRecipeIsBig = false;
			scaleLogoRecipe = 1;
			imageLogoFlavorSponsor = "";
			mixLayout = "";
			colorStrokeBrand = 0xff000000;
			colorTextNormalBrand = 0xff000000;
			colorTextStrongBrand = 0xff000000;
			colorPourStroke = new <uint>[0xff000000];
			colorPourFill = new <uint>[0xff000000];
			scalePour = new <Number>[1];
			colorButtonsText = 0xff000000;
			colorButtonsStroke = 0xff000000;
			colorButtonsFill = 0xff000000;

			imageLiquidBackground = "";
			noiseLiquidBackground = 0;
			videoLiquidIntro = "";
			videoLiquidIdle = "";

			animationId = "";
			animationOffsetX = 0;
			animationOffsetY = 0;
			animationScale = 1;
			animationAlpha = 1;

			particlesPerSecond = 0;
			particlesSizeScale = 1;
			particlesSpeedScale = 1;
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private static function getUintFromColorString(__color:String, __default:uint):uint {
			// Converts a "#aarrggbb" color string to an uint, with uint defaults
			if (__color == null || __color.length == 0) return __default;
			return Color.fromString(__color).toAARRGGBB();
		}

		private static function getNumberVectorFromNumberListString(__list:String, __default:Vector.<Number>):Vector.<Number> {
			if (__list == null || __list.length == 0) return __default;
			var list:Vector.<String> = VectorUtils.stringToStringVector(__list, ",", true);
			var numbers:Vector.<Number> = new Vector.<Number>();
			for (var i:int = 0; i < list.length; i++) {
				numbers.push(parseFloat(list[i]));
			}
			return numbers;
		}

		private static function getUintVectorFromColorListString(__list:String, __default:Vector.<uint>):Vector.<uint> {
			// Converts a color list as a comma-separated string into a uint vector
			// E.g. "#ff000000,#ff82ef11"
			if (__list == null || __list.length == 0) return __default;
			var list:Vector.<String> = VectorUtils.stringToStringVector(__list, ",", true);
			var colors:Vector.<uint> = new Vector.<uint>();
			for (var i:int = 0; i < list.length; i++) {
				colors.push(Color.fromString(list[i]).toAARRGGBB());
			}
			return colors;
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function getParticleColor(__partricleList:Vector.<ParticleDefinition>):Color {
			// Select a particle color

			var i:int;
			var totalWeight:Number = 0;
			for (i = 0; i < __partricleList.length; i++) {
				totalWeight += __partricleList[i].frequency;
			}

			var randomNumber:Number = totalWeight * Math.random();
			totalWeight = 0;
			for (i = 0; i < __partricleList.length; i++) {
				totalWeight += __partricleList[i].frequency;
				if (totalWeight >= randomNumber) return __partricleList[i].fullColor;
			}

			warn("Could not pick a color!!");

			return Color.fromRRGGBB(0xff000000);
		}

		public static function fromXML(__xmlData:XML, __platformsIdsAllowed:Vector.<String>, __adaFilter:Boolean, __isTemplate:Boolean = false, __base:BeverageDesign = null):BeverageDesign {

			// ADA is more important, so it's first
			var filterNames:Array = [FountainFamily.FILTER_ATTRIBUTE_XML_ADA, FountainFamily.FILTER_ATTRIBUTE_XML_PLATFORMS];
			var filterValues:Array = [__adaFilter ? FountainFamily.FILTER_ATTRIBUTE_XML_ADA_TRUE : FountainFamily.FILTER_ATTRIBUTE_XML_ADA_FALSE, __platformsIdsAllowed];

			var beverageDesign:BeverageDesign = __base == null ? new BeverageDesign() : __base;

			beverageDesign.colorStroke					= getUintFromColorString(XMLUtils.getFilteredNodeAsString(__xmlData, "colorStroke", filterNames, filterValues), beverageDesign.colorStroke);

            var xmlLight :XML = XML(XMLUtils.getFilteredNodeAsString(__xmlData, "colorLight", filterNames, filterValues));

            //This allows to read the previous version of the beverages.
            var lightColor : String = String(xmlLight.colorShade.(@id == BackendModel.lightihgHardware)) || String(xmlLight.colorShade[0]);
            if(lightColor != "undefined" && lightColor != "") beverageDesign.colorLight = getUintFromColorString(lightColor, beverageDesign.colorLight);
            if(lightColor == "undefined") beverageDesign.colorLight = getUintFromColorString(xmlLight, beverageDesign.colorLight);


            if (beverageDesign.colorLight == 0xff000000 && !__isTemplate) {
				warn("Found an empty color for light: using stroke color of #" + beverageDesign.colorStroke.toString(16));
				beverageDesign.colorLight = beverageDesign.colorStroke;
			}

			beverageDesign.colorAnimationDark			= getUintFromColorString(XMLUtils.getFilteredNodeAsString(__xmlData, "colorAnimationDark", filterNames, filterValues), beverageDesign.colorAnimationDark);
			beverageDesign.colorAnimationLight			= getUintFromColorString(XMLUtils.getFilteredNodeAsString(__xmlData, "colorAnimationLight", filterNames, filterValues), beverageDesign.colorAnimationLight);
			beverageDesign.colorMessageTitle			= getUintFromColorString(XMLUtils.getFilteredNodeAsString(__xmlData, "colorMessageTitle", filterNames, filterValues), beverageDesign.colorMessageTitle);
			beverageDesign.colorMessageSubtitle			= getUintFromColorString(XMLUtils.getFilteredNodeAsString(__xmlData, "colorMessageSubtitle", filterNames, filterValues), beverageDesign.colorMessageSubtitle);
			beverageDesign.imageLogo					= XMLUtils.getFilteredNodeAsString(__xmlData, "imageLogo", filterNames, filterValues, true, true, beverageDesign.imageLogo);
			beverageDesign.imageLogoIsBig				= XMLUtils.getFilteredNodeAsBoolean(__xmlData, "imageLogoIsBig", filterNames, filterValues, true, true, beverageDesign.imageLogoIsBig);
			beverageDesign.scaleLogo					= XMLUtils.getFilteredNodeAsFloat(__xmlData, "scaleLogo", filterNames, filterValues, true, true, beverageDesign.scaleLogo);
			beverageDesign.imageGradient				= XMLUtils.getFilteredNodeAsString(__xmlData, "imageGradient", filterNames, filterValues, true, true, beverageDesign.imageGradient);

			if (XMLUtils.hasNode(__xmlData, "particlesBrand")) beverageDesign.particlesBrand	= ParticleDefinition.fromXMLList((__xmlData.child("particlesBrand")[0] as XML).child("particle"), __platformsIdsAllowed);
			if (XMLUtils.hasNode(__xmlData, "particlesHome")) beverageDesign.particlesHome		= ParticleDefinition.fromXMLList((__xmlData.child("particlesHome")[0] as XML).child("particle"), __platformsIdsAllowed);

			beverageDesign.alphaCarbonation				= XMLUtils.getFilteredNodeAsFloat(__xmlData, "alphaCarbonation", filterNames, filterValues, true, true, beverageDesign.alphaCarbonation);

			// Brand page
			beverageDesign.imageLogoBrand				= XMLUtils.getFilteredNodeAsString(__xmlData, "imageLogoBrand", filterNames, filterValues, true, true, beverageDesign.imageLogoBrand);
			beverageDesign.imageLogoBrandIsBig			= XMLUtils.getFilteredNodeAsBoolean(__xmlData, "imageLogoBrandIsBig", filterNames, filterValues, true, true, beverageDesign.imageLogoBrandIsBig);
			beverageDesign.scaleLogoBrand				= XMLUtils.getFilteredNodeAsFloat(__xmlData, "scaleLogoBrand", filterNames, filterValues, true, true, beverageDesign.scaleLogoBrand);
			beverageDesign.imageLogoRecipe				= XMLUtils.getFilteredNodeAsString(__xmlData, "imageLogoRecipe", filterNames, filterValues, true, true, beverageDesign.imageLogoRecipe);
			beverageDesign.imageLogoRecipeIsBig			= XMLUtils.getFilteredNodeAsBoolean(__xmlData, "imageLogoRecipeIsBig", filterNames, filterValues, true, true, beverageDesign.imageLogoRecipeIsBig);
			beverageDesign.scaleLogoRecipe				= XMLUtils.getFilteredNodeAsFloat(__xmlData, "scaleLogoRecipe", filterNames, filterValues, true, true, beverageDesign.scaleLogoRecipe);
			beverageDesign.imageLogoFlavorSponsor		= XMLUtils.getFilteredNodeAsString(__xmlData, "imageLogoFlavorSponsor", filterNames, filterValues, true, true, beverageDesign.imageLogoFlavorSponsor);
			beverageDesign.mixLayout					= XMLUtils.getFilteredNodeAsString(__xmlData, "mixLayout", filterNames, filterValues, true, true, beverageDesign.mixLayout);
			beverageDesign.colorStrokeBrand				= getUintFromColorString(XMLUtils.getFilteredNodeAsString(__xmlData, "colorStrokeBrand", filterNames, filterValues), beverageDesign.colorStrokeBrand);
			beverageDesign.colorTextNormalBrand			= getUintFromColorString(XMLUtils.getFilteredNodeAsString(__xmlData, "colorTextNormalBrand", filterNames, filterValues), beverageDesign.colorTextNormalBrand);
			beverageDesign.colorTextStrongBrand			= getUintFromColorString(XMLUtils.getFilteredNodeAsString(__xmlData, "colorTextStrongBrand", filterNames, filterValues), beverageDesign.colorTextStrongBrand);
			beverageDesign.colorPourStroke				= getUintVectorFromColorListString(XMLUtils.getFilteredNodeAsString(__xmlData, "colorPourStroke", filterNames, filterValues), beverageDesign.colorPourStroke);
			beverageDesign.colorPourFill				= getUintVectorFromColorListString(XMLUtils.getFilteredNodeAsString(__xmlData, "colorPourFill", filterNames, filterValues), beverageDesign.colorPourFill);
			beverageDesign.scalePour					= getNumberVectorFromNumberListString(XMLUtils.getFilteredNodeAsString(__xmlData, "scalePour", filterNames, filterValues), beverageDesign.scalePour);
			beverageDesign.colorButtonsText				= getUintFromColorString(XMLUtils.getFilteredNodeAsString(__xmlData, "colorButtonsText", filterNames, filterValues), beverageDesign.colorButtonsText);
			beverageDesign.colorButtonsStroke			= getUintFromColorString(XMLUtils.getFilteredNodeAsString(__xmlData, "colorButtonsStroke", filterNames, filterValues), beverageDesign.colorButtonsStroke);
			beverageDesign.colorButtonsFill				= getUintFromColorString(XMLUtils.getFilteredNodeAsString(__xmlData, "colorButtonsFill", filterNames, filterValues), beverageDesign.colorButtonsFill);

			beverageDesign.imageLiquidBackground		= XMLUtils.getFilteredNodeAsString(__xmlData, "imageLiquidBackground", filterNames, filterValues, true, true, beverageDesign.imageLiquidBackground);
			beverageDesign.noiseLiquidBackground		= XMLUtils.getFilteredNodeAsFloat(__xmlData, "noiseLiquidBackground", filterNames, filterValues, true, true, beverageDesign.noiseLiquidBackground);
			beverageDesign.videoLiquidIntro				= XMLUtils.getFilteredNodeAsString(__xmlData, "videoLiquidIntro", filterNames, filterValues, true, true, beverageDesign.videoLiquidIntro);
			beverageDesign.videoLiquidIdle				= XMLUtils.getFilteredNodeAsString(__xmlData, "videoLiquidIdle", filterNames, filterValues, true, true, beverageDesign.videoLiquidIdle);

			beverageDesign.animationId					= XMLUtils.getFilteredNodeAsString(__xmlData, "animationId", filterNames, filterValues, true, true, beverageDesign.animationId);
			beverageDesign.animationOffsetX				= XMLUtils.getFilteredNodeAsFloat(__xmlData, "animationOffsetX", filterNames, filterValues, true, true, beverageDesign.animationOffsetX);
			beverageDesign.animationOffsetY				= XMLUtils.getFilteredNodeAsFloat(__xmlData, "animationOffsetY", filterNames, filterValues, true, true, beverageDesign.animationOffsetY);
			beverageDesign.animationScale				= XMLUtils.getFilteredNodeAsFloat(__xmlData, "animationScale", filterNames, filterValues, true, true, beverageDesign.animationScale);
			beverageDesign.animationAlpha				= XMLUtils.getFilteredNodeAsFloat(__xmlData, "animationAlpha", filterNames, filterValues, true, true, beverageDesign.animationAlpha);

			beverageDesign.particlesPerSecond			= XMLUtils.getFilteredNodeAsFloat(__xmlData, "particlesPerSecond", filterNames, filterValues, true, true, beverageDesign.particlesPerSecond);
			beverageDesign.particlesSizeScale			= XMLUtils.getFilteredNodeAsFloat(__xmlData, "particlesSizeScale", filterNames, filterValues, true, true, beverageDesign.particlesSizeScale);
			beverageDesign.particlesSpeedScale			= XMLUtils.getFilteredNodeAsFloat(__xmlData, "particlesSpeedScale", filterNames, filterValues, true, true, beverageDesign.particlesSpeedScale);

            //For the color of the calories text
            beverageDesign.caloriesColor				= getUintFromColorString(XMLUtils.getFilteredNodeAsString(__xmlData, "caloriesColor", filterNames, filterValues), beverageDesign.caloriesColor);


            if (FountainFamily.DEBUG_BEVERAGES_USE_GENERIC_DATA) {
				// Forces the design to use some placeholder parameters
				beverageDesign.colorStroke = 0xff999999;
				beverageDesign.scaleLogoBrand = 1;
				beverageDesign.colorStrokeBrand = 0xff999999;
				beverageDesign.colorTextNormalBrand = beverageDesign.colorTextStrongBrand = 0x666666;
				beverageDesign.imageLogoBrand = beverageDesign.imageLogo;
//				beverageDesign.colorPourStroke = new <uint>[0x00000000, 0xff999999];
//				beverageDesign.colorPourFill = new <uint>[0x00000000, 0x33000000];
			}

			return beverageDesign;
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function getParticleBrandColor():Color {
			if (FountainFamily.DEBUG_BEVERAGES_USE_GENERIC_DATA) return Color.fromRRGGBB(0x33aaaaaa);
			return getParticleColor(particlesBrand);
		}

		public function getParticleHomeColor():Color {
			if (FountainFamily.DEBUG_BEVERAGES_USE_GENERIC_DATA) return Color.fromRRGGBB(0x33aaaaaa);
			return getParticleColor(particlesHome);
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get colorAnimationDarkInstance():Color {
			if (_colorAnimationDarkInstance == null) _colorAnimationDarkInstance = Color.fromRRGGBB(colorAnimationDark);
			return _colorAnimationDarkInstance;
		}

		public function get colorAnimationLightInstance():Color {
			if (_colorAnimationLightInstance == null) _colorAnimationLightInstance = Color.fromRRGGBB(colorAnimationLight);
			return _colorAnimationLightInstance;
		}

		public function get colorMessageTitleInstance():Color {
			if (_colorMessageTitleInstance == null) _colorMessageTitleInstance = Color.fromAARRGGBB(colorMessageTitle);
			return _colorMessageTitleInstance;
		}

		public function get colorMessageSubtitleInstance():Color {
			if (_colorMessageSubtitleInstance == null) _colorMessageSubtitleInstance = Color.fromAARRGGBB(colorMessageSubtitle);
			return _colorMessageSubtitleInstance;
		}
	}
}
