package com.firstborn.pepsi.display.gpu.brand.particles {
	import com.firstborn.pepsi.application.FountainFamily;
	import com.zehfernando.geom.QuadraticBezierCurve;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.RandomGenerator;

	import flash.geom.Point;
	/**
	 * @author zeh fernando
	 */
	public class ParticleCreatorFactoryCircle implements IParticleCreatorFactory {

		// A circle that can spawn new particles from its top perimeter

		// Properties
		private var center:Point;
		private var radius:Number;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function ParticleCreatorFactoryCircle(__center:Point, __radius:Number) {
			center = __center;
			radius = __radius;
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function createParticlePath():QuadraticBezierCurve {
			// Find min and max starting angle (within the screen)

			var leftY:Number = Math.sqrt(radius * radius - center.x * center.x);
			var leftAngle:Number = Math.atan2(-leftY, -center.x);

			var rw:Number = FountainFamily.platform.width - center.x;
			var rightY:Number = Math.sqrt(radius * radius - rw * rw);
			var rightAngle:Number = Math.atan2(-rightY, rw);

			var f:Number = RandomGenerator.getBoolean() ? Equations.quadInOut(Math.random()) : Equations.quadOut(Math.random());
			var angle:Number = MathUtils.map(f, 0, 1, leftAngle, rightAngle);

			// Finally, find the position
			var p:Point = Point.polar(radius * 1, angle);
			p.x += center.x;
			p.y += center.y;

			var maxHeight:Number = f < 0.5 ? RandomGenerator.getInRange(200, 300) : RandomGenerator.getInRange(500, 600);

			// Decide on top point (towards the center)
			var pTop:Point = new Point(p.x + (FountainFamily.platform.width * 0.5 - p.x) * 0.25 + RandomGenerator.getInRange(-10, 10), p.y - maxHeight);
			//var pTop:Point = new Point(p.x + (blobCenter.x - p.x) * 0.4 + RandomGenerator.getInRange(-10, 10), p.y - RandomGenerator.getInRange(300, 400));

			// Decide on control point
			var pControl:Point = Point.interpolate(p, pTop, 0.6);
			pControl.x += (pTop.x - pControl.x) * 0.8;

			// Create curve
			return new QuadraticBezierCurve(p, pControl, pTop);
		}
	}
}
