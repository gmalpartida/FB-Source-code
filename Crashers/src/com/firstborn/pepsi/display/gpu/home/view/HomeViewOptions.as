package com.firstborn.pepsi.display.gpu.home.view {
	import com.firstborn.pepsi.data.PlatformProfile;
	import com.firstborn.pepsi.data.ViewOptionsProfile;
	import com.firstborn.pepsi.display.gpu.common.BlobButtonStyle;
	import com.firstborn.pepsi.display.gpu.common.components.BlobButton;
	/**
	 * @author zeh fernando
	 */
	public class HomeViewOptions {
		// Options for creating a new configurable HomeView

		// Constants
		public static const BUTTON_LAYOUT_VERTICAL:String = "vertical";
		public static const BUTTON_LAYOUT_VERTICAL_RIGHT:String = "vertical-right";
		public static const BUTTON_LAYOUT_HORIZONTAL:String = "horizontal";
		public static const BUTTON_LAYOUT_NONE:String = "none";

		public static const BUTTON_SIZE_SMALL:String = "small";
		public static const BUTTON_SIZE_SMALL_BACK:String = "small-back";
		public static const BUTTON_SIZE_MEDIUM:String = "medium";

		public static const MENU_LAYOUT_ORGANIC:String = "organic";				// Organic mesh distribution (tower)
		public static const MENU_LAYOUT_GRID:String = "grid";					// A more grid-like distribution (tower ADA)
		public static const MENU_LAYOUT_SPIRAL:String = "spiral";				// Distribution along a line or curve (bridge)
		public static const MENU_LAYOUT_CUSTOM:String = "custom";				// Distribution along a line or curve (bridge)

		// Properties
		public var id:String;													// Just a quick unique id for identification
		public var width:int;
		public var height:int;
		public var hasTitle:Boolean;
		public var marginTitleTop:Number;
		public var marginTitleBottom:Number;
		public var menuHasSequencePlayer:Boolean;
		public var menuAlignX:Number;
		public var menuAlignY:Number;
		public var particleAreaDensity:Number;
		public var particleNumberScale:Number;									// Scale multiplier to number of particles for main menu (1 = same number as required; 0.5 = half; etc)
		public var particleSizeScale:Number;									// Scale multiplier to size of particles for main menu (1 = same scale as original; 0.5 = half; etc)
		public var particleAlphaScale:Number;									// Scale opacity of particles for main menu (1 = same opacityas required; 0.5 = half; etc)
		public var particleClusterChance:Number;								// Chance of creating a particle cluster (0..1)
		public var particleClusterItemsMax:int;									// Maximum number of items in each cluster
		public var numColumnsDesired:int;										// Number of columns desired (for grid menu type)
		public var menuLayout:String;											// Enum string from MENU_LAYOUT_*
		public var menuLayoutParams:String;										// Long string, format depends on menyLayoutParams
		public var buttonLayout:String;											// Enum string
		public var buttonStyleId:String;										// Enum from BlobButton.STYLE_*
		public var allowKeyboardFocus:Boolean;									// Whether to use the focus controller (for hardware ADA support)


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function HomeViewOptions() {
			// Set defaults
			id = "";
			width = 0;
			height = 0;
			hasTitle = false;
			marginTitleTop = 0;
			marginTitleBottom = 0;
			menuHasSequencePlayer = true;
			menuAlignX = 0;
			menuAlignY = 0;
			particleAreaDensity = 0;
			particleNumberScale = 1;
			particleSizeScale = 1;
			particleAlphaScale = 1;
			particleClusterChance = 0.1;
			particleClusterItemsMax = 3;
			menuLayout = MENU_LAYOUT_GRID;
			menuLayoutParams = "";
			buttonLayout = BUTTON_LAYOUT_HORIZONTAL;
			buttonStyleId = BlobButton.STYLE_NEUTRAL_MEDIUM;
			allowKeyboardFocus = false;
			numColumnsDesired = 4;
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		// Static factories

		public static function fromViewOptions(__optionsProfile:ViewOptionsProfile, __platform:PlatformProfile):HomeViewOptions {
			var options:HomeViewOptions = new HomeViewOptions();
			options.id						= __optionsProfile.id;
			options.width					= __optionsProfile.getNumber("width",					__platform.width);
			options.height					= __optionsProfile.getNumber("height",					__platform.heightMinusMasthead);
			options.hasTitle				= __optionsProfile.getBoolean("hasTitle",				options.hasTitle);
			options.marginTitleTop			= __optionsProfile.getNumber("marginTitleTop",			options.marginTitleTop);
			options.marginTitleBottom		= __optionsProfile.getNumber("marginTitleBottom",		options.marginTitleBottom);
			options.menuHasSequencePlayer	= __optionsProfile.getBoolean("menuHasSequencePlayer",	options.menuHasSequencePlayer);
			options.menuAlignX				= __optionsProfile.getNumber("menuAlignX",				options.menuAlignX);
			options.menuAlignY				= __optionsProfile.getNumber("menuAlignY",				options.menuAlignY);
			options.particleAreaDensity		= __optionsProfile.getNumber("particleAreaDensity",		options.particleAreaDensity);
			options.particleNumberScale		= __optionsProfile.getNumber("particleNumberScale",		options.particleNumberScale);
			options.particleSizeScale		= __optionsProfile.getNumber("particleSizeScale",		options.particleSizeScale);
			options.particleAlphaScale		= __optionsProfile.getNumber("particleAlphaScale",		options.particleAlphaScale);
			options.particleClusterChance	= __optionsProfile.getNumber("particleClusterChance",	options.particleClusterChance);
			options.particleClusterItemsMax	= __optionsProfile.getInt("particleClusterItemsMax",	options.particleClusterItemsMax);
			options.menuLayout				= __optionsProfile.getString("menuLayout",				options.menuLayout);
			options.menuLayoutParams		= __optionsProfile.getString("menuLayoutParams",		options.menuLayoutParams);
			options.buttonLayout			= __optionsProfile.getString("buttonLayout",			options.buttonLayout);
			options.buttonStyleId			= __optionsProfile.getString("buttonStyle",				options.buttonStyleId);
			options.allowKeyboardFocus		= __optionsProfile.getBoolean("allowKeyboardFocus",		options.allowKeyboardFocus);
			options.numColumnsDesired		= __optionsProfile.getInt("numColumnsDesired",			options.numColumnsDesired);
			return options;
		}

		public function get buttonStyle():BlobButtonStyle {
			return BlobButton.getButtonStyle(buttonStyleId);
		}

	}
}
