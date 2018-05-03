package com.firstborn.pepsi.data.home {
	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.data.AnimationDefinition;
	import com.zehfernando.net.assets.AssetLibrary;
	import com.zehfernando.utils.ArrayUtils;
	import com.zehfernando.utils.VectorUtils;
	import com.zehfernando.utils.XMLUtils;
	/**
	 * @author zeh fernando
	 */
	public class SequenceItemDefinition {

		// Constants
		public static const DIRECTION_RIGHT:String = "right";

		// Properties
		public var animationId:String;
		private var _animation:AnimationDefinition;

		public var centerX:Number;
		public var centerY:Number;
		public var frequency:Number;
		public var minTravelAngle:Number;
		public var maxTravelAngle:Number;
		public var minStartAngle:Number;
		public var maxStartAngle:Number;
		public var minEndAngle:Number;
		public var maxEndAngle:Number;
		public var alignWithTarget:Boolean;
		public var flipOnAligning:Boolean;
		public var rotationOffset:Number;
		public var travelBlobs:Boolean;
		public var sameBlob:Boolean;
		public var childBlob:Boolean;
		public var heights:Vector.<Number>;
		public var speeds:Vector.<Number>;
		public var scales:Vector.<Number>;
		public var restrictedBeverageIds:Vector.<String>;
		public var direction:String;
		public var playMetaballsStart:Boolean;
		public var playMetaballsEnd:Boolean;
		public var aboveTarget:Boolean;
		public var startImpact:Number;
		public var endImpact:Number;
		public var avoidOverlap:Boolean;
		public var avoidBleed:Boolean;
		public var tinted:Boolean;

		// Static
		private static var _sequenceItems:Vector.<SequenceItemDefinition>;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function SequenceItemDefinition() {
			// Set defaults
			animationId = "";
			centerX = 0;
			centerY = 0;
			minTravelAngle = NaN;
			maxTravelAngle = NaN;
			minStartAngle = NaN;
			maxStartAngle = NaN;
			minEndAngle = NaN;
			maxEndAngle = NaN;
			alignWithTarget = false;
			flipOnAligning = false;
			rotationOffset = 0;
			direction = DIRECTION_RIGHT;
			frequency = 1;
			travelBlobs = true;
			sameBlob = true;
			childBlob = true;
			heights = new Vector.<Number>();
			speeds = new Vector.<Number>();
			playMetaballsStart = true;
			playMetaballsEnd = true;
			aboveTarget = false;
			startImpact = 0;
			endImpact = 0;
			avoidOverlap = false;
			avoidBleed = false;
			tinted = true;
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public static function fromXMLList(__xmlList:XMLList):Vector.<SequenceItemDefinition> {
			var sequenceItems:Vector.<SequenceItemDefinition> = new Vector.<SequenceItemDefinition>();

			var sequenceItemXML:XML;
			var newSequenceItem:SequenceItemDefinition;

			var i:int, j:int;
			for (i = 0; i < __xmlList.length(); i++) {
				sequenceItemXML = __xmlList[i];

				newSequenceItem = new SequenceItemDefinition();

				// Common
				newSequenceItem.animationId					= XMLUtils.getNodeAsString(sequenceItemXML, "animation",			newSequenceItem.animationId);
				newSequenceItem.centerX						= XMLUtils.getNodeAsFloat(sequenceItemXML, "centerX",				newSequenceItem.centerX);
				newSequenceItem.centerY						= XMLUtils.getNodeAsFloat(sequenceItemXML, "centerY",				newSequenceItem.centerY);
				newSequenceItem.frequency					= XMLUtils.getNodeAsFloat(sequenceItemXML, "frequency",				newSequenceItem.frequency);
				newSequenceItem.minTravelAngle				= XMLUtils.getNodeAsFloat(sequenceItemXML, "minTravelAngle",		newSequenceItem.minTravelAngle);
				newSequenceItem.maxTravelAngle				= XMLUtils.getNodeAsFloat(sequenceItemXML, "maxTravelAngle",		newSequenceItem.maxTravelAngle);
				newSequenceItem.minStartAngle				= XMLUtils.getNodeAsFloat(sequenceItemXML, "minStartAngle",			newSequenceItem.minStartAngle);
				newSequenceItem.maxStartAngle				= XMLUtils.getNodeAsFloat(sequenceItemXML, "maxStartAngle",			newSequenceItem.maxStartAngle);
				newSequenceItem.minEndAngle					= XMLUtils.getNodeAsFloat(sequenceItemXML, "minEndAngle",			newSequenceItem.minEndAngle);
				newSequenceItem.maxEndAngle					= XMLUtils.getNodeAsFloat(sequenceItemXML, "maxEndAngle",			newSequenceItem.maxEndAngle);
				newSequenceItem.alignWithTarget				= XMLUtils.getNodeAsBoolean(sequenceItemXML, "alignWithTarget",		newSequenceItem.alignWithTarget);
				newSequenceItem.flipOnAligning				= XMLUtils.getNodeAsBoolean(sequenceItemXML, "flipOnAligning",		newSequenceItem.flipOnAligning);
				newSequenceItem.rotationOffset				= XMLUtils.getNodeAsFloat(sequenceItemXML, "rotationOffset",		newSequenceItem.rotationOffset);
				newSequenceItem.travelBlobs					= XMLUtils.getNodeAsBoolean(sequenceItemXML, "travelBlobs",			newSequenceItem.travelBlobs);
				newSequenceItem.sameBlob					= XMLUtils.getNodeAsBoolean(sequenceItemXML, "sameBlob",			newSequenceItem.sameBlob);
				newSequenceItem.childBlob					= XMLUtils.getNodeAsBoolean(sequenceItemXML, "childBlob",			newSequenceItem.childBlob);
				newSequenceItem.heights						= VectorUtils.arrayToNumberVector(ArrayUtils.stringArrayToNumberArray(XMLUtils.getNodeAsString(sequenceItemXML, "heights", "0").split(",")));
				newSequenceItem.speeds						= VectorUtils.arrayToNumberVector(ArrayUtils.stringArrayToNumberArray(XMLUtils.getNodeAsString(sequenceItemXML, "speeds", "1").split(",")));
				newSequenceItem.scales						= VectorUtils.arrayToNumberVector(ArrayUtils.stringArrayToNumberArray(XMLUtils.getNodeAsString(sequenceItemXML, "scales", "1").split(",")));
				newSequenceItem.restrictedBeverageIds		= VectorUtils.stringToStringVector(XMLUtils.getNodeAsString(sequenceItemXML, "restrictedBeverageIds"), ",", true);
				newSequenceItem.direction					= XMLUtils.getNodeAsString(sequenceItemXML, "direction",			newSequenceItem.direction);
				newSequenceItem.playMetaballsStart			= XMLUtils.getNodeAsBoolean(sequenceItemXML, "playMetaballsStart",	newSequenceItem.playMetaballsStart);
				newSequenceItem.playMetaballsEnd			= XMLUtils.getNodeAsBoolean(sequenceItemXML, "playMetaballsEnd",	newSequenceItem.playMetaballsEnd);
				newSequenceItem.aboveTarget					= XMLUtils.getNodeAsBoolean(sequenceItemXML, "aboveTarget",			newSequenceItem.aboveTarget);
				newSequenceItem.startImpact					= XMLUtils.getNodeAsFloat(sequenceItemXML, "startImpact",			newSequenceItem.startImpact);
				newSequenceItem.endImpact					= XMLUtils.getNodeAsFloat(sequenceItemXML, "endImpact",				newSequenceItem.endImpact);
				newSequenceItem.avoidOverlap				= XMLUtils.getNodeAsBoolean(sequenceItemXML, "avoidOverlap",		newSequenceItem.avoidOverlap);
				newSequenceItem.avoidBleed					= XMLUtils.getNodeAsBoolean(sequenceItemXML, "avoidBleed",			newSequenceItem.avoidBleed);
				newSequenceItem.tinted						= XMLUtils.getNodeAsBoolean(sequenceItemXML, "tinted",				newSequenceItem.tinted);

				// Removes empty strings in beverageIds
				for (j = 0; j < newSequenceItem.restrictedBeverageIds.length; j++) {
					if (newSequenceItem.restrictedBeverageIds[j].length == 0) {
						newSequenceItem.restrictedBeverageIds.splice(j, 1);
						j--;
					}
				}

				sequenceItems.push(newSequenceItem);
			}
			return sequenceItems;
		}

		public static function getSequenceItems():Vector.<SequenceItemDefinition> {
			if (_sequenceItems == null) {
				// Need to load menu items first
				_sequenceItems = fromXMLList((FountainFamily.homeXML.child("sequences")[0] as XML).children());
			}
			return _sequenceItems;
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get isDirectionRight():Boolean {
			return direction == DIRECTION_RIGHT;
		}

		public function get animation():AnimationDefinition{
			if (_animation == null) {
				// Animation is unknown, tries to find it first
				_animation = AnimationDefinition.getAnimationDefinition(animationId, FountainFamily.animationDefinitions);
			}
			return _animation;
		}
	}
}
