package com.firstborn.pepsi.display.gpu.common {
	/**
	 * @author zeh fernando
	 */
	public class BlobButtonStyle {

		// Properties
		public var radius:Number;
		public var margin:Number;
		public var gutter:Number;
		public var strokeWidths:Vector.<Number>;
		public var iconScale:Number;
		public var fontSize:Number;
		public var fontBold:Boolean;
		public var fontAlpha:Number;
		public var fontTracking:Number;
		public var fontEmphasisSize:Number;
		public var fontEmphasisBold:Boolean;
		public var fontEmphasisAlpha:Number;
		public var fontEmphasisTracking:Number;
		public var fontLeading:Number;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function BlobButtonStyle() {
			radius					= 10;
			margin					= 0;
			gutter					= 0;
			strokeWidths 			= new Vector.<Number>();
			iconScale				= 1;
			fontSize				= 10;
			fontBold				= false;
			fontAlpha				= 1;
			fontTracking			= 0;
			fontEmphasisSize		= 0;
			fontEmphasisBold		= false;
			fontEmphasisAlpha		= 1;
			fontEmphasisTracking	= 0;
			fontLeading				= 0;
		}
	}
}
