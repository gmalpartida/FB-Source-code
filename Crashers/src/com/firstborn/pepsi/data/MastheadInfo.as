package com.firstborn.pepsi.data {
	import com.zehfernando.utils.XMLUtils;
	/**
	 * @author zeh fernando
	 */
	public class MastheadInfo {

		// Properties
		public var videos:Vector.<String>;
		public var timeBetweenVideos:Number;
		public var timeBetweenCycles:Number;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function MastheadInfo(__xml:XML) {
			videos = new Vector.<String>();

			timeBetweenVideos = XMLUtils.getNodeAsFloat(__xml, "timeBetweenVideos");
			timeBetweenCycles = XMLUtils.getNodeAsFloat(__xml, "timeBetweenCycles");

			var videosXML:XML = XMLUtils.getFirstNode(__xml.child("videos"));
			if (videosXML != null) {
				var videoListXML:XMLList = videosXML.child("video");
				for (var i:int = 0; i < videoListXML.length(); i++) {
					videos.push(XMLUtils.getValue(videoListXML[i]));
				}
			}
		}
	}
}
