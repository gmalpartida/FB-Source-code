package com.firstborn.pepsi.display.gpu.home.menu {
	import starling.display.Sprite;
	import starling.filters.ColorMatrixFilter;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.data.home.MetaballItemDefinition;
	import com.firstborn.pepsi.data.home.SequenceItemDefinition;
	import com.firstborn.pepsi.display.gpu.common.AnimationPlayer;
	import com.zehfernando.data.types.Color;
	import com.zehfernando.transitions.ZTween;
	import com.zehfernando.utils.AppUtils;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.RandomGenerator;
	import com.zehfernando.utils.console.error;
	import com.zehfernando.utils.console.warn;
	import com.zehfernando.utils.getTimerUInt;

	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * @author zeh fernando
	 */
	public class SequenceLayer extends Sprite {

		// Constants
		private static var TIME_WAIT_BETWEEN_SEQUENCES:Number = 2;							// Time, in seconds, to wait between each sequence animation
		private static var NUM_MAPPED_PHASE_POINTS:Number = 50;								// Precision for phase remapping... the more the better
		private static var METABALLS_RADIUS_SCALE:Number = 0.66;

		// Properties
		private var timeToPlayNextSequence:Number;
		private var lastSequenceAnimationPlayed:String;
		private var lastSequenceAnimationTried:String;
		private var sequenceScaleX:Number;
		private var sequenceScaleY:Number;
		private var timeCurrentSequenceStartedPlaying:uint;									// In ms
		private var timeCurrentSequenceDuration:uint;										// In ms

		private var scale:Number;
		private var _visibility:Number;
		private var _isPlaying:Boolean;
		private var lastMeasuredTime:Number;

		private var mappedPhase:Vector.<Number>;											// Re-mapped phase (sequences of 0-1) to take speed into consideration
		private var mappedHeights:Vector.<Number>;											// Re-mapped heights for proper curves

		private var startTarget:BlobSpritesInfo;
		private var startMetaballsPlayer:AnimationPlayer;
		private var startMetaballDefinition:MetaballItemDefinition;
		private var startRotation:Number;													// In radians, for visual element
		private var startAngle:Number;														// Starting angle on surface
		private var startAnglePoint:Point;													// Based on starting angle
		private var endTarget:BlobSpritesInfo;
		private var endMetaballsPlayer:AnimationPlayer;
		private var endMetaballDefinition:MetaballItemDefinition;
		private var endRotation:Number;														// In radians, for visual element
		private var endAngle:Number;														// Ending angle on surface
		private var endAnglePoint:Point;													// Based on ending angle
		private var animationArea:Rectangle;

		// Instances
		private var layerMetaballs:Sprite;
		private var layerAnimation:Sprite;
		private var layerUnderAnimation:Sprite;												// For blobs
		private var layerAboveAnimation:Sprite;

		private var sequencePlayer:AnimationPlayer;
		private var sequenceFilter:ColorMatrixFilter;
		private var currentSequenceDefinition:SequenceItemDefinition;
		private var topBlobSpritesInfo:BlobSpritesInfo;										// BlobSpritesInfo that is on top of everything

		private var blobsSprites:Vector.<BlobSpritesInfo>;

		private var debug_sequencePathShape:Shape;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function SequenceLayer(__blobsSprites:Vector.<BlobSpritesInfo>, __scale:Number, __animationArea:Rectangle) {
			blobsSprites = __blobsSprites;
			scale = __scale;
			animationArea = __animationArea.clone();
			// Play it safe with the animation area...
			animationArea.inflate(-30, -30);
			animationArea.top += 30;
			lastMeasuredTime = FountainFamily.looper.currentTimeSeconds;

			_visibility = 1;
			timeToPlayNextSequence = -1;
			lastSequenceAnimationPlayed = null;

			layerMetaballs = new Sprite();
			layerMetaballs.touchable = false;
			addChild(layerMetaballs);

			layerUnderAnimation = new Sprite();
			addChild(layerUnderAnimation);

			layerAnimation = new Sprite();
			layerAnimation.touchable = false;
			addChild(layerAnimation);

			layerAboveAnimation = new Sprite();
			addChild(layerAboveAnimation);

			sequenceFilter = new ColorMatrixFilter(new <Number>[
				1, 0, 0, 0, 0,
				0, 1, 0, 0, 0,
				0, 0, 1, 0, 0,
				0, 0, 0, 1, 0
			]);

//			var qq:Quad = new Quad(animationArea.width, animationArea.height, 0xff0000);
//			qq.x = animationArea.x;
//			qq.y = animationArea.y;
//			qq.alpha = 0.1;
//			addChild(qq);

			redrawVisibility();
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function redrawVisibility():void {
			visible = _visibility > 0;
			layerAnimation.alpha = _visibility * _visibility;
			layerMetaballs.alpha = _visibility * _visibility;
		}

		private function playNextSequence():void {
			// Pick and play a sequence

			var i:int, j:int;

			stopQueueingNextSequence();

			currentSequenceDefinition = getNextSequenceDefinition();

			if (currentSequenceDefinition != null) {
				// Maps phase
				// This works to re-map speed. With this system, a position phase of 0.25 (25% of the animation) grabs the phase from mappedPhase from (0.25 * mappedPhase.length)
				// and it'll have the new phase based on the "speeds" list.
				// It's a bit of a brute force approach and not 100% correct (since it interpolates positions) but it works well for this use.

				var ti:uint = getTimerUInt();

				// First, create a list of unweighted phases
				var preMappedPhase:Vector.<Number> = new Vector.<Number>(NUM_MAPPED_PHASE_POINTS, true);
				var currPhase:Number = 0;
				for (i = 0; i < preMappedPhase.length; i++) {
					preMappedPhase[i] = currPhase;
					if (i < preMappedPhase.length - 1) currPhase += getSplineInterpolationPosition(currentSequenceDefinition.speeds, i / (preMappedPhase.length-2)); // Normally, around 1
				}

				// Now, re-maps to start at 0 and end at 1
				mappedPhase = new Vector.<Number>(NUM_MAPPED_PHASE_POINTS, true);
				for (i = 0; i < preMappedPhase.length; i++) {
					mappedPhase[i] = preMappedPhase[i] / currPhase;
				}

				// Decide which metaballs to use
				if (currentSequenceDefinition.playMetaballsStart) startMetaballDefinition = getNextMetaballsDefinition();
				if (currentSequenceDefinition.playMetaballsEnd) endMetaballDefinition = getNextMetaballsDefinition();

				if (startTarget != null) startTarget.addChildrenToSprite();
				if (endTarget != null) endTarget.addChildrenToSprite();

				// Decide on the target blobs
				startTarget = null;
				endTarget = null;
				const maxTries:int = 5;
				var tries:int;

				tries = 0;
				while ((startTarget == null || endTarget == null) && tries < maxTries) {
					if (currentSequenceDefinition.travelBlobs && (!currentSequenceDefinition.sameBlob || (currentSequenceDefinition.sameBlob && RandomGenerator.getBoolean()))) {
						// Travel between two blobs
						startTarget = getRandomBlobSpritesInfo(currentSequenceDefinition.childBlob);
						if (startTarget != null) endTarget = getRandomBlobSpritesInfo(currentSequenceDefinition.childBlob, startTarget);
					} else if (currentSequenceDefinition.sameBlob) {
						// Use same blob
						startTarget = endTarget = getRandomBlobSpritesInfo(currentSequenceDefinition.childBlob);
					}
					tries++;
				}

				if (startTarget == null || endTarget == null) {
					// Could not find suitable targets
					//warn("Could not find suitable targets for sequence animation! Will wait and try again!");
					currentSequenceDefinition = null;
					queueNextSequence(true);
					return;
				}

				// Decides other attributes
				startAngle = NaN;
				endAngle = NaN;
				tries = 0;

				const HIT_RADIUS:Number = 40; // Margin each point needs to be allowed
				const SEGMENTS_PER_PATH:int = 20; // Segments to check for the whole path

				var failedHitTests:Boolean = false;
				var f:Number, s:Number;
				var p1:Point, p2:Point, pp:Point;

				//Console.timeStart("seq");

				// Prepares re-mapped heights
				mappedHeights = new Vector.<Number>(currentSequenceDefinition.heights.length, true);

				failedHitTests = true;

				while (failedHitTests && tries < maxTries) {
					startAngle = (isNaN(currentSequenceDefinition.minStartAngle) || isNaN(currentSequenceDefinition.maxStartAngle)) ? -Math.PI * 0.5 : RandomGenerator.getInRange(currentSequenceDefinition.minStartAngle, currentSequenceDefinition.maxStartAngle) * MathUtils.DEG2RAD;
					endAngle = startTarget == endTarget ? startAngle : ((isNaN(currentSequenceDefinition.minEndAngle) || isNaN(currentSequenceDefinition.maxEndAngle)) ? -Math.PI * 0.5 : RandomGenerator.getInRange(currentSequenceDefinition.minEndAngle, currentSequenceDefinition.maxEndAngle) * MathUtils.DEG2RAD);
					startAnglePoint = Point.polar(startTarget.nodeRadius, startAngle);
					endAnglePoint = Point.polar(endTarget.nodeRadius, endAngle);

					failedHitTests = false;

					// Check if it overlaps anything
					if (currentSequenceDefinition.avoidOverlap || currentSequenceDefinition.avoidBleed) {
						// This is a little bit duplicated from update() - need to make it better to avoid redundant code
						// (it's a bit problematic because the start/end point can change WHILE playing the sequence)

						// Check a number of points in the whole sequence to see if it hits any other blob, or bleeds outside of the area
						failedHitTests = false;

						// Prepares re-mapped heights
						mappedHeights = new Vector.<Number>(currentSequenceDefinition.heights.length, true);

						if (startTarget == endTarget) {
							// Same blob
							p1 = p2 = startTarget.getPosition().add(startAnglePoint);
						} else {
							// Moving from one blob to another
							p1 = startTarget.getPosition().add(startAnglePoint);
							p2 = endTarget.getPosition().add(endAnglePoint);
						}

						createMappedHeights(p1, p2);

						// Check all positions
						for (i = 0; i <= SEGMENTS_PER_PATH; i++) {
							f = i / SEGMENTS_PER_PATH;
							s = getSplineInterpolationPosition(currentSequenceDefinition.scales, f);
							pp = new Point(MathUtils.map(f, 0, 1, 0, p2.x - p1.x), getSplineInterpolationPosition(mappedHeights, f) - p1.y);
							pp = Point.polar(pp.length, Math.atan2(pp.y, pp.x) + MathUtils.map(f, 0, 1, startAngle, endAngle) + Math.PI * 0.5);
							pp = pp.add(p1);

							// Check if it goes out of the valid area
							if (currentSequenceDefinition.avoidBleed) {
								if (!animationArea.containsPoint(pp)) {
									failedHitTests = true;
									break;
								}
							}

							// Check overlap against other objects
							if (currentSequenceDefinition.avoidOverlap) {
								for (j = 0; j < blobsSprites.length; j++) {
									if (blobsSprites[j] != startTarget && Point.distance(blobsSprites[j].nodeInfo.position, pp) < blobsSprites[j].nodeRadius + HIT_RADIUS * s) {
										failedHitTests = true;
										break;
									}
								}
							}

							if (failedHitTests) break;
						}
					}


					//if (isNaN(startAngle) || isNaN(endAngle)) warn("Hitting target, trying again");

					tries++;
				}

				//Console.timeEnd("seq");

				if (failedHitTests) {
					// Could not find suitable angle
					//warn("Could not find suitable angle for sequence animation! Will wait and try again!");
					lastSequenceAnimationTried = currentSequenceDefinition.animationId;
					currentSequenceDefinition = null;
					queueNextSequence(true);
					return;
				}

				//info("Found valid target with angle " + (startAngle * MathUtils.RAD2DEG));

				// Changes depth of targets
				startTarget.addChildrenToSprite(layerUnderAnimation);
				endTarget.addChildrenToSprite(layerUnderAnimation);

				startRotation = currentSequenceDefinition.alignWithTarget ? startAngle + Math.PI * 0.5 : 0;
				endRotation = currentSequenceDefinition.alignWithTarget ? endAngle + Math.PI * 0.5 : 0;

				startRotation += currentSequenceDefinition.rotationOffset * MathUtils.DEG2RAD;
				endRotation += currentSequenceDefinition.rotationOffset * MathUtils.DEG2RAD;

				if (getTimerUInt() - ti > 10) warn("Warning: took " + (getTimerUInt() - ti) + " ms to pick a sequence to play.");

				// Plots sequence
				if (FountainFamily.DEBUG_DRAW_SEQUENCE_CURVE) {
					if (debug_sequencePathShape == null) {
						debug_sequencePathShape = new Shape();
						debug_sequencePathShape.y = 700;
						debug_sequencePathShape.scaleX = FountainFamily.platform.scaleX;
						debug_sequencePathShape.scaleY = FountainFamily.platform.scaleY;
						AppUtils.getStage().addChild(debug_sequencePathShape);
					}

					const graphWidth:Number = 200;

					debug_sequencePathShape.graphics.clear();

					// Plots position graph
					debug_sequencePathShape.graphics.lineStyle(2, 0x3300aa, 0.8);
					const numGraphSegments:int = 50;
					for (i = 0; i <= numGraphSegments; i++) {
						//log(i, i / numGraphSegments * (currentSequence.heights.length - 1));
						if (i == 0) {
							debug_sequencePathShape.graphics.moveTo(i / numGraphSegments * graphWidth, getSplineInterpolationPosition(currentSequenceDefinition.heights, i / numGraphSegments) * -100);
						} else {
							debug_sequencePathShape.graphics.lineTo(i / numGraphSegments * graphWidth, getSplineInterpolationPosition(currentSequenceDefinition.heights, i / numGraphSegments) * -100);
						}
					}

					// Plots size chart
					const numCircles:int = 20;
					for (i = 0; i <= numCircles; i++) {
						debug_sequencePathShape.graphics.lineStyle(1, 0x660000, 0.8);
						debug_sequencePathShape.graphics.beginFill(0xff0000, 0.5);
						debug_sequencePathShape.graphics.drawCircle(i / numCircles * graphWidth, 40, 5 * getSplineInterpolationPosition(currentSequenceDefinition.scales, i / numCircles));
						debug_sequencePathShape.graphics.endFill();
					}

					// Plots phase remapping chart
					for (i = 0; i <= numCircles; i++) {
						debug_sequencePathShape.graphics.lineStyle(1, 0x660000, 0.8);
						debug_sequencePathShape.graphics.beginFill(0xff0000, 0.5);
						debug_sequencePathShape.graphics.drawCircle(getSpeedRemappedPhase(i / numCircles) * graphWidth, 80, 2);
						debug_sequencePathShape.graphics.endFill();
					}

				}

				lastSequenceAnimationPlayed = lastSequenceAnimationTried = currentSequenceDefinition.animationId;
				//log("Playing sequence: " + currentSequence.animationId);
				createCurrentSequencePlayer();
			}
		}

		private function getSpeedRemappedPhase(__phase:Number):Number {
			// Remaps a phase of value 0-1 to the one mapped according to the speed
			if (__phase <= 0) {
				// Beginning
//				log("=> ", 0);
				return 0;
			} if (__phase >= 1) {
				// End
//				log("=> ", 1);
				return 1;
			} else {
				// Middle, does linear interpolation between two known values
				var fullPhase:Number = __phase * (mappedPhase.length - 1);
				var pi:int = Math.floor(fullPhase);
				var pf:Number = fullPhase - pi;
//				log("=> ", MathUtils.map(pf, 0, 1, mappedPhase[pi], mappedPhase[pi+1]), " => ", __phase + " @ ", fullPhase, pi, pf);
				return MathUtils.map(pf, 0, 1, mappedPhase[pi], mappedPhase[pi+1]);
			}
		}

		private function getSplineInterpolationPosition(__values:Vector.<Number>, __phase:Number):Number {
			// Gets a spline-ish interpolated value using catmull-rom splines (passing through all points)
			// __phase is 0-1

			if (__values.length == 1) return __values[0];
			if (__values.length == 2) return __values[0] * __phase + __values[1] * (1 - __phase);

			// http://en.wikipedia.org/wiki/Spline_interpolation

			// Find position (x1, x2 and t)
			var pos:Number = Math.floor(__phase * (__values.length-1));
			var inPhase:Number = (__phase * (__values.length-1)) - pos;

			// Hermite interpolation
			if (pos <= 0) {
				// Beginning value
				//log(" => begin");
				return getInterpolatedPositionHermite(__values[pos] + (__values[pos] - __values[pos+1]), __values[pos], __values[pos+1], __values[pos+2], inPhase);
//				return getInterpolatedPositionCatmullRom(__values[pos] + (__values[pos] - __values[pos+1]), __values[pos], __values[pos+1], __values[pos+2], inPhase);
			} else if (pos >= __values.length - 1) {
				// After end value
				//log(" => after end");
				return __values[pos];
			} else if (pos >= __values.length - 2) {
				// End value
				return getInterpolatedPositionHermite(__values[pos-1], __values[pos], __values[pos+1], __values[pos+1] + (__values[pos+1] - __values[pos]), inPhase);
//				return getInterpolatedPositionCatmullRom(__values[pos-1], __values[pos], __values[pos+1], __values[pos+1] + (__values[pos+1] - __values[pos]), inPhase);
			} else {
				// Middle value
				//log(" => mid");
				return getInterpolatedPositionHermite(__values[pos-1], __values[pos], __values[pos+1], __values[pos+2], inPhase);
//				return getInterpolatedPositionCatmullRom(__values[pos-1], __values[pos], __values[pos+1], __values[pos+2], inPhase);
			}
		}

		private function getInterpolatedPositionCatmullRom(p0:Number, p1:Number, p2:Number, p3:Number, t:Number):Number {
			// Gets all positions on a curve between p1 and p2 using a catmull-rom spline
			// http://www.dxstudio.com/guide_content.aspx?id=70a2b2cf-193e-4019-859c-28210b1da81f
			var t3:Number = t * t * t;
			var t2:Number = t * t;
			var f0:Number = -0.5 * t3 + t2 - 0.5 * t;
			var f1:Number =  1.5 * t3 - 2.5 * t2 + 1.0;
			var f2:Number = -1.5 * t3 + 2.0 * t2 + 0.5 * t;
			var f3:Number =  0.5 * t3 - 0.5 * t2;
			return p0 * f0 + p1 * f1 + p2 * f2 + p3 * f3;
		}

		private function getInterpolatedPositionHermite(p0:Number, p1:Number, p2:Number, p3:Number, t:Number, m1:Number = NaN, m2:Number = NaN):Number {
			// Gets all positions on a curve between p1 and p2 using a Cubic Hermite spline
			// http://en.wikipedia.org/wiki/Cubic_Hermite_spline

			// Tangents
			var t3:Number = t * t * t;
			var t2:Number = t * t;

			if (isNaN(m1) || isNaN(m2)) {
				var tangents:Object = getTangents(p0, p1, p2, p3);
				m1 = tangents["m1"];
				m2 = tangents["m2"];
			}

			return (2 * t3 - 3 * t2 + 1) * p1 + (t3 - 2 * t2 + t) * m1 + (-2 * t3 + 3 * t2) * p2 + (t3 - t2) * m2;
		}

		private function getTangents(p0:Number, p1:Number, p2:Number, p3:Number):Object {
			// Find the tangents of a curve segment using Kochanek-Bartels splines
			// http://en.wikipedia.org/wiki/Kochanek%E2%80%93Bartels_spline

			var t:Number = -1; // Tension; curve smoothness, as it changes the length of the tangent vector (-1 forces straight on point; 1 = produces a line)
			var b:Number = 0; // Bias; (-1 = align to hit the point at the right angle; 1 = align to hit the point in the easiet way after leaving the previous point)
			var c:Number = 0; // Continuity; (-1 = produces a line; 1 = pointy thing)

			// 0, 0, 0 is the same as a catmull-rom

			var m1:Number = (((1-t) * (1+b) * (1+c)) / 2) * (p1 - p0) + (((1-t) * (1-b) * (1-c)) / 2) * (p2 - p1);
			var m2:Number = (((1-t) * (1+b) * (1-c)) / 2) * (p2 - p1) + (((1-t) * (1-b) * (1+c)) / 2) * (p3 - p2);

			return {m1:m1, m2:m2};
		}

		private function getNextMetaballsDefinition():MetaballItemDefinition {
			// Pick a metaball definition to use
			var allMetaballs:Vector.<MetaballItemDefinition> = MetaballItemDefinition.getMetaballItems().concat();

			// Finds total weight, removing disabled sequences
			var i:int;
			var totalWeight:Number = 0;
			for (i = 0; i < allMetaballs.length; i++) {
				if (allMetaballs[i].frequency > 0) {
					// Normal item
					totalWeight += allMetaballs[i].frequency;
				} else {
					// Disabled item, removes this item from the list
					allMetaballs.splice(i, 1);
					i--;
				}
			}

			// Pick an item
			var f:Number = Math.random() * totalWeight;
			totalWeight = 0;
			for (i = 0; i < allMetaballs.length; i++) {
				totalWeight += allMetaballs[i].frequency;
				if (totalWeight >= f) {
					// This one
					return allMetaballs[i];
				}
			}

			error("Could not find a metaball to use!");
			return null;
		}

		private function getNextSequenceDefinition():SequenceItemDefinition {
			// Decides which sequence to play next
			var allSequences:Vector.<SequenceItemDefinition> = SequenceItemDefinition.getSequenceItems().concat();

			// Finds total weight, removing disabled sequences
			var i:int;
			var totalWeight:Number = 0;
			for (i = 0; i < allSequences.length; i++) {
				if (allSequences[i].frequency > 0) {
					// Normal item
					totalWeight += allSequences[i].frequency;
				} else {
					// Disabled item, removes this item from the list
					allSequences.splice(i, 1);
					i--;
				}
			}

			// Rremove the last animation tried if possible
			for (i = 0; i < allSequences.length; i++) {
				if (lastSequenceAnimationTried != null && allSequences[i].animationId == lastSequenceAnimationTried && allSequences.length > 1) {
					totalWeight -= allSequences[i].frequency;
					allSequences.splice(i, 1);
					i--;
				}
			}

			// also remove previous animation if possible
			for (i = 0; i < allSequences.length; i++) {
				if (lastSequenceAnimationPlayed != null && allSequences[i].animationId == lastSequenceAnimationPlayed && allSequences.length > 1) {
					totalWeight -= allSequences[i].frequency;
					allSequences.splice(i, 1);
					i--;
				}
			}

			// Pick an item
			var f:Number = Math.random() * totalWeight;
			totalWeight = 0;
			for (i = 0; i < allSequences.length; i++) {
				totalWeight += allSequences[i].frequency;
				if (totalWeight >= f) {
					// This one
					return allSequences[i];
				}
			}

			error("Could not find a sequence to play!");
			return null;
		}

		private function createCurrentSequencePlayer():void {
			destroyCurrentSequencePlayer();

			// Creates actual animation player
			//log("Create: sequence player");
			sequencePlayer = new AnimationPlayer();
			sequencePlayer.alignX = currentSequenceDefinition.centerX;
			sequencePlayer.alignY = currentSequenceDefinition.centerY;
			sequencePlayer.visible = false;
			sequenceScaleX = scale;
			sequenceScaleY = scale;
			if (!currentSequenceDefinition.isDirectionRight) {
				sequenceScaleX *= -1;
			}
			if ((endTarget != null && endTarget.getPosition().x < startTarget.getPosition().x) || (endTarget == null && Math.random() > 0.5)) {
				sequenceScaleX *= -1;
			}
			if (currentSequenceDefinition.alignWithTarget && currentSequenceDefinition.flipOnAligning && (startAngle > Math.PI * 0.5 && startAngle < Math.PI * 1.5)) {
				sequenceScaleX *= -1;
				startRotation += Math.PI;
				endRotation += Math.PI;
			}

			sequencePlayer.filter = sequenceFilter;

			if (startTarget == endTarget) {
				// Just one target, so update the color to match
				if (currentSequenceDefinition.tinted) {
					setSequenceFilter(startTarget.beverage.getDesign().colorAnimationDarkInstance, startTarget.beverage.getDesign().colorAnimationLightInstance);
				} else {
					sequencePlayer.filter = null;
				}
			}

			// Load animation
			sequencePlayer.playAnimation(currentSequenceDefinition.animationId, false);
			sequencePlayer.pauseAnimation();
			layerAnimation.addChild(sequencePlayer);

			// Prepares for starting
			timeCurrentSequenceStartedPlaying = 0;
		}

		private function destroyCurrentSequencePlayer():void {
			if (sequencePlayer != null) {
				//log("Dispose: sequence player");
				unsetTopBlobSpritesInfo();

				layerAnimation.removeChild(sequencePlayer);
				sequencePlayer.filter = null;
				sequencePlayer.dispose();
				sequencePlayer = null;
			}
		}

		private function queueNextSequence(__fast:Boolean = false):void {
			timeToPlayNextSequence = lastMeasuredTime + TIME_WAIT_BETWEEN_SEQUENCES * (__fast ? 0.2 : 1);
		}

		private function stopQueueingNextSequence():void {
			timeToPlayNextSequence = -1;
		}

		private function setSequenceFilter(__colorDark:Color, __colorLight:Color):void {
			// Sets the tinting of the current sequence
			sequenceFilter.matrix = getColorMatrix(__colorDark, __colorLight);
		}

		private function getColorFilter(__colorDark:Color, __colorLight:Color):ColorMatrixFilter {
			// Returns a color tinting filter for the metaballs
			return new ColorMatrixFilter(getColorMatrix(__colorDark, __colorLight));
		}

		private function getColorMatrix(__colorDark:Color, __colorLight:Color):Vector.<Number> {
			// Returns a number vector for color tinting filter, where black is colorDark and white is colorLight
			return new <Number>[
				__colorLight.r - __colorDark.r, 0, 0, 0, __colorDark.r*255,
				0, __colorLight.g - __colorDark.g, 0, 0, __colorDark.g*255,
				0, 0, __colorLight.b - __colorDark.b, 0, __colorDark.b*255,
				0, 0, 0, 1, 0
			];
		}

		private function getRandomBlobSpritesInfo(__allowChildBlobs:Boolean, __startTarget:BlobSpritesInfo = null):BlobSpritesInfo {
			// Picks a blobsSpriteInfo to be the start or end target of the animation sequence

			// Creates a list of allowed blob sprites
			var allowedBlobsSprites:Vector.<BlobSpritesInfo> = new Vector.<BlobSpritesInfo>();
			var i:int;
			for (i = 0; i < blobsSprites.length; i++) {
				// Check if it's already used
				if ((__startTarget == null || blobsSprites[i] != __startTarget) && (blobsSprites[i].available == 1) && (__allowChildBlobs || blobsSprites[i].parentBlob == null)) {
					// Not the start target item, or there's no start target yet; continue

					// Check beverage restriction
					if (currentSequenceDefinition.restrictedBeverageIds.length == 0 || currentSequenceDefinition.restrictedBeverageIds.indexOf(blobsSprites[i].beverage.id) > -1) {
						// No restriction to beverage ids, or the blob sprites info has a beverage id that is allowed; continue

						// Check angle
						if (__startTarget == null) {
							// First target, so no angle to check
							allowedBlobsSprites.push(blobsSprites[i]);
						} else {
							// Second target
							var angle:Number = Math.atan2(blobsSprites[i].nodeInfo.position.y - __startTarget.nodeInfo.position.y, blobsSprites[i].nodeInfo.position.x - __startTarget.nodeInfo.position.x);
							if (angle > Math.PI * 0.5) {
								// Other side, so flip it
								angle = Math.PI - angle;
							}

//							log("angles: " + currentSequence.minTravelAngle + " -> " + currentSequence.maxTravelAngle + " = " + angle * MathUtils.RAD2DEG);

							if ((isNaN(currentSequenceDefinition.minTravelAngle) || angle >= currentSequenceDefinition.minTravelAngle * MathUtils.DEG2RAD) && (isNaN(currentSequenceDefinition.maxTravelAngle) || angle <= currentSequenceDefinition.maxTravelAngle * MathUtils.DEG2RAD)) {
								// Inside the allowed angle cone, so use it
								allowedBlobsSprites.push(blobsSprites[i]);
							}
						}
					}
				}
			}

			//log("==> " + allowedBlobsSprites.length + " blob sprites can be used for animation");

			if (allowedBlobsSprites.length == 0) {
				// No suitable blob could be found, return null (invalidating the selection)
				return null;
			}

			// Finally, pick one of the items
			return allowedBlobsSprites[RandomGenerator.getInIntegerRange(0, allowedBlobsSprites.length-1)];
		}

		private function setTopBlobSpritesInfo(__blobSpritesInfo:BlobSpritesInfo):void {
			// Reset
			if (__blobSpritesInfo != topBlobSpritesInfo) {
				unsetTopBlobSpritesInfo();

				topBlobSpritesInfo = __blobSpritesInfo;
				topBlobSpritesInfo.addChildrenToSprite(layerAboveAnimation);
			}
		}

		private function unsetTopBlobSpritesInfo():void {
			if (topBlobSpritesInfo != null) {
				topBlobSpritesInfo.addChildrenToSprite(layerUnderAnimation);
				topBlobSpritesInfo = null;
			}
		}

		private function removeMetaballPlayer(__metaball:AnimationPlayer):void {
			if (__metaball != null) {
				if (__metaball == startMetaballsPlayer) startMetaballsPlayer = null;
				if (__metaball == endMetaballsPlayer) {
					endMetaballsPlayer = null;
					if (endTarget != null) endTarget.addChildrenToSprite();
				}
				ZTween.remove(__metaball);
				layerMetaballs.removeChild(__metaball);
				__metaball.filter.dispose();
				__metaball.filter = null;
				__metaball.dispose();
				__metaball = null;
			}
		}

		private function createMappedHeights(__p1:Point, __p2:Point):void {
			// Re-maps heights: center uses max Y, sides use target's y
			var i:int;
			//log("p1 = "+ __p1 + ", rect = " + animationArea);
			var highestY:Number = Math.min(__p1.y, __p2.y);
			var halfPoint:int = (mappedHeights.length - 1) / 2;
			for (i = 0; i < mappedHeights.length; i++) {
				mappedHeights[i] = MathUtils.map(Math.abs(halfPoint - i) / halfPoint, 0, 1, highestY, i < halfPoint ? __p1.y : __p2.y) - currentSequenceDefinition.heights[i] * currentSequenceDefinition.animation.height; // * s
				// Hack - the above doesn't work correctly if the heights has a length of 1
				if (isNaN(mappedHeights[i])) mappedHeights[i] = highestY;
			}
			//log("Mapped heights => " + mappedHeights);
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onFinishedPlayingMetaballs(__player:AnimationPlayer):void {
			// Finished playing a metaball sequence; simply get rid of it

//			if (__player == startMetaballsPlayer) log("Dispose: start metaball");
//			if (__player == endMetaballsPlayer) log("Dispose: end metaball");

			//if (__player == startMetaballsPlayer) removeMetaballPlayer(startMetaballsPlayer);
			//if (__player == endMetaballsPlayer) removeMetaballPlayer(endMetaballsPlayer);

			__player.onFinishedPlaying.remove(onFinishedPlayingMetaballs);

			ZTween.add(__player, {alpha:0}, {time:0.2, onComplete:function():void {
				removeMetaballPlayer(__player);
				__player = null;
			}});
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function update(__currentTimeSeconds:Number, __tickDeltaTimeSeconds:Number, __currentTick:int):void {
			lastMeasuredTime = __currentTimeSeconds;
			if (timeToPlayNextSequence > 0 && timeToPlayNextSequence < __currentTimeSeconds) {
				// Create a new sequence
				playNextSequence();
			}

			if (sequencePlayer != null) {
				// For the sequence to start playing, the sequence, the metaballs intro, and the metaballs outro need to be created and loaded
				// That's done once per frame, to reduce the performance impact; but it also means it has this deep check

				if (timeCurrentSequenceStartedPlaying == 0) {
					// Still waiting for the animation to be loaded
					if (sequencePlayer.getCurrentAnimatedImage() != null) {
						// Sequence has loaded

						if (startMetaballsPlayer == null && currentSequenceDefinition.playMetaballsStart) {
							// No start metaballs yet, and they're needed
//							log("Create: start metaball");
							startMetaballsPlayer = new AnimationPlayer();
							//startMetaballsPlayer.alpha = startTarget.getEffectiveAlpha();
							startMetaballsPlayer.alignX = startMetaballDefinition.centerX;
							startMetaballsPlayer.alignY = startMetaballDefinition.centerY;
							startMetaballsPlayer.rotation = -startMetaballDefinition.angle * MathUtils.DEG2RAD + Math.atan2(startAnglePoint.y, startAnglePoint.x);
							startMetaballsPlayer.visible = false;
							startMetaballsPlayer.scaleX = startMetaballsPlayer.scaleY = startTarget.nodeInfo.scale * startMetaballDefinition.scale;
							startMetaballsPlayer.playAnimation(startMetaballDefinition.animationId, false);
							startMetaballsPlayer.pauseAnimation();
							startMetaballsPlayer.filter = getColorFilter(startTarget.beverage.getDesign().colorAnimationDarkInstance, startTarget.beverage.getDesign().colorAnimationLightInstance);
							startMetaballsPlayer.onFinishedPlaying.add(onFinishedPlayingMetaballs);
							layerMetaballs.addChild(startMetaballsPlayer);
						} else if ((startMetaballsPlayer != null && startMetaballsPlayer.getCurrentAnimatedImage() != null) || !currentSequenceDefinition.playMetaballsStart) {
							// Starting metaballs sequence has loaded, or no starting metaballs are needed

							if (endMetaballsPlayer == null && currentSequenceDefinition.playMetaballsEnd) {
								// No end metaballs yet, and they're needed
//								log("Create: end metaball");
								endMetaballsPlayer = new AnimationPlayer();
								//endMetaballsPlayer.alpha = endTarget.getEffectiveAlpha();
								endMetaballsPlayer.alignX = endMetaballDefinition.centerX;
								endMetaballsPlayer.alignY = endMetaballDefinition.centerY;
								endMetaballsPlayer.rotation = -endMetaballDefinition.angle * MathUtils.DEG2RAD + Math.atan2(endAnglePoint.y, endAnglePoint.x);
								endMetaballsPlayer.visible = false;
								endMetaballsPlayer.scaleX = endMetaballsPlayer.scaleY = endTarget.nodeInfo.scale * endMetaballDefinition.scale;
								endMetaballsPlayer.playAnimation(endMetaballDefinition.animationId, false);
								endMetaballsPlayer.pauseAnimation();
								endMetaballsPlayer.filter = getColorFilter(endTarget.beverage.getDesign().colorAnimationDarkInstance, endTarget.beverage.getDesign().colorAnimationLightInstance);
								endMetaballsPlayer.onFinishedPlaying.add(onFinishedPlayingMetaballs);
								layerMetaballs.addChild(endMetaballsPlayer);
							} else if ((endMetaballsPlayer != null && endMetaballsPlayer.getCurrentAnimatedImage() != null) || !currentSequenceDefinition.playMetaballsEnd) {
								// Ending metaballs sequence has loaded, or no ending metaballs are needed

								// All loaded, can start playing

								// Set time and start
								timeCurrentSequenceStartedPlaying = lastMeasuredTime * 1000;
								timeCurrentSequenceDuration = Math.round((sequencePlayer.getCurrentAnimationDefinition().frames / sequencePlayer.getCurrentAnimationDefinition().fps) * 1000);
								sequencePlayer.visible = true;

								if (currentSequenceDefinition.playMetaballsStart) {
									// Play start metaballs
									startMetaballsPlayer.visible = true;
									startMetaballsPlayer.getCurrentAnimatedImage().stop();
									startMetaballsPlayer.getCurrentAnimatedImage().play();

									// Play impact
									if (currentSequenceDefinition.startImpact > 0) startTarget.setImpact(startAngle + Math.PI, currentSequenceDefinition.startImpact);
								}
							}
						}
					}
				}

				if (timeCurrentSequenceStartedPlaying > 0) {
					// Playing, update the state of the current sequence

					var linearPhase:Number = MathUtils.map(lastMeasuredTime * 1000 - timeCurrentSequenceStartedPlaying, 0, timeCurrentSequenceDuration, 0, 1, true);
					var mappedPhase:Number = getSpeedRemappedPhase(linearPhase);

					if (lastMeasuredTime * 1000 > timeCurrentSequenceStartedPlaying + timeCurrentSequenceDuration) {
						// Finished playing the animation, remove it

						if (startTarget != null) startTarget.addChildrenToSprite();

						if (currentSequenceDefinition.playMetaballsEnd && endMetaballsPlayer != null) {
							// Play end metaballs
							endMetaballsPlayer.visible = true;
							endMetaballsPlayer.getCurrentAnimatedImage().stop();
							endMetaballsPlayer.getCurrentAnimatedImage().play();
						} else {
							if (endTarget != null) endTarget.addChildrenToSprite();
						}

						// Play impact
						if (currentSequenceDefinition.endImpact > 0) endTarget.setImpact(endAngle + Math.PI, currentSequenceDefinition.endImpact);

						currentSequenceDefinition = null;
						destroyCurrentSequencePlayer();
						queueNextSequence();
					} else {
						// Still playing the animation, update
						if (currentSequenceDefinition == null) {
							error("ERROR: Current sequence definition doesn't exist anymore!");
							return;
						}

						//var p:Point;
						var p1:Point, p2:Point;

						if (startTarget == endTarget) {
							// Same blob

							// Find target position
							p1 = p2 = startTarget.getPosition().add(startAnglePoint);
						} else {
							// Moving from one blob to another

							// Find target position
							p1 = startTarget.getPosition().add(startAnglePoint);
							p2 = endTarget.getPosition().add(endAnglePoint);

							// Set color
							if (currentSequenceDefinition.tinted) setSequenceFilter(Color.interpolateHSV(startTarget.beverage.getDesign().colorAnimationDarkInstance, endTarget.beverage.getDesign().colorAnimationDarkInstance, 1-mappedPhase), Color.interpolateHSV(startTarget.beverage.getDesign().colorAnimationLightInstance, endTarget.beverage.getDesign().colorAnimationLightInstance, 1-mappedPhase));
						}

						// Set rotation
						sequencePlayer.rotation = MathUtils.map(mappedPhase, 0, 1, startRotation, endRotation);

						// Set blobs that are in front
						if (mappedPhase < 0.5) {
							if (topBlobSpritesInfo != startTarget && !currentSequenceDefinition.aboveTarget) setTopBlobSpritesInfo(startTarget);
						} else {
							if (topBlobSpritesInfo != endTarget && !currentSequenceDefinition.aboveTarget) setTopBlobSpritesInfo(endTarget);
						}

						// Set scale
						var s:Number = getSplineInterpolationPosition(currentSequenceDefinition.scales, mappedPhase);
						sequencePlayer.scaleX = sequenceScaleX * s;
						sequencePlayer.scaleY = sequenceScaleY * s;

						createMappedHeights(p1, p2); // , s

//						if (currentSequenceDefinition.animationId == "menu_character_headspin") {
//							log("====== " + currentSequenceDefinition.animationId);
//							log("half => " + halfPoint, highestY);
//							log("original => " + currentSequenceDefinition.heights);
//							log("mapped => " + mappedHeights);
//						}

						// Set position
						var pp:Point = new Point(MathUtils.map(mappedPhase, 0, 1, 0, p2.x - p1.x), getSplineInterpolationPosition(mappedHeights, mappedPhase) - p1.y);
						var pp2:Point = pp;
						//if (startRotation) {
							pp2 = Point.polar(pp.length, Math.atan2(pp.y, pp.x) + MathUtils.map(mappedPhase, 0, 1, startAngle, endAngle) + Math.PI * 0.5);
						//}
						sequencePlayer.x = p1.x + pp2.x;
						sequencePlayer.y = p1.y + pp2.y;

						//sequencePlayer.x = MathUtils.map(mappedPhase, 0, 1, p1.x, p2.x);
						//sequencePlayer.y = getSplineInterpolationPosition(mappedHeights, mappedPhase);

						// Set animation frame
						if (sequencePlayer.getCurrentAnimatedImage() != null) sequencePlayer.getCurrentAnimatedImage().frame = Math.round(MathUtils.map(linearPhase, 0, 1, 0, sequencePlayer.getCurrentAnimatedImage().totalFrames-1, true));
					}
				}
			}

			// Update metaballs
			// This is done outside of the main loop because metaballs can exist after the sequence has already been destroyed
			if (startMetaballsPlayer != null && startTarget != null && startMetaballsPlayer.visible) {
				startMetaballsPlayer.x = startTarget.getPosition().x + startAnglePoint.x * METABALLS_RADIUS_SCALE;
				startMetaballsPlayer.y = startTarget.getPosition().y + startAnglePoint.y * METABALLS_RADIUS_SCALE;
			}

			if (endMetaballsPlayer != null && endTarget != null && endMetaballsPlayer.visible) {
				endMetaballsPlayer.x = endTarget.getPosition().x + endAnglePoint.x * METABALLS_RADIUS_SCALE;
				endMetaballsPlayer.y = endTarget.getPosition().y + endAnglePoint.y * METABALLS_RADIUS_SCALE;
			}
		}

		public function start():void {
			if (!_isPlaying) {
				queueNextSequence();
				_isPlaying = true;
			}
		}

		public function stop():void {
			// Destroy current sequence and stop everything
			if (_isPlaying) {
				_isPlaying = false;
				stopQueueingNextSequence();

				currentSequenceDefinition = null;

				destroyCurrentSequencePlayer();

				startTarget = null;
				endTarget = null;

				if (startMetaballsPlayer != null) removeMetaballPlayer(startMetaballsPlayer);
				if (endMetaballsPlayer != null) removeMetaballPlayer(endMetaballsPlayer);
			}
		}

		override public function dispose():void {
			sequenceFilter.dispose();
			sequenceFilter = null;

			super.dispose();
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get visibility():Number {
			return _visibility;
		}
		public function set visibility(__value:Number):void {
			if (_visibility != __value) {
				_visibility = __value;
				redrawVisibility();
			}
		}

		public function get isPlaying():Boolean {
			return _isPlaying;
		}
	}
}
