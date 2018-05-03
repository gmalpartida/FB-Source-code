package com.firstborn.pepsi.display.gpu.home.menu.mesh {
	import com.zehfernando.utils.console.error;
	import com.zehfernando.utils.console.warn;

	import flash.geom.Rectangle;
	/**
	 * @author zeh fernando
	 */
	public class MeshInfo {

		// Builds meny system with distribution of nodes
		// DO NOT use this class - one of the subclasses should be used instead

		// Constants
		public static var NODE_RADIUS_STANDARD:Number = 80;
		public static var NODE_DISTANCE_MINIMUM:Number = 5;

		// Properties
		protected var _numNodes:int;					// Number of nodes needed
		protected var parentIds:Vector.<int>;			// List of the parent of each of node (-1 if none)
		protected var groupIds:Vector.<String>;			// List of the group of each of node ("" or null if none)
		protected var customParameters:String;

		protected var minimumNodeDistance:Number;		// Desired minimum distance per node (not counting radius)

		// Instances
		protected var nodes:Vector.<MeshNodeInfo>;
		protected var orderedNodesByFocus:Vector.<MeshNodeInfo>;			// Nodes ordered by focus order, for hardware ADA
		protected var orderedNodesByAppearance:Vector.<MeshNodeInfo>;		// Nodes ordered by appearance order, for show/hide animation
		protected var boundaries:Rectangle;

		protected var paddingTop:Number;
		protected var paddingBottom:Number;
		protected var paddingLeft:Number;
		protected var paddingRight:Number;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function MeshInfo(__numNodes:int, __parentIds:Vector.<int>, __groupIds:Vector.<String>, __customParameters:String) {
			_numNodes = __numNodes;
			parentIds = __parentIds;
			groupIds = __groupIds;
			customParameters = __customParameters;

			setDefaultValues();

			createNodes();
			calculateBoundaries();
			createOrderedLists();
		}

		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		protected function setDefaultValues():void {
			minimumNodeDistance = NODE_DISTANCE_MINIMUM;
			paddingTop = 0;
			paddingBottom = 0;
			paddingLeft = 0;
			paddingRight = 0;
		}

		protected function createNodes():void {
			error("Create the nodes!");
		}

		protected function calculateBoundaries():void {
			// Calculates the boundaries of all node positions (includes radius/node size)
			var minX:Number;
			var maxX:Number;
			var minY:Number;
			var maxY:Number;
			var nodeMinX:Number;
			var nodeMaxX:Number;
			var nodeMinY:Number;
			var nodeMaxY:Number;
			for (var i:int = 0; i < nodes.length; i++) {
				if (nodes[i] != null) {
					nodeMinX = nodes[i].position.x - nodes[i].scale * MeshInfo.NODE_RADIUS_STANDARD;
					nodeMaxX = nodes[i].position.x + nodes[i].scale * MeshInfo.NODE_RADIUS_STANDARD;
					nodeMinY = nodes[i].position.y - nodes[i].scale * MeshInfo.NODE_RADIUS_STANDARD;
					nodeMaxY = nodes[i].position.y + nodes[i].scale * MeshInfo.NODE_RADIUS_STANDARD;
					if (isNaN(minX) || nodeMinX < minX) minX = nodeMinX;
					if (isNaN(maxX) || nodeMaxX > maxX) maxX = nodeMaxX;
					if (isNaN(minY) || nodeMinY < minY) minY = nodeMinY;
					if (isNaN(maxY) || nodeMaxY > maxY) maxY = nodeMaxY;
				}
			}

			minX -= paddingLeft;
			minY -= paddingTop;
			maxX += paddingRight;
			maxY += paddingBottom;

			boundaries = new Rectangle(minX, minY, maxX - minX, maxY - minY);
		}

		protected function createOrderedLists():void {
			// Create differently ordered node lists
			warn("Creating ordered list with default node order");

			// Reusing the default list by default!

			// Create a list of the nodeinfos ordered by the suggested order for hardware ADA
			orderedNodesByFocus = nodes;

			// Create a list of nodeinfos ordered for animation (order of appearance)
			orderedNodesByAppearance = nodes;
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function shuffleNodes():void {
			// Re-shuffle the position of the nodes, if applicable
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function getNodes():Vector.<MeshNodeInfo> {
			return nodes.concat();
		}

		public function getOrderedNodesByFocus():Vector.<MeshNodeInfo> {
			return orderedNodesByFocus.concat();
		}

		public function getOrderedNodesByAppearance():Vector.<MeshNodeInfo> {
			return orderedNodesByAppearance.concat();
		}

		public function getBoundaries():Rectangle {
			return boundaries;
		}

		public function getNodeById(__id:int):MeshNodeInfo {
			for (var i:int = 0; i < nodes.length; i++) {
				if (nodes[i] != null && nodes[i].id == __id) return nodes[i];
			}
			return null;
		}

		public function get numNodes():int {
			return _numNodes;
		}
	}
}