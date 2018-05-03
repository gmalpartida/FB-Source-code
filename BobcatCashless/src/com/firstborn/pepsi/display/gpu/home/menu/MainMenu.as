package com.firstborn.pepsi.display.gpu.home.menu {
	import starling.display.Sprite;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.common.backend.BackendModel;
	import com.firstborn.pepsi.data.home.MenuItemDefinition;
	import com.firstborn.pepsi.data.inventory.Beverage;
	import com.firstborn.pepsi.display.gpu.home.menu.mesh.MeshInfo;
	import com.firstborn.pepsi.display.gpu.home.menu.mesh.MeshInfoCustom;
	import com.firstborn.pepsi.display.gpu.home.menu.mesh.MeshInfoGrid;
	import com.firstborn.pepsi.display.gpu.home.menu.mesh.MeshInfoOrganic;
	import com.firstborn.pepsi.display.gpu.home.menu.mesh.MeshInfoSpiral;
	import com.firstborn.pepsi.display.gpu.home.menu.mesh.MeshNodeInfo;
	import com.firstborn.pepsi.display.gpu.home.view.HomeViewOptions;
	import com.zehfernando.geom.Path;
	import com.zehfernando.signals.SimpleSignal;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.utils.AppUtils;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.RandomGenerator;

	import flash.display.Shape;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * @author zeh fernando
	 */
	public class MainMenu extends Sprite {

		// Constants
		private static var MAXIMUM_SCALE:Number = 3;

		// Layers for all items (so draw calls can be grouped together)
		public static const LAYERS_TOTAL:int = 9;
		public static const LAYER_ID_UNDER_EVERYTHING:int = 0;
		public static const LAYER_ID_GRADIENT:int = 1;
		public static const LAYER_ID_STROKE:int = 2;
		public static const LAYER_ID_BUBBLES:int = 3;
		public static const LAYER_ID_LOGO:int = 4;
		public static const LAYER_ID_MESSAGE_TITLE:int = 5;
		public static const LAYER_ID_MESSAGE_SUBTITLE:int = 6;
        public static const LAYER_ID_PAYMENT:int = 7;
        public static const LAYER_ID_FOCUS:int = 8;
		public static const LAYERS_TOUCHABLE:Vector.<int> = new <int>[LAYER_ID_UNDER_EVERYTHING, LAYER_ID_BUBBLES];

		// Properties
		private var desiredWidth:Number;
		private var desiredHeight:Number;

		private var focusedBeverageId:String;
		private var focusedBlobSprites:BlobSpritesInfo;
		private var focusedBeverageCenter:Point;
		private var focusedBeverageRadius:Number;

		private var _brandTransitionPhase:Number;
		private var _brandTransitionIsHiding:Boolean;
		private var _hiddenTransitionPhase:Number;
		private var _hiddenTransitionIsHiding:Boolean;

		private var isPaused:Boolean;
		private var lastPausedTime:Number;
		private var totalPausedTime:Number;
		private var canDispatchActions:Boolean;

		private var useFocusController:Boolean;
		private var numColsDesired:int;
		private var alignX:Number;
		private var alignY:Number;
		private var layoutType:String;
		private var customLayoutParams:String;

		// Instances
		private var mesh:MeshInfo;
		private var blobsSprites:Vector.<BlobSpritesInfo>;

		private var blobLayers:Vector.<Sprite>;

		private var particleLayer:ParticleLayer;
		private var sequenceLayer:SequenceLayer;

		private var _onTappedBlob:SimpleSignal;

		private var simulatedButton:BlobSpritesInfo;

		private var debugShape:Shape;
		private var realBounds:Rectangle;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function MainMenu(__width:Number, __height:Number, __hasSequencePlayer:Boolean, __layoutType:String, __customLayoutParams:String, __useFocusController:Boolean, __particleNumberScale:Number, __particleSizeScale:Number, __particleAlphaScale:Number, __particleClusterChance:Number, __particleClusterItemsMax:int, __numColsDesired:int, __alignX:Number, __alignY:Number) {
			desiredWidth = __width;
			desiredHeight = __height;
			_brandTransitionPhase = 0;
			isPaused = false;
			lastPausedTime = 0;
			totalPausedTime = 0;
			canDispatchActions = !FountainFamily.configList.getBoolean("debug/ignore-menu-actions");
			layoutType = __layoutType;
			customLayoutParams = __customLayoutParams;
			useFocusController = __useFocusController;
			numColsDesired = __numColsDesired;
			alignX = __alignX;
			alignY = __alignY;

			_onTappedBlob = new SimpleSignal();

			// Data
			blobsSprites = new Vector.<BlobSpritesInfo>();

			// Layers
			blobLayers = new Vector.<Sprite>(LAYERS_TOTAL, true);
			for (var i:int = 0; i < blobLayers.length; i++) {
				blobLayers[i] = new Sprite();
				blobLayers[i].touchable = LAYERS_TOUCHABLE.indexOf(i) > -1;
				addChild(blobLayers[i]);
			}

			// Finally, creates the menu
			createMenu();

			FountainFamily.backendModel.addEventListener(BackendModel.EVENT_RECIPE_AVAILABILITY_CHANGED, onRecipeAvailabilityChanged);

			// Particle layer
			particleLayer = new ParticleLayer(mesh, blobsSprites, this, __particleNumberScale, __particleSizeScale, __particleAlphaScale, __particleClusterChance, __particleClusterItemsMax);
			particleLayer.x = blobLayers[MainMenu.LAYER_ID_LOGO].x;
			particleLayer.y = blobLayers[MainMenu.LAYER_ID_LOGO].y;
			particleLayer.touchable = false;
			addChildAt(particleLayer, 0);

			// Create animation sequences
			if (__hasSequencePlayer && !FountainFamily.DEBUG_DISABLE_SEQUENCE) {
				sequenceLayer = new SequenceLayer(blobsSprites, 1 / scaleX, new Rectangle(0 - blobLayers[MainMenu.LAYER_ID_LOGO].x, 0 - blobLayers[MainMenu.LAYER_ID_LOGO].y, desiredWidth / scaleX, desiredHeight / scaleY));
				sequenceLayer.x = blobLayers[MainMenu.LAYER_ID_LOGO].x;
				sequenceLayer.y = blobLayers[MainMenu.LAYER_ID_LOGO].y;
				addChild(sequenceLayer);

				sequenceLayer.start();
			}

			FountainFamily.looper.onTickedOncePerVisualFrame.add(update);
			FountainFamily.looper.updateOnce(update);
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function createMenu():void {
			// Create mesh definition
			var menuItems:Vector.<MenuItemDefinition> = MenuItemDefinition.getMenuItems();

			// Create a list of parents and group ids to be passed
			var parentList:Vector.<int> = new Vector.<int>();
			var groupList:Vector.<String> = new Vector.<String>();

			var i:int, j:int;
			var allPresentBeverageIds:Vector.<String> = new Vector.<String>();
			for (i = 0; i < menuItems.length; i++) {
				allPresentBeverageIds.push(menuItems[i].beverageId);
			}

			var beverage:Beverage;
			var validParentId:String;
			for (i = 0; i < menuItems.length; i++) {
				beverage = FountainFamily.inventory.getBeverageById(menuItems[i].beverageId);

				// Parent id
				// Consider the first parent id found to be the currently valid parent id
				validParentId = "";
				for (j = 0; j < beverage.parentIds.length; j++) {
					if (allPresentBeverageIds.indexOf(beverage.parentIds[j]) > -1) {
						validParentId = beverage.parentIds[j];
						break;
					}
				}
				parentList.push(MenuItemDefinition.getMenuItemIndexByBeverageId(validParentId));

				// Group
				groupList.push(beverage.groupId);
			}

			switch (layoutType) {
				case HomeViewOptions.MENU_LAYOUT_ORGANIC:
					mesh = new MeshInfoOrganic(menuItems.length, parentList, groupList, customLayoutParams);
					break;
				case HomeViewOptions.MENU_LAYOUT_GRID:
					mesh = new MeshInfoGrid(menuItems.length, parentList, groupList, customLayoutParams, numColsDesired);
					break;
				case HomeViewOptions.MENU_LAYOUT_SPIRAL:
					mesh = new MeshInfoSpiral(menuItems.length, parentList, groupList, customLayoutParams);
					break;
				case HomeViewOptions.MENU_LAYOUT_CUSTOM:
					mesh = new MeshInfoCustom(menuItems.length, parentList, groupList, customLayoutParams);
					break;
			}

			removeAllBlobs();

			// Parameters
			var floatingRadius:Number = MathUtils.map(mesh.numNodes, 8, 12, 3, 1, true);
			var floatingScaleOffset:Number = MathUtils.map(mesh.numNodes, 8, 12, 0.01, 0.005, true);

			// Create all sprites
			var blobSprites:BlobSpritesInfo;
			for (i = 0; i < mesh.numNodes; i ++) {
				blobSprites = new BlobSpritesInfo(mesh.getNodeById(i), i < menuItems.length ? menuItems[i] : null, blobLayers, floatingRadius, floatingScaleOffset, useFocusController);
				blobSprites.isUnderEverything = mesh.getNodeById(i).parentId > -1;
				blobSprites.available = FountainFamily.backendModel.getRecipeAvailability(FountainFamily.inventory.getBeverageById(menuItems[i].beverageId).recipeId) ? 1 : 0;
				blobSprites.onTapped.add(onTappedBlobSprite);
				blobsSprites.push(blobSprites);
			}

			// Set parent blobs if needed
			for (i = 0; i < mesh.numNodes; i ++) {
				if (blobsSprites[i].isUnderEverything) {
					blobsSprites[i].parentBlob = blobsSprites[mesh.getNodeById(i).parentId];
				}
			}

			// Add all the blobs to the focus controller in a way that makes sense
			if (useFocusController) {
				var nodeInfos:Vector.<MeshNodeInfo> = mesh.getOrderedNodesByFocus();
				for (i = 0; i < nodeInfos.length; i++) {
					blobSprites = getBlobSpritesByNodeInfo(nodeInfos[i]);
					FountainFamily.focusController.addElement(blobSprites, blobSprites == blobsSprites[0]);
				}
			}

			calculateBounds();

			if (FountainFamily.DEBUG_DRAW_MENU_AXIS && mesh is MeshInfoSpiral) {
				var path:Path = (mesh as MeshInfoSpiral).getPath();
				debugShape = new flash.display.Shape();
				debugShape.graphics.clear();
				debugShape.graphics.lineStyle(2, 0xff0000, 0.5);
				for (i = 0; i < path.points.length; i++) {
					if (i == 0) {
						debugShape.graphics.moveTo(path.points[i].x, path.points[i].y);
					} else {
						debugShape.graphics.lineTo(path.points[i].x, path.points[i].y);
					}
				}
				redrawDebugShapePosition();
				AppUtils.getStage().addChild(debugShape);
			}
		}

		private function calculateBounds():void {
			var bounds:Rectangle = mesh.getBoundaries();

			// Center content in menu rectangle
			var scaleW:Number = desiredWidth / bounds.width;
			var scaleH:Number = desiredHeight / bounds.height;
			scaleX = scaleY = Math.min(scaleW, scaleH, MAXIMUM_SCALE);

			var w:Number = desiredWidth / scaleX;
			var h:Number = desiredHeight / scaleY;
			var px:Number = MathUtils.map(alignX, -1, 1, 0, w - bounds.width) - bounds.x; // desiredWidth * 0.5 / scaleX - bounds.width * 0.5 - bounds.x
			var py:Number = MathUtils.map(alignY, -1, 1, 0, h - bounds.height) - bounds.y; //desiredHeight * 0.5 / scaleY - bounds.height * 0.5 - bounds.y;
			for (var i:int = 0; i < blobLayers.length; i++) {
				blobLayers[i].x = px;
				blobLayers[i].y = py;
			}

			realBounds = bounds.clone();
			realBounds.x += px;
			realBounds.y += py;
			realBounds.left *= scaleX;
			realBounds.right *= scaleX;
			realBounds.top *= scaleY;
			realBounds.bottom *= scaleY;

			if (debugShape != null) redrawDebugShapePosition();
		}

		private function removeAllBlobs():void {
			while (blobsSprites != null && blobsSprites.length > 0) {
				if (useFocusController) FountainFamily.focusController.removeElement(blobsSprites[0]);
				blobsSprites[0].dispose();
				blobsSprites[0].onTapped.removeAll();
				blobsSprites.splice(0, 1);
			}
		}

		private function update(__currentTimeSeconds:Number, __tickDeltaTimeSeconds:Number, __currentTick:int):void {
			if (visible && !isPaused) {
				var currentTime:Number = __currentTimeSeconds - totalPausedTime;

				// Update all blobs sprites
				for (var i:int = 0; i < blobsSprites.length; i++) {
					blobsSprites[i].update(currentTime, __tickDeltaTimeSeconds, __currentTick);
				}

				if (sequenceLayer != null) sequenceLayer.update(currentTime, __tickDeltaTimeSeconds, __currentTick);
				if (particleLayer != null) particleLayer.update(currentTime, __tickDeltaTimeSeconds, __currentTick);
			}
		}

		private function redrawDebugShapePosition():void {
			// Redraws the position of the debug shape (which contains the path of the spiral menu, for testing)
			var p1:Point = new Point(0, 0);
			var np1:Point = blobLayers[0].localToGlobal(p1);
			var p2:Point = new Point(1, 1);
			var np2:Point = blobLayers[0].localToGlobal(p2);

			debugShape.x = np1.x;
			debugShape.y = np1.y + FountainFamily.platform.mastheadHeightScaled;
			debugShape.scaleX = np2.x - np1.x;
			debugShape.scaleY = np2.y - np1.y;
		}

		private function redrawVisibility():void {
			var wasVisible:Boolean = visible;

			visible = _brandTransitionPhase < 1;

			if (sequenceLayer != null) {
				if (_brandTransitionPhase == 0) sequenceLayer.start();
				if (_brandTransitionPhase == 1) sequenceLayer.stop();
			}

			if (visible && !wasVisible) {
				FountainFamily.looper.updateOnce(update);
			}

			if (debugShape != null) {
				debugShape.alpha = 1 - _brandTransitionPhase;
				debugShape.visible = _brandTransitionPhase < 1;
			}

			if (visible || wasVisible) {

				// Animate all blobs
				var i:int;
				var distance:Number = 1800;
				var p:Point;
				var t:Number = _brandTransitionPhase; // MathUtils.map(_visibility, 1, 1-TIME_ANIMATE_HIDE, 0, 1, true);
				var t2:Number = MathUtils.map(t, 0, 0.6, 0, 1, true);
				var qt:Number = Equations.quadIn(t);
				var qt2:Number = Equations.quadIn(t2);
				var qo:Number = Equations.quintOut(t);
				//var ct:Number = Equations.cubicIn(t);
				var et:Number = Equations.sineInOut(Equations.sineInOut(t));
				//var bt2:Number = Equations.backIn(t);

				if (sequenceLayer != null) sequenceLayer.visibility = MathUtils.map(_brandTransitionPhase, 0, 0.6, 1, 0, true) * MathUtils.map(_hiddenTransitionPhase, 0, 0.6, 1, 0, true);

				var globalPos:Point;
				var showHideScale:Number;		// Scale because it's showing or hiding
				var treatFocusedBlobDifferently:Boolean = focusedBlobSprites != null && _brandTransitionPhase > 0;

				var showHideAnimTime:Number = MathUtils.map(blobsSprites.length, 1, 16, 1, 0.4, true); // percentage of all transition time
				var showHideDelayPerItem:Number = blobsSprites.length > 1 ? (1 - showHideAnimTime) / (blobsSprites.length - 1) : 0;
				var orderedList:Vector.<MeshNodeInfo> = mesh.getOrderedNodesByAppearance();

				for (i = blobsSprites.length - 1; i >= 0; i--) {
					if (_hiddenTransitionPhase == 0) {
						showHideScale = 1;
					} else {
						showHideScale = Equations.quintInOut(_hiddenTransitionPhase == 0 ? 1 : MathUtils.map(Equations.quadInOut(_hiddenTransitionPhase) - (showHideDelayPerItem * orderedList.indexOf(blobsSprites[i].nodeInfo)), 0, showHideAnimTime, 1, 0, true));
					}

					if (!treatFocusedBlobDifferently || blobsSprites[i] != focusedBlobSprites) {
						if (treatFocusedBlobDifferently) {
							// Distance the node from the focused point
							p = Point.polar(distance, Math.atan2(blobsSprites[i].nodeInfo.position.y - focusedBlobSprites.nodeInfo.position.y, blobsSprites[i].nodeInfo.position.x - focusedBlobSprites.nodeInfo.position.x));

							if (FountainFamily.platform.mastheadHeight > 0) {
								// If it has a masthead, try to avoid moving anything up too much
								globalPos = FountainFamily.platform.getUnscaledPoint(blobLayers[MainMenu.LAYER_ID_LOGO].localToGlobal(blobsSprites[i].nodeInfo.position).add(p));
								if (globalPos.y < FountainFamily.platform.mastheadHeight - blobsSprites[i].nodeRadius) {
									p.y += FountainFamily.platform.mastheadHeight - blobsSprites[i].nodeRadius - globalPos.y;
								}
							}

							blobsSprites[i].offsetX = p.x * qt;
							blobsSprites[i].offsetY = p.y * qt;
						} else {
							// Use the same location
							blobsSprites[i].offsetX = 0;
							blobsSprites[i].offsetY = 0;
						}

						blobsSprites[i].alpha = MathUtils.map(qt2, 0, 1, 1, 0) * showHideScale;
						blobsSprites[i].scale = MathUtils.map(qt2, 0, 1, 1, 0) * showHideScale;
						blobsSprites[i].logoAlpha = 1;
					}
				}

				if (treatFocusedBlobDifferently) {
					if (focusedBeverageCenter != null) {
						// Has focused bubble (liquid view)
						p = blobLayers[MainMenu.LAYER_ID_LOGO].globalToLocal(FountainFamily.platform.getScaledPoint(focusedBeverageCenter)).subtract(focusedBlobSprites.nodeInfo.position);
						focusedBlobSprites.offsetX = p.x * et;
						focusedBlobSprites.offsetY = p.y * et;
					} else {
						// No focused bubble (no liquid view)
						focusedBlobSprites.offsetX = 0;
						focusedBlobSprites.offsetY = 0;
					}

					focusedBlobSprites.alpha = MathUtils.map(qt, 0, 1, 1, 0);
					focusedBlobSprites.logoAlpha = MathUtils.map(qo, 0, 1, 1, 0);
					var decreasePhase:Number = 0.3;
					var desiredScale:Number = focusedBeverageRadius / (focusedBlobSprites.nodeInfo.scale * MeshInfo.NODE_RADIUS_STANDARD) / scaleX;
					//log("=> focusedBeverageRadius " + focusedBeverageRadius, desiredScale);

					if (_brandTransitionIsHiding) {
						// Hiding (home to brand)
						focusedBlobSprites.scale = t < decreasePhase ? MathUtils.map(Equations.quintOut(MathUtils.map(t, 0, decreasePhase, 0, 1)), 0, 1, 1, 0.5) : MathUtils.map(Equations.quintInOut(MathUtils.map(t, decreasePhase, 1, 0, 1)), 0, 1, 0.5, desiredScale);
					} else {
						// Showing (brand to home)
						focusedBlobSprites.scale = t < decreasePhase ? MathUtils.map(Equations.expoIn(MathUtils.map(t, 0, decreasePhase, 0, 1)), 0, 1, 1, 0.65) : MathUtils.map(Equations.quintInOut(MathUtils.map(t, decreasePhase, 1, 0, 1)), 0, 1, 0.65, desiredScale);
					}
				}
			}
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onRecipeAvailabilityChanged(__e:Event):void {
			// Update the availability of all blobs
			for (var i:int = 0; i < blobsSprites.length; i ++) {
				blobsSprites[i].available = FountainFamily.backendModel.getRecipeAvailability(blobsSprites[i].beverage.recipeId) ? 1 : 0;
			}
			if (useFocusController) FountainFamily.focusController.checkValidityOfCurrentElement();
		}

		private function onTappedBlobSprite(__blobSpritesInfo:BlobSpritesInfo):void {
			if (canDispatchActions) _onTappedBlob.dispatch(__blobSpritesInfo.menuItemInfo.beverageId);
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function setFocusedBeverageId(__beverageId:String):void {
			// Sets the beverage id that should be focused when animating out

			if (focusedBlobSprites != null) {
				focusedBlobSprites.isFocused = false;
				focusedBlobSprites = null;
			}

			// Set the "focused" beverage id
			focusedBeverageId = __beverageId;

			// Find focused beverage info
			focusedBlobSprites = getBlobSpriteInfoFromBeverageId(focusedBeverageId);
			if (focusedBlobSprites != null) focusedBlobSprites.isFocused = true;
		}

		public function setFocusedBeverageCenter(__center:Point, __radius:Number):void {
			// Sets where the center beverage point should be located (stage scale) when focused
			focusedBeverageCenter = __center;
			focusedBeverageRadius = __radius;
		}

//		public function show(__delay:Number):Number {
//			// Animate everything, going from the brand page to the home menu
//			// Returns the time it'll take to show everything
//
//			var i:int;
//
//			// Animate all blobs
//			ZTween.remove(focusedBlobSprites, "offsetX", "offsetY", "alpha", "scale");
//			ZTween.add(focusedBlobSprites, {offsetX:0, offsetY:0}, {time:TIME_ANIMATE_BLOB_IN, delay:__delay, transition:Equations.quintInOut});
//			ZTween.add(focusedBlobSprites, {alpha:1}, {time:TIME_ANIMATE_BLOB_IN, delay:__delay, transition:Equations.cubicOut});
//			ZTween.add(focusedBlobSprites, {scale:1}, {time:TIME_ANIMATE_BLOB_IN, delay:__delay, transition:Equations.backOut});
//
//			var ttime:Number = 0;
//			var timeDelay:Number = MathUtils.map(blobsSprites.length, 8, 16, TIME_ANIMATE_BLOB_IN_DELAY, TIME_ANIMATE_BLOB_IN_DELAY * 0.75, true);
//
//			ttime += timeDelay;
//
//			for (i = 0; i < blobsSprites.length; i++) {
//				if (blobsSprites[i] != focusedBlobSprites) {
//					ZTween.remove(blobsSprites[i], "offsetX", "offsetY", "alpha", "scale");
//					ZTween.add(blobsSprites[i], {offsetX:0, offsetY:0}, {time:TIME_ANIMATE_BLOB_IN, delay:ttime + __delay, transition:Equations.quintOut});
//					ZTween.add(blobsSprites[i], {alpha:1}, {time:TIME_ANIMATE_BLOB_IN, delay:ttime + __delay, transition:Equations.cubicOut});
//					ZTween.add(blobsSprites[i], {scale:1}, {time:TIME_ANIMATE_BLOB_IN * 0.75, delay:ttime + TIME_ANIMATE_BLOB_IN * 0.25 + __delay, transition:Equations.backOut});
//					ttime += timeDelay;
//				}
//			}
//
//			ZTween.remove(this, "visibility");
//			ZTween.add(this, {visibility:1}, {time:TIME_ANIMATE_BLOB_IN, delay:__delay});
//
//			return ttime + TIME_ANIMATE_BLOB_IN;
//		}
//
//		public function hide(__delay:Number):Number {
//			// Animate everything, going from the home menu to the brand page
//			// Returns the time it'll take to show everything
//
//			var p:Point;
//			var i:int;
//
//			// Animate all blobs
//			var ttime:Number = 0;
//			var timeDelay:Number = MathUtils.map(blobsSprites.length, 8, 16, TIME_ANIMATE_BLOB_OUT_DELAY, TIME_ANIMATE_BLOB_OUT_DELAY * 0.75, true);
//			var distance:Number = 1000 * FountainFamily.platform.densityScale;
//			for (i = blobsSprites.length - 1; i >= 0; i--) {
//				if (blobsSprites[i] != focusedBlobSprites) {
//					p = Point.polar(distance, Math.atan2(blobsSprites[i].nodeInfo.position.y - focusedBlobSprites.nodeInfo.position.y, blobsSprites[i].nodeInfo.position.x - focusedBlobSprites.nodeInfo.position.x));
//					ZTween.remove(blobsSprites[i], "offsetX", "offsetY", "alpha", "scale");
//					ZTween.add(blobsSprites[i], {offsetX:p.x, offsetY:p.y}, {time:TIME_ANIMATE_BLOB_OUT, delay:ttime + __delay, transition:Equations.quintIn});
//					ZTween.add(blobsSprites[i], {alpha:0}, {time:TIME_ANIMATE_BLOB_OUT, delay:ttime + __delay, transition:Equations.cubicIn});
//					ZTween.add(blobsSprites[i], {scale:0.5}, {time:TIME_ANIMATE_BLOB_OUT * 0.75, delay:ttime + __delay, transition:Equations.backIn});
//					ttime += timeDelay;
//				}
//			}
//
//			ttime += TIME_ANIMATE_BLOB_OUT * 0.3; // Just so they can all get out in time
//			p = layerBlobLogos.globalToLocal(focusedBeverageCenter).subtract(focusedBlobSprites.nodeInfo.position);
//			ZTween.remove(focusedBlobSprites, "offsetX", "offsetY", "alpha", "scale");
//			ZTween.add(focusedBlobSprites, {offsetX:p.x, offsetY:p.y}, {time:TIME_ANIMATE_BLOB_OUT, delay:ttime + __delay, transition:Equations.quintInOut});
//			ZTween.add(focusedBlobSprites, {alpha:0}, {time:TIME_ANIMATE_BLOB_OUT, delay:ttime + __delay, transition:Equations.quintIn});
//			ZTween.add(focusedBlobSprites, {scale:0.5}, {time:TIME_ANIMATE_BLOB_OUT, delay:ttime + __delay, transition:Equations.quintInOut});
//			ttime += timeDelay;
//
//			ZTween.remove(this, "visibility");
//			ZTween.add(this, {visibility:0}, {time:TIME_ANIMATE_BLOB_OUT, delay:ttime + __delay});
//
//			return ttime + TIME_ANIMATE_BLOB_OUT;
//		}

		public function language(value: uint) : void {
			for(var i: uint = 0; i < blobsSprites.length; i ++) blobsSprites[i].language(value);
		}

		public function simulatePickButton():void {
			// Decide a button to pick for simulated events

			// Skip unavailable buttons
			simulatedButton = null;
			var tries:int = 0;
			while ((simulatedButton == null || simulatedButton.available != 1) && tries < 10) {
				simulatedButton = blobsSprites[RandomGenerator.getInIntegerRange(0, blobsSprites.length-1)];
				tries++;
			}
		}

		public function simulateEnterDown():void {
			simulatedButton.simulateEnterDown();
		}

		public function simulateEnterUp():void {
			simulatedButton.simulateEnterUp();
		}

		public function getSimulatedButtonX():Number {
			return simulatedButton == null ? 0 : x + (simulatedButton.nodeInfo.position.x + blobLayers[MainMenu.LAYER_ID_LOGO].x) * scaleX;
		}

		public function getSimulatedButtonY():Number {
			return simulatedButton == null ? 0 : y + (simulatedButton.nodeInfo.position.y + blobLayers[MainMenu.LAYER_ID_LOGO].y) * scaleY;
		}

		public function getBlobSpritesByNodeInfo(__nodeInfo:MeshNodeInfo):BlobSpritesInfo {
			// Find the blobSprites instance related to a given nodeInfo
			for each (var blobSprites:BlobSpritesInfo in blobsSprites) {
				if (blobSprites.nodeInfo == __nodeInfo) return blobSprites;
			}
			return null;
		}

		public function setButtonsEnabled(__enabled:Boolean):void {
			// Updates whether the buttons are focusable or not

			var enabledValue:Number = __enabled ? 1 : 0;

			var nodeInfo:MeshNodeInfo;
			for (var i:int = 0; i < mesh.numNodes; i++) {
				nodeInfo = mesh.getNodeById(i);
				if (nodeInfo != null) {
					getBlobSpritesByNodeInfo(nodeInfo).enabled = enabledValue;
				}
			}
		}

		public function getFocusedBlobRect():Rectangle {
			// Finds the rectangle that the focused item is ocupying, in GLOBAL space
			var radius:Number = focusedBlobSprites.nodeInfo.scale * focusedBlobSprites.scale * MeshInfo.NODE_RADIUS_STANDARD;

			var p:Point = FountainFamily.platform.getUnscaledPoint(blobLayers[MainMenu.LAYER_ID_LOGO].localToGlobal(new Point(focusedBlobSprites.nodeInfo.position.x - radius + focusedBlobSprites.offsetX, focusedBlobSprites.nodeInfo.position.y - radius + focusedBlobSprites.offsetY)));
			var rect:Rectangle = new Rectangle(p.x, p.y, radius * 2 * scaleX, radius * 2 * scaleY);

			return rect;
		}

		public function getRealBounds():Rectangle {
			// Retuns the boundaries of the whole menu
			return realBounds;
		}

		public function recreateRandomElements():void {
			if (FountainFamily.DEBUG_ALWAYS_SHUFFLE_MENU) {
			//if (Math.random() < 0.1 || FountainFamily.DEBUG_ALWAYS_SHUFFLE_MENU) {
				// 10% chance of moving stuff around in the main menu
				mesh.shuffleNodes();
				calculateBounds();
				redrawVisibility();
				if (sequenceLayer != null) {
					sequenceLayer.x = blobLayers[MainMenu.LAYER_ID_LOGO].x;
					sequenceLayer.y = blobLayers[MainMenu.LAYER_ID_LOGO].y;
				}
				particleLayer.x = blobLayers[MainMenu.LAYER_ID_LOGO].x;
				particleLayer.y = blobLayers[MainMenu.LAYER_ID_LOGO].y;
			}
			particleLayer.recreate();
		}

		public function pause():void {
			// Pauses all looper-based animation
			if (!isPaused) {
				lastPausedTime = FountainFamily.looper.currentTimeSeconds;
				isPaused = true;
			}
		}

		public function resume():void {
			// Resumes all looper-based animation
			if (isPaused) {
				totalPausedTime += FountainFamily.looper.currentTimeSeconds - lastPausedTime;
				isPaused = false;
			}
		}

		override public function dispose():void {
			_onTappedBlob.removeAll();
			_onTappedBlob = null;

			removeChild(sequenceLayer, true);
			sequenceLayer = null;

			removeChild(particleLayer, true);
			particleLayer = null;

			for (var i:int = 0; i < blobLayers.length; i++) removeChild(blobLayers[i], true);
			blobLayers = null;

			FountainFamily.backendModel.removeEventListener(BackendModel.EVENT_RECIPE_AVAILABILITY_CHANGED, onRecipeAvailabilityChanged);

			removeAllBlobs();
			blobsSprites = null;

			mesh = null;

			FountainFamily.looper.onTickedOncePerVisualFrame.remove(update);

			super.dispose();
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get onTappedBlob():SimpleSignal {
			return _onTappedBlob;
		}

		public function get brandTransitionPhase():Number {
			return _brandTransitionPhase;
		}
		public function set brandTransitionPhase(__value:Number):void {
			if (_brandTransitionPhase != __value) {
				_brandTransitionPhase = __value;
				redrawVisibility();
			}
		}

		public function get brandTransitionIsHiding():Boolean {
			return _brandTransitionIsHiding;
		}
		public function set brandTransitionIsHiding(__value:Boolean):void {
			_brandTransitionIsHiding = __value;
		}

		public function get hiddenTransitionPhase():Number {
			return _hiddenTransitionPhase;
		}
		public function set hiddenTransitionPhase(__value:Number):void {
			if (_hiddenTransitionPhase != __value) {
				_hiddenTransitionPhase = __value;
				redrawVisibility();
			}
		}

		public function get hiddenTransitionIsHiding():Boolean {
			return _hiddenTransitionIsHiding;
		}
		public function set hiddenTransitionIsHiding(__value:Boolean):void {
			_hiddenTransitionIsHiding = __value;
		}

		public function getBlobSpriteInfoFromBeverageId(__beverageId:String):BlobSpritesInfo {
			// Return the BlovSpriteInfo that has a certain beverage id
			var i:int;
			for (i = 0; i < blobsSprites.length; i++) {
				if (blobsSprites[i].menuItemInfo.beverageId == __beverageId) {
					return blobsSprites[i];
				}
			}
			return null;
		}

		override public function set x(__value:Number):void {
			super.x = __value;
			if (debugShape != null) redrawDebugShapePosition();
		}

		override public function set y(__value:Number):void {
			super.y = __value;
			if (debugShape != null) redrawDebugShapePosition();
		}

		override public function set scaleX(__value:Number):void {
			super.scaleX = __value;
			if (debugShape != null) redrawDebugShapePosition();
		}

		override public function set scaleY(__value:Number):void {
			super.scaleY = __value;
			if (debugShape != null) redrawDebugShapePosition();
		}
	}
}
