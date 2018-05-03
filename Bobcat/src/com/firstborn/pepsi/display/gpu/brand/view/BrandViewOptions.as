package com.firstborn.pepsi.display.gpu.brand.view {
	import com.firstborn.pepsi.data.PlatformProfile;
	import com.firstborn.pepsi.data.ViewOptionsProfile;
	import com.firstborn.pepsi.display.gpu.common.BlobButtonStyle;
	import com.firstborn.pepsi.display.gpu.common.components.BlobButton;
import com.firstborn.pepsi.display.gpu.home.view.HomeView;
import com.firstborn.pepsi.display.gpu.home.view.HomeViewOptions;

/**
	 * @author zeh fernando
	 */
	public class BrandViewOptions {
		// Options for creating a new configurable BrandView

		// Constants
		public static const LIQUID_LAYOUT_NONE:String = "none";
		public static const LIQUID_LAYOUT_BOTTOM:String = "bottom";
		public static const LIQUID_LAYOUT_RIGHT:String = "right";

		public static const LOGO_LAYOUT_LEFT:String = "left";
		public static const LOGO_LAYOUT_CENTER:String = "center";

		public static const ORIENTATION_HORIZONTAL:String = "horizontal";
		public static const ORIENTATION_VERTICAL:String = "vertical";

		public static const FONT_TYPE_REGULAR:String = "regular";
		public static const FONT_TYPE_LIGHT:String = "light";
		public static const FONT_TYPE_BOLD:String = "bold";

		public static const FLAVOR_MIX_ITEM_TYPE_FRUIT:String = "fruit";
		public static const FLAVOR_MIX_ITEM_TYPE_CAPTION:String = "caption";

		public static const FLAVOR_MIX_ITEM_ALIGNMENT_CENTER:String = "center";
		public static const FLAVOR_MIX_ITEM_ALIGNMENT_LEFT:String = "left";

		// Properties
		public var id:String;											// Just a quick unique id for identification
		public var width:int;
		public var height:int;
		public var isADA:Boolean;										// If true, assumes it's ADA (uses some different elements)
		public var allowKeyboardFocus:Boolean;							// Whether to use the focus controller (for hardware ADA support)
		public var liquidLayout:String;									// Enum from BrandViewOptions
		public var liquidOffsetX:Number;
		public var liquidOffsetY:Number;
		public var liquidPouredOffsetY:Number;							// How much it moves when 100% poured
		public var liquidParticles:Boolean;
		public var logoLayout:String;									// Enum from BrandViewOptions
		public var marginTitleFromTop:Number;
		public var marginTitleLeft:Number;
		public var marginTitleSecondLine:Number;
		public var marginLogoFromTitle:Number;
		public var marginLogoFromTopMix:MixDependentNumber;
		public var logoAlignY:MixDependentNumber;
		public var marginFlavorsFromTitle:Number;
		public var marginFlavorLeft:Number;
		public var marginFlavorIcon:Number;
		public var marginFlavorRight:Number;
		public var assumedWidthFruits:Number;
		public var marginFlavorMixFromLogo:MixDependentNumber;
		public var flavorMixOrientation:MixDependentString;				// Enum from BrandViewOptions
		public var flavorMixX:MixDependentNumber;
		public var flavorMixAlignY:MixDependentNumber;
		public var flavorMixScale:MixDependentNumber;
		public var flavorMixScaleLogo:MixDependentNumber;
		public var flavorMixScaleFruit:MixDependentNumber;
		public var flavorMixItemSpacing:MixDependentNumber;
		public var flavorMixItemType:MixDependentString;				// Enum
		public var flavorMixItemAlignment:MixDependentString;			// Enum
		public var fontSizeSponsorMix:MixDependentNumber;				// Font size for sponsor prefix, determines the logo size too
		public var fontSizeFlavorMix:MixDependentNumber;				// Font size for flavor name
		public var fontSizeFlavorGlueTopMix:MixDependentNumber;			// Font size for "glue" between title and flavor names ("+")
		public var fontSizeFlavorGlueMidMix:MixDependentNumber;			// Font size for "glue" between flavor names ("&" or mid-flavor "+")
		public var fontSizeTitle:Number;
		public var fontSizeTitleEmphasis:Number;
		public var titleInTwoLines:Boolean;
		public var fontSizeFlavor:Number;
		public var fontTrackingFlavor:Number;
		public var fontTypeMix:MixDependentString;
		public var numColsFlavor:int;
		public var scaleFruits:Number;
		public var invisibleFruitsRedistributesButtons:Boolean;
		public var heightFlavorItem:Number;
		public var marginFlavorItem:Number;
		public var buttonBackStyleId:String;							// Enum from BlobButton.STYLE_*
		public var buttonBackColorsNeutral:Boolean;						// If true, uses neutral colors (like home) for the back button
		public var buttonPourStyleId:String;							// Enum from BlobButton.STYLE_*
		public var trackId:String;										// What to track upon opening
		public var animationY:Number;
		public var animationPivotY:Number;

        //For the calories
        public var fontSizeFlavorCalories:Number;
        public var fontSizeCalories:String;
        public var marginCaloriesBottom:Number;
        public var marginCaloriesRight:Number;
        public var fontSizeCaloriesScale : Number;

        public var fontTypeFlavorCopy : String;                         //font type for the brand's flavors amount or type copy.

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function BrandViewOptions() {
			// Set defaults
			id = "";
			width = 0;
			height = 0;
			isADA = false;
			allowKeyboardFocus = false;
			liquidLayout = LIQUID_LAYOUT_NONE;
			liquidParticles = true;
			liquidOffsetX = 0;
			liquidOffsetY = 0;
			liquidPouredOffsetY = 380;
			logoLayout = LOGO_LAYOUT_CENTER;
			marginTitleFromTop = 0;
			marginTitleLeft = 0;
			marginTitleSecondLine = 0;
			marginLogoFromTitle = 0;
			marginLogoFromTopMix = new MixDependentNumber(0);
			logoAlignY = new MixDependentNumber(1);
			marginFlavorsFromTitle = 0;
			marginFlavorLeft = 0;
			marginFlavorIcon = 0;
			marginFlavorRight = 0;
			assumedWidthFruits = 0;
			marginFlavorMixFromLogo = new MixDependentNumber(0);
			flavorMixOrientation = new MixDependentString(ORIENTATION_HORIZONTAL);
			flavorMixX = new MixDependentNumber(0);
			flavorMixAlignY = new MixDependentNumber(0);
			flavorMixScale = new MixDependentNumber(1);
			flavorMixScaleLogo = new MixDependentNumber(1);
			flavorMixScaleFruit = new MixDependentNumber(1);
			flavorMixItemSpacing = new MixDependentNumber(20);
			flavorMixItemType = new MixDependentString(FLAVOR_MIX_ITEM_TYPE_FRUIT);
			flavorMixItemAlignment = new MixDependentString(FLAVOR_MIX_ITEM_ALIGNMENT_CENTER);
			fontSizeSponsorMix = new MixDependentNumber(10);
			fontSizeFlavorMix = new MixDependentNumber(10);
			fontSizeFlavorGlueTopMix = new MixDependentNumber(10);
			fontSizeFlavorGlueMidMix = new MixDependentNumber(10);
			fontSizeTitle = 10;
			fontSizeTitleEmphasis = 10;
			titleInTwoLines = false;
			fontSizeFlavor = 0;
			fontTrackingFlavor = 0;
			fontTypeMix = new MixDependentString(FONT_TYPE_REGULAR);
			numColsFlavor = 1;
			scaleFruits = 1;
			invisibleFruitsRedistributesButtons = false;
			heightFlavorItem = 100;
			marginFlavorItem = 0;
			buttonBackStyleId = "";
			buttonBackColorsNeutral = false;
			buttonBackStyleId = "";
			trackId = "";
			animationY = 0;
			animationPivotY = 0;

            fontTypeFlavorCopy = FONT_TYPE_REGULAR;

            fontSizeCalories = "33,33,33,29";
            fontSizeFlavorCalories = 40;
            marginCaloriesBottom = 45;
            marginCaloriesRight = 25;
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		// Static factories

		public static function fromViewOptions(__optionsProfile:ViewOptionsProfile, __platform:PlatformProfile):BrandViewOptions {
			var options:BrandViewOptions = new BrandViewOptions();
			options.id								= __optionsProfile.id;
			options.width							= __optionsProfile.getNumber("width",							__platform.width);
			options.height							= __optionsProfile.getNumber("height",							__platform.heightMinusMasthead);
			options.isADA							= __optionsProfile.getBoolean("isADA",							options.isADA);
			options.allowKeyboardFocus				= __optionsProfile.getBoolean("allowKeyboardFocus",				options.allowKeyboardFocus);
			options.liquidLayout					= __optionsProfile.getString("liquidLayout",					options.liquidLayout);
			options.liquidParticles					= __optionsProfile.getBoolean("liquidParticles",				options.liquidParticles);
			options.liquidOffsetX					= __optionsProfile.getNumber("liquidOffsetX",					options.liquidOffsetX);
			options.liquidOffsetY					= __optionsProfile.getNumber("liquidOffsetY",					options.liquidOffsetY);
			options.liquidPouredOffsetY				= __optionsProfile.getNumber("liquidPouredOffsetY",				options.liquidPouredOffsetY);
			options.logoLayout						= __optionsProfile.getString("logoLayout",						options.logoLayout);
			options.marginTitleFromTop				= __optionsProfile.getNumber("marginTitleFromTop",				options.marginTitleFromTop);
			options.marginTitleLeft					= __optionsProfile.getNumber("marginTitleLeft",					options.marginTitleLeft);
			options.marginTitleSecondLine			= __optionsProfile.getNumber("marginTitleSecondLine",			options.marginTitleSecondLine);
			options.marginLogoFromTitle				= __optionsProfile.getNumber("marginLogoFromTitle",				options.marginLogoFromTitle);
			options.marginLogoFromTopMix			= MixDependentNumber.fromXMLList(__optionsProfile.getXMLNodes("marginLogoFromTopMix"), options.marginLogoFromTopMix.defaultValue);
			options.logoAlignY						= MixDependentNumber.fromXMLList(__optionsProfile.getXMLNodes("logoAlignY"), options.logoAlignY.defaultValue);
			options.marginFlavorsFromTitle			= __optionsProfile.getNumber("marginFlavorsFromTitle",			options.marginFlavorsFromTitle);
			options.marginFlavorLeft				= __optionsProfile.getNumber("marginFlavorLeft",				options.marginFlavorLeft);
			options.marginFlavorIcon				= __optionsProfile.getNumber("marginFlavorIcon",				options.marginFlavorIcon);
			options.marginFlavorRight				= __optionsProfile.getNumber("marginFlavorRight",				options.marginFlavorRight);
			options.assumedWidthFruits				= __optionsProfile.getNumber("assumedWidthFruits",				options.assumedWidthFruits);
			options.marginFlavorMixFromLogo			= MixDependentNumber.fromXMLList(__optionsProfile.getXMLNodes("marginFlavorMixFromLogo"), options.marginFlavorMixFromLogo.defaultValue);
			options.flavorMixOrientation			= MixDependentString.fromXMLList(__optionsProfile.getXMLNodes("flavorMixOrientation"), options.flavorMixOrientation.defaultValue);
			options.flavorMixX						= MixDependentNumber.fromXMLList(__optionsProfile.getXMLNodes("flavorMixX"), options.flavorMixX.defaultValue);
			options.flavorMixAlignY					= MixDependentNumber.fromXMLList(__optionsProfile.getXMLNodes("flavorMixAlignY"), options.flavorMixAlignY.defaultValue);
			options.flavorMixScale					= MixDependentNumber.fromXMLList(__optionsProfile.getXMLNodes("flavorMixScale"), options.flavorMixScale.defaultValue);
			options.flavorMixScaleLogo				= MixDependentNumber.fromXMLList(__optionsProfile.getXMLNodes("flavorMixScaleLogo"), options.flavorMixScaleLogo.defaultValue);
			options.flavorMixScaleFruit				= MixDependentNumber.fromXMLList(__optionsProfile.getXMLNodes("flavorMixScaleFruit"), options.flavorMixScaleFruit.defaultValue);
			options.flavorMixItemSpacing			= MixDependentNumber.fromXMLList(__optionsProfile.getXMLNodes("flavorMixItemSpacing"), options.flavorMixItemSpacing.defaultValue);
			options.flavorMixItemType				= MixDependentString.fromXMLList(__optionsProfile.getXMLNodes("flavorMixItemType"), options.flavorMixItemType.defaultValue);
			options.flavorMixItemAlignment			= MixDependentString.fromXMLList(__optionsProfile.getXMLNodes("flavorMixItemAlignment"), options.flavorMixItemAlignment.defaultValue);
			options.fontSizeSponsorMix				= MixDependentNumber.fromXMLList(__optionsProfile.getXMLNodes("fontSizeSponsorMix"), options.fontSizeSponsorMix.defaultValue);
			options.fontSizeFlavorMix				= MixDependentNumber.fromXMLList(__optionsProfile.getXMLNodes("fontSizeFlavorMix"), options.fontSizeFlavorMix.defaultValue);
			options.fontSizeFlavorGlueTopMix		= MixDependentNumber.fromXMLList(__optionsProfile.getXMLNodes("fontSizeFlavorGlueTopMix"), options.fontSizeFlavorGlueTopMix.defaultValue);
			options.fontSizeFlavorGlueMidMix		= MixDependentNumber.fromXMLList(__optionsProfile.getXMLNodes("fontSizeFlavorGlueMidMix"), options.fontSizeFlavorGlueMidMix.defaultValue);
			options.fontSizeTitle					= __optionsProfile.getNumber("fontSizeTitle",					options.fontSizeTitle);
			options.fontSizeTitleEmphasis			= __optionsProfile.getNumber("fontSizeTitleEmphasis",			options.fontSizeTitleEmphasis);
			options.titleInTwoLines					= __optionsProfile.getBoolean("titleInTwoLines",				options.titleInTwoLines);
			options.fontSizeFlavor					= __optionsProfile.getNumber("fontSizeFlavor",					options.fontSizeFlavor);
			options.fontTrackingFlavor				= __optionsProfile.getNumber("fontTrackingFlavor",				options.fontTrackingFlavor);
			options.fontTypeMix						= MixDependentString.fromXMLList(__optionsProfile.getXMLNodes("fontTypeMix"), options.fontTypeMix.defaultValue);
			options.numColsFlavor					= __optionsProfile.getNumber("numColsFlavor",					options.numColsFlavor);
			options.scaleFruits						= __optionsProfile.getNumber("scaleFruits",						options.scaleFruits);
			options.invisibleFruitsRedistributesButtons	= __optionsProfile.getBoolean("invisibleFruitsRedistributesButtons",						options.invisibleFruitsRedistributesButtons);
			options.heightFlavorItem				= __optionsProfile.getNumber("heightFlavorItem",				options.heightFlavorItem);
			options.marginFlavorItem				= __optionsProfile.getNumber("marginFlavorItem",				options.marginFlavorItem);
			options.buttonBackStyleId				= __optionsProfile.getString("buttonBackStyle",					options.buttonBackStyleId);
			options.buttonBackColorsNeutral			= __optionsProfile.getBoolean("buttonBackColorsNeutral",		options.buttonBackColorsNeutral);
			options.buttonPourStyleId				= __optionsProfile.getString("buttonPourStyle",					options.buttonPourStyleId);
			options.trackId							= __optionsProfile.getString("trackId",							options.trackId);
			options.animationY						= __optionsProfile.getNumber("animationY",						options.animationY);
			options.animationPivotY					= __optionsProfile.getNumber("animationPivotY",					options.animationPivotY);

            //Data for the calories
            options.fontSizeCalories			    = __optionsProfile.getString("fontSizeCalories",				options.fontSizeCalories);
            options.fontSizeFlavorCalories			= __optionsProfile.getNumber("fontSizeFlavorCalories",			options.fontSizeFlavorCalories);
            options.marginCaloriesBottom			= __optionsProfile.getNumber("marginCaloriesBottom",			options.marginCaloriesBottom);
            options.marginCaloriesRight			    = __optionsProfile.getNumber("marginCaloriesRight",			    options.marginCaloriesRight);

            //for the font type of the flavor copy:
            options.fontTypeFlavorCopy			    = __optionsProfile.getString("fontTypeFlavorCopy",				options.fontTypeFlavorCopy);


            return options;
		}

		public function get buttonBackStyle():BlobButtonStyle {
			return BlobButton.getButtonStyle(buttonBackStyleId);
		}

		public function get buttonPourStyle():BlobButtonStyle {
			return BlobButton.getButtonStyle(buttonPourStyleId);
		}
	}
}


import com.zehfernando.utils.XMLUtils;
class MixDependentNumber {
	// A value that depends on a given id

	public var defaultValue:Number;
	private var map:Object = {}; // key:value pair

	public function MixDependentNumber(__defaultValue:Number) {
		defaultValue = __defaultValue;
		map = {};
	}

	public static function fromXMLList(__xmlList:XMLList, __defaultValue:Number = 0):MixDependentNumber {
		var mixDependentNumber:MixDependentNumber = new MixDependentNumber(__defaultValue);
		var xmlNode:XML;
		var mixLayoutId:String;
		var defaultValueFound:Number = NaN;
		var value:Number;
		for (var i:int = 0; i < __xmlList.length(); i++) {
			xmlNode = __xmlList[i];
			mixLayoutId = XMLUtils.getAttributeAsString(xmlNode, "mixLayout");
			value = parseFloat(xmlNode);
			if (mixLayoutId.length == 0) {
				// No id, set as default
				if (isNaN(defaultValueFound)) defaultValueFound = value;
			} else {
				// Has id, add
				mixDependentNumber.addValue(mixLayoutId, value);
			}
		}
		if (!isNaN(defaultValueFound)) mixDependentNumber.defaultValue = defaultValueFound;
		return mixDependentNumber;
	}

	public function addValue(__mixLayout:String, __value:Number):void {
		map[__mixLayout] = __value;
	}

	public function getValue(__mixLayout:String = null):Number {
		return (map.hasOwnProperty(__mixLayout) ? map[__mixLayout] : defaultValue) as Number;
	}
}
class MixDependentString {
	// A value that depends on a given id

	public var defaultValue:String;
	private var map:Object = {}; // key:value pair

	public function MixDependentString(__defaultValue:String) {
		defaultValue = __defaultValue;
		map = {};
	}

	public static function fromXMLList(__xmlList:XMLList, __defaultValue:String = ""):MixDependentString {
		var mixDependentString:MixDependentString = new MixDependentString(__defaultValue);
		var xmlNode:XML;
		var mixLayoutId:String;
		var defaultValueFound:String = null;
		var value:String;
		for (var i:int = 0; i < __xmlList.length(); i++) {
			xmlNode = __xmlList[i];
			mixLayoutId = XMLUtils.getAttributeAsString(xmlNode, "mixLayout");
			value = xmlNode;
			if (mixLayoutId.length == 0) {
				// No id, set as default
				if (defaultValueFound == null) defaultValueFound = value;
			} else {
				// Has id, add
				mixDependentString.addValue(mixLayoutId, value);
			}
		}
		if (defaultValueFound != null) mixDependentString.defaultValue = defaultValueFound;
		return mixDependentString;
	}

	public function addValue(__mixLayout:String, __value:String):void {
		map[__mixLayout] = __value;
	}

	public function getValue(__mixLayout:String = null):String {
		return (map.hasOwnProperty(__mixLayout) ? map[__mixLayout] : defaultValue) as String;
	}
}