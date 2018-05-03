package com.firstborn.pepsi.data {
	import com.zehfernando.utils.VectorUtils;
	import com.zehfernando.utils.XMLUtils;
	/**
	 * @author zeh fernando
	 */
	public class XMLOverrider {

		// Static class to serve as a helper for overriding data in other XMLs

		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public static function getOverriddenXML(__overrideDatas:Vector.<XML>, __assumedXMLId:String, __sourceXML:XML, __canCreate:Boolean = true):XML {
			// Given a sourceXML of an assumed id, replaces ALL of its nodes that match the xml(id) and path with the new value, returning the new XML

			// Create a copy
			var newXML:XML = new XML(__sourceXML.toXMLString());

			for (var i:int = 0; i < __overrideDatas.length; i++) {
				replaceXMLData(__overrideDatas[i], __assumedXMLId, newXML, __canCreate);
			}

			return newXML;
		}


		// ================================================================================================================
		// PRIVATE INTERFACE ----------------------------------------------------------------------------------------------

		private static function replaceXMLData(__overrideData:XML, __assumedXMLId:String, __targetXML:XML, __canCreate:Boolean = true):void {
			// Given a sourceXML of an assumed id, replaces ALL of its nodes that match the xml(id) and path with the new value

			// Parses and replaces
			var overrideItems:XMLList = __overrideData.child("override");
			var overrideItem:XML;
			for (var i:int = 0; i < overrideItems.length(); i++) {
				overrideItem = overrideItems[i];
				if (XMLUtils.getNodeAsString(overrideItem, "xml") == __assumedXMLId) {
					// Correct XML, replace
					replaceXMLNodesData(__targetXML, VectorUtils.stringToStringVector(XMLUtils.getNodeAsString(overrideItem, "path"), "/"), XMLUtils.getNodeAsStringInternal(overrideItem, "value"), __canCreate);
				}
			}
		}

		private static function replaceXMLNodesData(__targetXML:XML, __path:Vector.<String>, __value:String, __canCreate:Boolean = true):void {
			// Replaces nodes of a given path with a certain string value
			// Path: name[attribute="value",attribute="value"]...

			var i:int;

			var currentPathItem:String = __path[0];
			var bracketPos:int = currentPathItem.indexOf("[");
			var pathName:String;
			var requiredAttributes:Object; // key:values
			if (bracketPos > -1) {
				// Complex query
				pathName = currentPathItem.substr(0, bracketPos);
				requiredAttributes = {};
				var attributePairs:Vector.<String> = VectorUtils.stringToStringVector(currentPathItem.substr(bracketPos + 1, currentPathItem.length - bracketPos - 2), ",", true);
				for (i = 0; i < attributePairs.length; i++) {
					var posEqual:int = attributePairs[i].indexOf("=");
					if (posEqual > -1) {
						requiredAttributes[attributePairs[i].substr(0, posEqual)] = attributePairs[i].substr(posEqual + 2, attributePairs[i].length - posEqual - 3);
					}
				}
			} else {
				// Simple path name
				pathName = currentPathItem;
				requiredAttributes = {};
			}

			var nodes:XMLList = __targetXML.child(pathName);

			if (nodes.length() == 0 && __canCreate && __path.length == 1) {
				// Last path element, no node to change, and it can create: create a new text node
				__targetXML.appendChild(new XML("<" + pathName + ">" + __value + "</" + pathName + ">"));
			} else {
				// There's nodes already, so change them
				var isValidNode:Boolean;
				for (i = 0; i < nodes.length(); i++) {
					// Check whether it matches the node
					isValidNode = true;
					for (var iis:String in requiredAttributes) {
						if (XMLUtils.getAttributeAsString((nodes[i] as XML), iis) != requiredAttributes[iis]) {
							isValidNode = false;
							break;
						}
					}

					if (isValidNode) {
						// It's a valid node
						if (__path.length == 1) {
							// Change these nodes
							nodes[i] = new XML("<" + pathName + ">" + __value + "</" + pathName + ">");
						} else {
							// More sub nodes
							replaceXMLNodesData(nodes[i], __path.slice(1), __value);
						}
					}
				}
			}
		}
	}
}
