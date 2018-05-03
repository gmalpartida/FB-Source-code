package com.firstborn.pepsi.common.backend {
	/**
	 * @author zeh fernando
	 */
	public class CupSizeInfo {

		// Properties
		public var id:String;
		public var name:String;
		public var amount:Number;
		public var isDefault:Boolean;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function CupSizeInfo() {
		}


		// ================================================================================================================
		// STATIC INTERFACE ------------------------------------------------------------------------------------------------

		public static function sort(__cup1:CupSizeInfo, __cup2:CupSizeInfo):Number {
			// Sort between two CupSizeInfo instances. Meaning to be used with Vector.sort().
			// Returns:
			// -1 if __cup1 should appear before __cup2 in the sorted sequence
			// 0 if they are the same
			// +1 if __cup1 should appear after __cup2 in the sorted sequence
			return __cup1.amount < __cup2.amount ? -1 : (__cup1.amount > __cup2.amount ? 1 : 0);
		}

	}
}
