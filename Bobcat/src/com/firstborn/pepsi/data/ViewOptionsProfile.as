package com.firstborn.pepsi.data {
	import com.zehfernando.utils.StringUtils;
	import com.zehfernando.utils.XMLUtils;
	/**
	 * @author zeh fernando
	 */
	public class ViewOptionsProfile {

		// Properties
		public var id:String;								// E.g. "home"

		public var objects:Object;
		public var originalXML:XML;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function ViewOptionsProfile() {
			objects = {};
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function getBoolean(__id:String, __default:Boolean = false):Boolean {
			return (objects.hasOwnProperty(__id) && getString(__id).length > 0) ? StringUtils.toBoolean(objects[__id], __default) : __default;
		}

		public function getString(__id:String, __default:String = ""):String {
			return objects.hasOwnProperty(__id) ? objects[__id] : __default;
		}

		public function getNumber(__id:String, __default:Number = 0):Number {
			return (objects.hasOwnProperty(__id) && getString(__id).length > 0) ? parseFloat(objects[__id]) : __default;
		}

		public function getInt(__id:String, __default:Number = 0):Number {
			return (objects.hasOwnProperty(__id) && getString(__id).length > 0) ? Math.round(parseFloat(objects[__id])) : __default;
		}

		public function getXMLNodes(__id:String):XMLList {
			return originalXML.child(__id);
		}


		// ================================================================================================================
		// STATIC INTERFACE -----------------------------------------------------------------------------------------------

		public static function fromXMLList(__xmlList:XMLList):Vector.<ViewOptionsProfile> {
			var viewOptionsXML:XML;
			var newViewOptions:ViewOptionsProfile;
			var newViewOptionsList:Vector.<ViewOptionsProfile> = new Vector.<ViewOptionsProfile>();

			var i:int, j:int;
			for (i = 0; i < __xmlList.length(); i++) {
				viewOptionsXML = __xmlList[i];

				newViewOptions = new ViewOptionsProfile();

				newViewOptions.id = XMLUtils.getAttributeAsString(viewOptionsXML, "id");
				newViewOptions.originalXML = viewOptionsXML;

				for (j = 0; j < viewOptionsXML.children().length(); j++) {
					//log(j,"====> " + XMLUtils.getNodeName(viewOptionsXML.children()[j]) + " = " + XMLUtils.getValue(viewOptionsXML.children()[j], ""));
					newViewOptions.objects[XMLUtils.getNodeName(viewOptionsXML.children()[j])] = XMLUtils.getValue(viewOptionsXML.children()[j], "");
				}

				newViewOptionsList.push(newViewOptions);
			}
			return newViewOptionsList;
		}
	}
}
