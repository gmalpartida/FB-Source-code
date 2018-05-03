package com.firstborn.pepsi.assets {
	/**
	 * @author zeh fernando
	 */
	public class ImageLibrary {

		// Pre-compressed textures

		[Embed(source="/../embed/icons/icon_arrow.atf", mimeType="application/octet-stream")]
		public static const ICON_ARROW:Class;

		[Embed(source="/../embed/icons/icon_water_tap.atf", mimeType="application/octet-stream")]
		public static const ICON_WATER_TAP:Class;

		[Embed(source="/../embed/icons/icon_water_sparkling.atf", mimeType="application/octet-stream")]
		public static const ICON_WATER_SPARKLING:Class;

		[Embed(source="/../embed/icons/icon_pour.atf", mimeType="application/octet-stream")]
		public static const ICON_POUR:Class;
		public static const ICON_POUR_ID:String = "icon_pour"; // Used for object pool

		[Embed(source="/../embed/icons/icon_pour_small.atf", mimeType="application/octet-stream")]
		public static const ICON_POUR_SMALL:Class;
		public static const ICON_POUR_SMALL_ID:String = "icon_pour_small";

		[Embed(source="/../embed/icons/icon_ada.atf", mimeType="application/octet-stream")]
		public static const ICON_ADA:Class;
		public static const ICON_ADA_ID:String = "icon_ada";


        //For unattended
        [Embed(source="/../embed/icons/icon_arrow_unlock.atf", mimeType="application/octet-stream")]
        public static const ICON_ARROW_UNLOCK:Class;

        [Embed(source="/../embed/icons/icon_done.atf", mimeType="application/octet-stream")]
        public static const ICON_DONE:Class;


    }
}
