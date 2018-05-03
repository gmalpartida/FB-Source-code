package com.firstborn.pepsi.assets {
	/**
	 * @author zeh fernando
	 */
	public class FontLibrary {

		// Consolas
        public static const TUNGSTEN_MEDIUM:String = "TungstenMedium";
        [Embed(source="/../embed/fonts/Tungsten-Medium.otf", fontFamily="TungstenMedium", mimeType="application/x-font", embedAsCFF="true")]
        protected static const fontTM:Class;

        public static const BOOSTER_FY_REGULAR:String = "BoosterFyRegular";
        [Embed(source="/../embed/fonts/Booster-FY-Regular.otf", fontFamily="BoosterFyRegular", mimeType="application/x-font", embedAsCFF="true")]
        protected static const fontBFR:Class;

        public static const BOOSTER_NEXT_FY_LIGHT:String = "BoosterNextFyLight";
        [Embed(source="/../embed/fonts/BoosterNextFY-Light.otf", fontFamily="BoosterNextFyLight", mimeType="application/x-font", embedAsCFF="true")]
        protected static const fontBNFL:Class;

        public static const BOOSTER_NEXT_FY_REGULAR:String = "BoosterNextFyRegular";
        [Embed(source="/../embed/fonts/BoosterNextFY-Regular.otf", fontFamily="BoosterNextFyRegular", mimeType="application/x-font", embedAsCFF="true")]
        protected static const fontBNFR:Class;

        public static const BOOSTER_NEXT_FY_BOLD:String = "BoosterNextFyBold";
        [Embed(source="/../embed/fonts/BoosterNextFY-Bold.otf", fontFamily="BoosterNextFyBold", mimeType="application/x-font", embedAsCFF="true")]
        protected static const fontBNFB:Class;

        public static const FUTURA_MEDIUM:String = "FuturaMedium";
        [Embed(source="/../embed/fonts/FuturaStd-Medium.otf", fontFamily="FuturaMedium", mimeType="application/x-font", embedAsCFF="true")]
        protected static const fontFM:Class;

        public static const FUTURA_BOLD:String = "FuturaBold";
        [Embed(source="/../embed/fonts/FuturaStd-Bold.otf", fontFamily="FuturaBold", mimeType="application/x-font", embedAsCFF="true")]
        protected static const fontFB:Class;


        //Constants for the external fonts naming.
        public static const EXTERNAL_LIGHT:String = "ExternalLight";
        public static const EXTERNAL_MEDIUM:String = "ExternalMedium";
        public static const EXTERNAL_REGULAR:String = "ExternalRegular";
        public static const EXTERNAL_BOLD:String = "ExternalBold";

	}
}
