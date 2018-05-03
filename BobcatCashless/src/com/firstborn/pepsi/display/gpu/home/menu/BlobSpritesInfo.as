package com.firstborn.pepsi.display.gpu.home.menu {
	import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.filters.ColorMatrixFilter;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.data.AnimationDefinition;
	import com.firstborn.pepsi.data.home.MenuItemDefinition;
	import com.firstborn.pepsi.data.inventory.Beverage;
	import com.firstborn.pepsi.display.gpu.common.TextureLibrary;
	import com.firstborn.pepsi.display.gpu.home.menu.mesh.MeshInfo;
	import com.firstborn.pepsi.display.gpu.home.menu.mesh.MeshNodeInfo;
	import com.firstborn.pepsi.events.TouchHandler;
	import com.zehfernando.controllers.focus.FocusController;
	import com.zehfernando.controllers.focus.IFocusable;
	import com.zehfernando.display.starling.AnimatedImage;
	import com.zehfernando.signals.SimpleSignal;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.transitions.ZTween;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.RandomGenerator;
	import com.zehfernando.utils.console.warn;

	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * @author zeh fernando
	 */
	public class BlobSpritesInfo implements IFocusable {

		// Easier control for a node's textures
		// Normally this would be a single sprite, but it's done as a normal class just so the same sprite types (e.g. solid or stroke) can be in the same layer and
		// Draw calls are kept to a minimum

		// Constants
		private static const BUBBLES_FRAMES_PER_SECOND:int = 30;			// FPS for the bubbles animation
		private static const TIME_ANIMATE_PRESS:Number = 0.5;
		private static const TIME_ANIMATE_RELEASE:Number = 1.2;
		private static const LOGO_SCALE:Number = 0.55;
		private static const MESSAGE_SCALE:Number = 0.55;
		private static const MESSAGE_SPACING:Number = 15;
		private static const IMPACT_FORCE:Number = 10;						// Maximum force of impacts, in pixels
		private static const IMPACT_DECAY_TIME:Number = 2;					// Time, in seconds, that it takes for an impact to decay
		private static const IMPACT_DECAY_CYCLES:Number = 2;				// Cycles (2 waves) of impact motion

		private static const LUMA_R:Number = 0.2126;
		private static const LUMA_G:Number = 0.7152;
		private static const LUMA_B:Number = 0.0722;

		// Properties
		private var _offsetX:Number;										// Offset due to external influences
		private var _offsetY:Number;										// Offset due to external influences
		private var _offsetXFloat:Number;									// Offset due to floating
		private var _offsetYFloat:Number;									// Offset due to floating
		private var _offsetForceImpact:Number;								// Offset due to impact
		private var _offsetAngleImpact:Number;								// Offset due to impact
		private var _offsetXImpact:Number;									// Offset due to impact
		private var _offsetYImpact:Number;									// Offset due to impact
		private var _alpha:Number;
		private var _logoAlpha:Number;
		private var _bubbleAlpha:Number;
		private var _scale:Number;

		private var currentTime:Number;
		private var impactStartTime:Number;

		private var _pressed:Number;
		private var _enabled:Number;
		private var _available:Number;										// Whether this blob is available (1) or not (..0)
		private var _isUnderEverything:Boolean;								// Whether this blob is under everything (because it has a "parent")
		private var _keyboardFocused:Number;
		private var _isFocused:Boolean;
		private var _wasClickSimulated:Boolean;

		// Instances
		private var _parentBlob:BlobSpritesInfo;							// "Parent" blob that is always on top of this
		private var desiredParent:Sprite;

		private var _nodeInfo:MeshNodeInfo;
		private var _menuItemInfo:MenuItemDefinition;
		private var _beverage:Beverage;

		private var floatingRadius:Number;
		private var floatingScaleOffset:Number;
		private var drawFocusImage:Boolean;

		private var gradientImage:Image;
		private var strokeImage:Image;
		private var bubbleImage:AnimatedImage;
		private var logoImage:Image;
		private var focusImage:Image;

		private var gradientImageSpeed:Number;
		private var strokeImageSpeed:Number;
		private var focusImageSpeed:Number;

		private var touchHandler:TouchHandler;

		private var blobLayers:Vector.<Sprite>;

		private var _onTapped:SimpleSignal;

		private var blobFilter:ColorMatrixFilter;



		// Temp
		private var imageScaleGradient:Number;
		private var imageScaleStroke:Number;
		private var imageScaleBubble:Number;
		private var imageScaleLogo:Number;
		private var imageScaleMessage:Number;
		private var imageScaleGlobal:Number;

		private var messageTitleImage: Vector.<Image> = new Vector.<Image>();
		private var messageSubtitleImage: Vector.<Image> = new Vector.<Image>();
		private var messageTitleImageOffsetY: Vector.<Number> = new Vector.<Number>();
		private var messageSubtitleImageOffsetY: Vector.<Number> = new Vector.<Number>();

        private var paymentMessage: Vector.<Image> = new Vector.<Image>();

        private var USE_FREE_MESSAGE : Boolean = false;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function BlobSpritesInfo(__nodeInfo:MeshNodeInfo, __menuItemInfo:MenuItemDefinition, __blobLayers:Vector.<Sprite>, __floatingRadius:Number, __floatingScaleOffset:Number, __drawFocusImage:Boolean) {
			_nodeInfo = __nodeInfo;
			_menuItemInfo = __menuItemInfo;
			_isFocused = false;
			drawFocusImage = __drawFocusImage;

			impactStartTime = 0;
			currentTime = 0;

			desiredParent = null;

			floatingRadius = __floatingRadius;
			floatingScaleOffset = __floatingScaleOffset;

			blobLayers = __blobLayers;

			if (_menuItemInfo == null) {
				warn("Error: no menu item info found for node " + __nodeInfo.id + "! Simulating with random properties...");
				_beverage = new Beverage();
			} else {
				_beverage = FountainFamily.inventory.getBeverageById(_menuItemInfo.beverageId);
			}

			_onTapped = new SimpleSignal();
			_pressed = 0;
			_enabled = 1;
			_available = 1;
			_keyboardFocused = 0;
			_offsetX = 0;
			_offsetY = 0;
			_offsetXFloat = 0;
			_offsetYFloat = 0;
			_offsetXImpact = 0;
			_offsetYImpact = 0;
			_offsetAngleImpact = 0;
			_offsetForceImpact = 0;
			_alpha = 1;
			_logoAlpha = 1;
			_bubbleAlpha = _beverage.getDesign().alphaCarbonation;
			_scale = 1;

            USE_FREE_MESSAGE = FountainFamily.PAYMENT_ENABLED && !_beverage.requiresPayment;

//			solidImage = new Image(textureLibrary.getBlobSolidTexture());
//			solidImage.pivotX = solidImage.width * 0.5;
//			solidImage.pivotY = solidImage.height * 0.5;
//			solidImage.color = RandomGenerator.getColor();
//			solidImage.smoothing = FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_BLOB_SHAPES).smoothing;
//			__layerBlobSolids.addChild(solidImage);

			gradientImage = new Image(FountainFamily.textureLibrary.getBlobGradientTexture(_beverage.getDesign().imageGradient));
			gradientImage.touchable = false;
			gradientImage.pivotX = gradientImage.width * 0.5;
			gradientImage.pivotY = gradientImage.height * 0.5;
			gradientImage.smoothing = FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_BLOB_SHAPES_GRADIENT).smoothing;

			strokeImage = new Image(FountainFamily.textureLibrary.getBlobStrokeTexture());
			strokeImage.touchable = false;
			strokeImage.pivotX = strokeImage.width * 0.5;
			strokeImage.pivotY = strokeImage.height * 0.5;
			strokeImage.color = _beverage.getDesign().colorStroke;
			strokeImage.smoothing = FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_BLOB_SHAPES_STROKE).smoothing;

			var bubbleAnimDef:AnimationDefinition = FountainFamily.textureLibrary.getBlobBubblesAnimationDefinition();
			bubbleImage = new AnimatedImage(FountainFamily.textureLibrary.getBlobBubblesTexture(), bubbleAnimDef.frameWidth, bubbleAnimDef.frameHeight, bubbleAnimDef.frames, bubbleAnimDef.fps);
			bubbleImage.blendMode = BlendMode.ADD;
			//bubbleImage.touchable = false;
			//bubbleImage.alpha = 0.2; // applied later
			//bubbleImage.smoothing = TextureSmoothing.NONE;
			bubbleImage.pivotX = bubbleImage.texture.width * 0.5; // This is kinda wrong? Not sure why it's working
			bubbleImage.pivotY = bubbleImage.texture.height * 0.5;

			logoImage = new Image(FountainFamily.textureLibrary.getBlobLogoTexture(_beverage.getDesign().imageLogo));
            trace(logoImage.width, logoImage.height);
			logoImage.touchable = false;
			logoImage.pivotX = logoImage.width * 0.5;
			logoImage.pivotY = logoImage.height * 0.5;
			logoImage.smoothing = FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_BLOB_LOGOS).smoothing;

			var i : uint = 0;
			for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
				messageTitleImage.push(new Image(FountainFamily.textureLibrary.getMessageUnavailableTitleTexture()[i]));
				messageTitleImage[i].color = _beverage.getDesign().colorMessageTitleInstance.toRRGGBB();
				messageTitleImage[i].touchable = false;
				messageTitleImage[i].pivotX = messageTitleImage[i].width * 0.5;
				messageTitleImage[i].pivotY = messageTitleImage[i].height * 0.5;
				messageTitleImage[i].smoothing = FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_GENERIC_TEXT).smoothing;
				messageTitleImage[i].visible = 0;

				messageSubtitleImage.push(new Image(FountainFamily.textureLibrary.getMessageUnavailableSubtitleTexture()[i]));
				messageSubtitleImage[i].color = _beverage.getDesign().colorMessageSubtitleInstance.toRRGGBB();
				messageSubtitleImage[i].touchable = false;
				messageSubtitleImage[i].pivotX = messageSubtitleImage[i].width * 0.5;
				messageSubtitleImage[i].pivotY = messageSubtitleImage[i].height * 0.5;
				messageSubtitleImage[i].smoothing = FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_GENERIC_TEXT).smoothing;
				messageSubtitleImage[i].visible = 0;

				messageTitleImageOffsetY.push((messageTitleImage[i].height + MESSAGE_SPACING + messageSubtitleImage[i].height) * -0.5 + messageTitleImage[i].height * 0.5);
				messageSubtitleImageOffsetY.push((messageTitleImage[i].height + MESSAGE_SPACING + messageSubtitleImage[i].height) * 0.5 - messageSubtitleImage[i].height * 0.5);
			}


            //Message for the cashless version
            if(USE_FREE_MESSAGE) {
                for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
                    paymentMessage.push(new Image(FountainFamily.textureLibrary.getMessagePayment()[i]));
                    paymentMessage[i].color = _beverage.getDesign().freePaymentCopyColor;
                    paymentMessage[i].touchable = false;
                    paymentMessage[i].pivotX = paymentMessage[i].width * 0.5;
                    paymentMessage[i].pivotY = paymentMessage[i].height * 0.5;
                    paymentMessage[i].smoothing = FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_GENERIC_TEXT).smoothing;
                    paymentMessage[i].visible = 1;
                }
            }

			if (drawFocusImage) {
				focusImage = new Image(FountainFamily.textureLibrary.getBlobFocusTexture());
				focusImage.touchable = false;
				focusImage.pivotX = focusImage.width * 0.5;
				focusImage.pivotY = focusImage.height * 0.5;
				//focusImage.color = _beverage.design.colorStroke;
				focusImage.smoothing = FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_BLOB_SHAPES_FOCUS).smoothing;
			}

			var direction:Boolean = RandomGenerator.getBoolean();
			gradientImageSpeed = (direction ? 1 : -1) * RandomGenerator.getInRange(12, 18);
			strokeImageSpeed = (!direction ? 1 : -1) * RandomGenerator.getInRange(12, 18);
			focusImageSpeed = (!direction ? 1 : -1) * RandomGenerator.getInRange(12, 18);

			touchHandler = new TouchHandler();
			touchHandler.onTapped.add(onBlobTapped);
			touchHandler.onPressed.add(onBlobPressed);
			touchHandler.onReleased.add(onBlobReleased);
			touchHandler.onPressCanceled.add(onBlobPressCanceled);
			touchHandler.attachTo(bubbleImage);

			applyAvailable();
			setGrayscaleLevel(0);

			// Add all the children to the display list
			addChildrenToSprite();
		}

		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function applyAvailable():void {
			update(currentTime, 0, 0);
		}

		private function setGrayscaleLevel(__level:Number):void {
			// Sets the tinting of the current sequence
			// This was previously used for "disabling" the item (it'd become gray), but it was later replaced with the "out of stock" message

			if (__level == 0) {
				blobFilter = null;
			} else {
				var br:Number = __level * 190;
				var nb:Number = 1-(br / 255); // Amount of original color due to brightness
				var desat:Number = MathUtils.map(__level, 0, 1, 0, 1);
				var co:Number = desat * nb; // Other channels

				// Apply luminosity-based desaturation and brightness addition
				var matrix:Vector.<Number> = new <Number>[
					(1 - (desat * (1-LUMA_R))) * nb, co * LUMA_G, co * LUMA_B, 0, br,
					co * LUMA_R, (1 - (desat * (1-LUMA_G))) * nb, co * LUMA_B, 0, br,
					co * LUMA_R, co * LUMA_G, (1 - (desat * (1-LUMA_B))) * nb, 0, br,
					0, 0, 0, 1, 0
				];

				if (blobFilter == null) {
					blobFilter = new ColorMatrixFilter(matrix);
				} else {
					blobFilter.matrix = matrix;
				}
			}

			if (gradientImage.filter != blobFilter) {
				gradientImage.filter = blobFilter;
				strokeImage.filter = blobFilter;
				bubbleImage.filter = blobFilter;
				logoImage.filter = blobFilter;

				for(var i : uint = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
					messageTitleImage[i].filter = blobFilter;
					messageSubtitleImage[i].filter = blobFilter;
				}

                if(USE_FREE_MESSAGE) {
                    for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
                        paymentMessage[i].filter = blobFilter;
                    }
                }

			}

		}

		private function applyDesiredParent():void {

			var i : uint = 0;
			if (Boolean(desiredParent)) {
				// Add to a specific parent
				desiredParent.addChild(gradientImage);
				desiredParent.addChild(strokeImage);
				desiredParent.addChild(bubbleImage);
				desiredParent.addChild(logoImage);

				for(i = 0; i < messageTitleImage.length; i ++) {
					desiredParent.addChild(messageTitleImage[i]);
					desiredParent.addChild(messageSubtitleImage[i]);
				}

                if(USE_FREE_MESSAGE ) {
                    desiredParent.addChild(paymentMessage[i]);
                }

				if (focusImage != null) desiredParent.addChild(focusImage);
			} else {
				if (isUnderEverything) {
					// Actually renders under everything, for animations
					blobLayers[MainMenu.LAYER_ID_UNDER_EVERYTHING].addChild(gradientImage);
					blobLayers[MainMenu.LAYER_ID_UNDER_EVERYTHING].addChild(strokeImage);
					blobLayers[MainMenu.LAYER_ID_UNDER_EVERYTHING].addChild(bubbleImage);
					blobLayers[MainMenu.LAYER_ID_UNDER_EVERYTHING].addChild(logoImage);

					for(i = 0; i < messageTitleImage.length; i ++) {
						blobLayers[MainMenu.LAYER_ID_UNDER_EVERYTHING].addChild(messageTitleImage[i]);
						blobLayers[MainMenu.LAYER_ID_UNDER_EVERYTHING].addChild(messageSubtitleImage[i]);

                        if(USE_FREE_MESSAGE ) {
                            blobLayers[MainMenu.LAYER_ID_UNDER_EVERYTHING].addChild(paymentMessage[i]);
                        }
					}

					if (focusImage != null) blobLayers[MainMenu.LAYER_ID_UNDER_EVERYTHING].addChild(focusImage);
				} else {
				// Uses the main layers (save draws)
					blobLayers[MainMenu.LAYER_ID_GRADIENT].addChild(gradientImage);
					blobLayers[MainMenu.LAYER_ID_STROKE].addChild(strokeImage);
					blobLayers[MainMenu.LAYER_ID_BUBBLES].addChild(bubbleImage);
					blobLayers[MainMenu.LAYER_ID_LOGO].addChild(logoImage);

					for(i = 0; i < messageTitleImage.length; i ++) {
						blobLayers[MainMenu.LAYER_ID_MESSAGE_TITLE].addChild(messageTitleImage[i]);
						blobLayers[MainMenu.LAYER_ID_MESSAGE_SUBTITLE].addChild(messageSubtitleImage[i]);

                        if(USE_FREE_MESSAGE ) {
                            blobLayers[MainMenu.LAYER_ID_PAYMENT].addChild(paymentMessage[i]);
                        }
					}

					if (focusImage != null) blobLayers[MainMenu.LAYER_ID_FOCUS].addChild(focusImage);
				}
			}
		}

		private function wasLastTouchInsideCircle():Boolean {
			// Returns true if it is assumed that the last touch was inside a certain radius of the circle; that way, it won't catch touches that happen to be in the texture but don't belong to the button
			return Point.distance(logoImage.parent.globalToLocal(touchHandler.getLastTouchPoint()), new Point(logoImage.x, logoImage.y)) < nodeRadius * 0.75;
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onBlobTapped():void {
			if (_available == 1 && _enabled == 1) {
				if (wasLastTouchInsideCircle() || wasClickSimulated()) _onTapped.dispatch(this);
			}
		}

		private function onBlobPressed():void {
			if (_available == 1 && _enabled == 1 && (wasLastTouchInsideCircle() || wasClickSimulated())) {
				if (!_wasClickSimulated) FountainFamily.focusController.executeCommand(FocusController.COMMAND_DEACTIVATE);
				ZTween.remove(this, "pressed");
				ZTween.add(this, {pressed:1}, {time:TIME_ANIMATE_PRESS, transition:Equations.expoOut});
			}
		}

		private function onBlobReleased():void {
			ZTween.remove(this, "pressed");
			ZTween.add(this, {pressed:0}, {time:TIME_ANIMATE_RELEASE, transition:Equations.elasticOut});
		}

		private function onBlobPressCanceled():void {
			ZTween.remove(this, "pressed");
			ZTween.add(this, {pressed:0}, {time:TIME_ANIMATE_RELEASE, transition:Equations.elasticOut});
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function language(value : uint) : void {
			for(var i : uint = 0; i < messageTitleImage.length; i ++) {
				messageTitleImage[i].visible = 0;
				messageSubtitleImage[i].visible = 0;
                if(USE_FREE_MESSAGE) {
                    paymentMessage[i].visible = 0;
                }
			}
			messageTitleImage[value].visible = 1;
			messageSubtitleImage[value].visible = 1;
            if(USE_FREE_MESSAGE) {
                paymentMessage[value].visible = 1;
            }
		}

		public function addChildrenToSprite(__sprite:Sprite = null):void {
			// Add all the children of this blob sprites info to a given sprite
			// If no parent sprite is passed, it is reset, adding the children to the default layers for speed
			desiredParent = __sprite;
			applyDesiredParent();

			// Also move the parent blob to the top, if it has one
			if (_parentBlob != null) {
				_parentBlob.addChildrenToSprite(__sprite);
			}
		}

		public function update(__currentTimeSeconds:Number, __tickDeltaTimeSeconds:Number, __currentTick:int):void {
			// Updates the visible representation of a node with the attributes of the mesh node

			var s:Number = __currentTimeSeconds;
			currentTime = __currentTimeSeconds;

			var a:Number = _alpha; // * MathUtils.map(_available, 0, 1, 0.5, 1);

			_offsetXFloat = Math.sin(s * gradientImageSpeed / 10) * floatingRadius;
			_offsetYFloat = Math.cos(s * strokeImageSpeed / 10) * floatingRadius;

			var impactScale:Number = 1;
			if (impactStartTime > 0 && __currentTimeSeconds < impactStartTime + IMPACT_DECAY_TIME) {
				// Has an impact taking place
				var impactPhase:Number = MathUtils.map(__currentTimeSeconds, impactStartTime, impactStartTime + IMPACT_DECAY_TIME, 0, 1, true);
				var impactPoint:Point = Point.polar((1 - impactPhase) * _offsetForceImpact * Math.sin(impactPhase * Math.PI * 2 * IMPACT_DECAY_CYCLES), _offsetAngleImpact);
				impactScale += MathUtils.map(impactPhase, 1, 0, 0, Math.sin(impactPhase * Math.PI * 2 * IMPACT_DECAY_CYCLES) * -0.01 * (_offsetForceImpact / IMPACT_FORCE));
				_offsetXImpact = impactPoint.x;
				_offsetYImpact = impactPoint.y;
			} else {
				// No impact
				_offsetXImpact = 0;
				_offsetYImpact = 0;
			}

			var tOffsetX:Number = _offsetXFloat + _offsetX + _offsetXImpact;
			var tOffsetY:Number = _offsetYFloat + _offsetY + _offsetYImpact;
			var scaleOffset:Number = floatingScaleOffset * Math.sin(s * gradientImageSpeed / 6);

			imageScaleGradient = ((MeshInfo.NODE_RADIUS_STANDARD * 2) / (FountainFamily.textureLibrary.blobGradientTextureResolution - TextureLibrary.BLOB_TEXTURE_MARGIN) * _nodeInfo.scale) + scaleOffset;
			imageScaleStroke = ((MeshInfo.NODE_RADIUS_STANDARD * 2) / (FountainFamily.textureLibrary.blobStrokeTextureResolution - TextureLibrary.BLOB_TEXTURE_MARGIN) * _nodeInfo.scale) + scaleOffset;
			imageScaleBubble = ((MeshInfo.NODE_RADIUS_STANDARD * 2) / (FountainFamily.textureLibrary.blobBubbleTextureResolution - TextureLibrary.BLOB_TEXTURE_MARGIN) * _nodeInfo.scale) + scaleOffset;
			imageScaleLogo = (((MeshInfo.NODE_RADIUS_STANDARD * 2) / (FountainFamily.textureLibrary.getBlobLogoTextureResolution(_beverage.getDesign().imageLogoIsBig) - TextureLibrary.BLOB_TEXTURE_MARGIN) * _nodeInfo.scale) + scaleOffset) * _nodeInfo.logoScaleMultiplier * _beverage.getDesign().scaleLogo;
			imageScaleMessage = MathUtils.map(_nodeInfo.scale, 2, 1, 1.4, 0.9) + scaleOffset;
			imageScaleGlobal = MathUtils.map(_pressed, 0, 1, 1, 0.95) * _scale * impactScale;

			gradientImage.alpha = a;
			gradientImage.x = _nodeInfo.position.x + tOffsetX;
			gradientImage.y = _nodeInfo.position.y + tOffsetY;
			gradientImage.scaleX = gradientImage.scaleY = imageScaleGradient * imageScaleGlobal;
			gradientImage.rotation = MathUtils.rangeMod(s * Math.PI * 2 / gradientImageSpeed, -Math.PI, Math.PI);

			strokeImage.alpha = a * _logoAlpha;
			strokeImage.x = _nodeInfo.position.x + tOffsetX;
			strokeImage.y = _nodeInfo.position.y + tOffsetY;
			strokeImage.scaleX = strokeImage.scaleY = imageScaleStroke * imageScaleGlobal * 1;
			strokeImage.rotation = MathUtils.rangeMod(s * Math.PI * 2 / strokeImageSpeed, -Math.PI, Math.PI);

			if (focusImage != null) {
				focusImage.alpha = a * _logoAlpha * _keyboardFocused;
				focusImage.x = _nodeInfo.position.x + tOffsetX;
				focusImage.y = _nodeInfo.position.y + tOffsetY;
				focusImage.scaleX = focusImage.scaleY = imageScaleStroke * imageScaleGlobal * FountainFamily.adaInfo.hardwareFocusScaleMenu;
				focusImage.rotation = MathUtils.rangeMod(s * Math.PI * 2 / focusImageSpeed, -Math.PI, Math.PI);
			}

			bubbleImage.alpha = a * _bubbleAlpha * MathUtils.map(_available, 0, 1, 0.2, 1);
			//bubbleImage.visible = bubbleImage.alpha > 0;
			bubbleImage.x = _nodeInfo.position.x + tOffsetX;
			bubbleImage.y = _nodeInfo.position.y + tOffsetY;
			bubbleImage.scaleX = bubbleImage.scaleY = imageScaleBubble * imageScaleGlobal * 0.85; // TODO: this should probably be a different var

			if (bubbleImage.visible) bubbleImage.frame = Math.floor(s * BUBBLES_FRAMES_PER_SECOND) % bubbleImage.totalFrames;

			logoImage.alpha = a * _logoAlpha * _available;
			logoImage.x = _nodeInfo.position.x + tOffsetX;
			logoImage.y = _nodeInfo.position.y + tOffsetY;
			logoImage.scaleX = logoImage.scaleY = imageScaleLogo * imageScaleGlobal * LOGO_SCALE;

			var i: uint = 0;
			for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
				messageTitleImage[i].alpha = a * 0.99 * (1-_available) * _beverage.getDesign().colorMessageTitleInstance.a; // The 0.99 is to force all images to use the same render path, and only one draw call (an alpha of 1 uses a different render path optimized for single rendering)
				messageTitleImage[i].x = _nodeInfo.position.x + tOffsetX;
				messageTitleImage[i].y = _nodeInfo.position.y + tOffsetY + messageTitleImageOffsetY[i] * imageScaleMessage * MESSAGE_SCALE;
				messageTitleImage[i].scaleX = messageTitleImage[i].scaleY = imageScaleGlobal * imageScaleMessage * MESSAGE_SCALE;

				messageSubtitleImage[i].alpha = a * 0.99 * (1-_available) * _beverage.getDesign().colorMessageSubtitleInstance.a;
				messageSubtitleImage[i].x = _nodeInfo.position.x + tOffsetX;
				messageSubtitleImage[i].y = _nodeInfo.position.y + tOffsetY + messageSubtitleImageOffsetY[i] * imageScaleMessage * MESSAGE_SCALE;
				messageSubtitleImage[i].scaleX = messageSubtitleImage[i].scaleY = imageScaleGlobal * imageScaleMessage * MESSAGE_SCALE;

                if(USE_FREE_MESSAGE) {
                    paymentMessage[i].alpha = a * 0.99 * _available * _beverage.getDesign().colorMessageTitleInstance.a; // The 0.99 is to force all images to use the same render path, and only one draw call (an alpha of 1 uses a different render path optimized for single rendering)
                    paymentMessage[i].x = _nodeInfo.position.x + tOffsetX;
                    paymentMessage[i].y = _nodeInfo.position.y + tOffsetY + messageTitleImageOffsetY[i] * imageScaleMessage * MESSAGE_SCALE + logoImage.height * beverage.getDesign().freePaymentCopyRadius;
                    paymentMessage[i].scaleX = paymentMessage[i].scaleY = imageScaleGlobal * imageScaleMessage * MESSAGE_SCALE;
                }
			}

		}

		public function setFocused(__isFocused:Boolean, __immediate:Boolean = false):void {
			ZTween.remove(this, "keyboardFocused");
			if (__immediate) {
				keyboardFocused = __isFocused ? 1 : 0;
			} else {
				ZTween.add(this, {keyboardFocused:__isFocused ? 1 : 0}, {time:FountainFamily.adaInfo.hardwareFocusTimeAnimate});
			}
		}

		public function getVisualBounds():Rectangle {
			return gradientImage.getBounds(Starling.current.stage);
		}

		public function canReceiveFocus():Boolean {
			return _enabled == 1 && _available == 1;
		}

		public function simulateEnterDown():void {
			_wasClickSimulated = true;
			onBlobPressed();
		}

		public function simulateEnterUp():void {
			onBlobReleased();
			onBlobTapped();
		}

		public function simulateEnterCancel():void {
			_wasClickSimulated = false;
			onBlobReleased();
		}

		public function wasClickSimulated():Boolean {
			return _wasClickSimulated;
		}

		public function setImpact(__angle:Number, __impactScale:Number = 1):void {
			// Moves the bubble slightly due to an impact, with some elastic damping
			impactStartTime = currentTime;
			_offsetAngleImpact = __angle;
			_offsetForceImpact = IMPACT_FORCE * __impactScale;
		}

		public function dispose():void {
			touchHandler.dispose();
			touchHandler = null;

			blobLayers = null;

			gradientImage.texture.dispose();
			gradientImage.parent.removeChild(gradientImage, true);
			gradientImage = null;

			strokeImage.texture.dispose();
			strokeImage.parent.removeChild(strokeImage, true);
			strokeImage = null;

			bubbleImage.parent.removeChild(bubbleImage); // , true
			bubbleImage = null;

			logoImage.texture.dispose();
			logoImage.parent.removeChild(logoImage, true);
			logoImage = null;

			var i : uint = 0;
			for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
				messageTitleImage[i].parent.removeChild(messageTitleImage[i], true);
				messageTitleImage[i] = null;

				messageSubtitleImage[i].parent.removeChild(messageSubtitleImage[i], true);
				messageSubtitleImage[i] = null;

                if(USE_FREE_MESSAGE) {
                    paymentMessage[i].parent.removeChild(paymentMessage[i], true);
                    paymentMessage[i] = null;
                }
			}

		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function getGradientImage():Image {
			// Return the gradient image used; this is used so a mask can be created from it
			return gradientImage;
		}

		public function getPosition():Point {
			var p:Point = _nodeInfo.position.clone();
			p.x += _offsetXFloat + _offsetX;
			p.y += _offsetYFloat + _offsetY;

			p.x += _offsetXImpact;
			p.y += _offsetYImpact;
			return p;
		}

		public function get menuItemInfo():MenuItemDefinition {
			return _menuItemInfo;
		}

		public function get nodeInfo():MeshNodeInfo {
			return _nodeInfo;
		}

		public function get onTapped():SimpleSignal {
			return _onTapped;
		}

		public function get pressed():Number {
			return _pressed;
		}
		public function set pressed(__value:Number):void {
			if (_pressed != __value) {
				_pressed = __value;
			}
		}

		public function get enabled():Number {
			return _enabled;
		}
		public function set enabled(__value:Number):void {
			if (_enabled != __value) {
				_enabled = __value;
			}
		}

		public function get available():Number {
			return _available;
		}
		public function set available(__value:Number):void {
			if (_available != __value) {
				_available = __value;
				applyAvailable();
			}
		}

		public function get isUnderEverything():Boolean {
			return _isUnderEverything;
		}
		public function set isUnderEverything(__value:Boolean):void {
			if (_isUnderEverything != __value) {
				_isUnderEverything = __value;
				applyDesiredParent();
			}
		}

		public function get parentBlob():BlobSpritesInfo {
			return _parentBlob;
		}
		public function set parentBlob(__value:BlobSpritesInfo):void {
			if (_parentBlob != __value) {
				_parentBlob = __value;
				applyDesiredParent();
			}
		}

		public function get offsetX():Number {
			return _offsetX;
		}
		public function set offsetX(__value:Number):void {
			if (_offsetX != __value) {
				_offsetX = __value;
			}
		}

		public function get offsetY():Number {
			return _offsetY;
		}
		public function set offsetY(__value:Number):void {
			if (_offsetY != __value) {
				_offsetY = __value;
			}
		}

		public function get offsetXFloat():Number {
			return _offsetXFloat;
		}

		public function get offsetYFloat():Number {
			return _offsetYFloat;
		}

		public function get offsetXImpact():Number {
			return _offsetXImpact;
		}

		public function get offsetYImpact():Number {
			return _offsetYImpact;
		}

		public function get alpha():Number {
			return _alpha;
		}
		public function set alpha(__value:Number):void {
			if (_alpha != __value) {
				_alpha = __value;
			}
		}

		public function get logoAlpha():Number {
			return _logoAlpha;
		}
		public function set logoAlpha(__value:Number):void {
			if (_logoAlpha != __value) {
				_logoAlpha = __value;
			}
		}

		public function get scale():Number {
			return _scale;
		}
		public function set scale(__value:Number):void {
			if (_scale != __value) {
				_scale = __value;
			}
		}

		public function get nodeRadius():Number {
			return nodeInfo.scale * MeshInfo.NODE_RADIUS_STANDARD;
		}

		public function get beverage():Beverage {
			return _beverage;
		}

		public function get isFocused():Boolean {
			return _isFocused;
		}

		public function set isFocused(__value:Boolean):void {
			_isFocused = __value;
		}

		public function get keyboardFocused():Number {
			return _keyboardFocused;
		}

		public function set keyboardFocused(__value:Number):void {
			if (_keyboardFocused != __value) {
				_keyboardFocused = __value;
			}
		}
	}
}
