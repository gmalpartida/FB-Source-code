package com.firstborn.pepsi.display.gpu.home.menu.mesh {
	import flash.geom.Point;
	/**
	 * @author zeh fernando
	 */
	public class MeshNodeInfo {

		// Information about each node
		public var position:Point;
		public var scale:Number;
		public var id:int;							// index of the item that goes here... starts at 0, -1 = invalid/unused node
		public var parentId:int;					// index of the "parent" node id (the one is always on top of this node)
		public var logoScaleMultiplier:Number;			// Default = 1, higher = bigger (multiplier)

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function MeshNodeInfo(__id:int) {
			id = __id;
			scale = 1;
			position = new Point();
			parentId = -1;
			logoScaleMultiplier = 1;
		}
	}
}
