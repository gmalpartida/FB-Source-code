package com.firstborn.pepsi.display.gpu.brand.particles {
	import starling.display.Image;
	import starling.display.Sprite;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.data.inventory.BeverageDesign;
	import com.zehfernando.data.types.Color;
	import com.zehfernando.geom.QuadraticBezierCurve;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.RandomGenerator;

	import flash.geom.Point;
	/**
	 * @author zeh fernando
	 */
	public class ParticleCreator extends Sprite {

		// Constant creator of particles

		// Properties
		private var particlesPerSecond:Number;
		private var particlesSizeScale:Number;
		private var particlesSpeedScale:Number;
		private var beverageDesign:BeverageDesign;

		private var lastTimeCreatedParticle:Number;

		private var factory:IParticleCreatorFactory;

		// Instances
		private var particles:Vector.<ParticleInfo>;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function ParticleCreator(__factory:IParticleCreatorFactory, __particlesPerSecond:Number, __particlesSizeScale:Number, __particlesSpeedScale:Number, __beverageDesign:BeverageDesign) {
			factory = __factory;
			particlesPerSecond = __particlesPerSecond;
			particlesSizeScale = __particlesSizeScale;
			particlesSpeedScale = __particlesSpeedScale;
			beverageDesign = __beverageDesign;

			particles = new Vector.<ParticleInfo>();

			lastTimeCreatedParticle = FountainFamily.looper.currentTimeSeconds;
			FountainFamily.looper.onTickedOncePerVisualFrame.add(update);
		}

		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function createParticle():void {
			// Find out where to create it

			// Create curve
			var curve:QuadraticBezierCurve = factory.createParticlePath();
			var particleColor:Color = beverageDesign.getParticleBrandColor();

			var maxLife:Number = curve.length / 600 * 11 * RandomGenerator.getInRange(0.85, 1.15);

			// Create image
			var particle:Image = new Image(FountainFamily.textureLibrary.getBlobParticlesTexture());
			particle.color = particleColor.toRRGGBB();
			addChild(particle);

			// Create sprite info
			var particleInfo:ParticleInfo = new ParticleInfo();
			particleInfo.particle = particle;
			particleInfo.startTime = FountainFamily.looper.currentTimeSeconds;
			particleInfo.stopTime = FountainFamily.looper.currentTimeSeconds + maxLife / particlesSpeedScale;
			particleInfo.startAngle = Math.random() * Math.PI * 2;
			particleInfo.stopAngle = particleInfo.startAngle + RandomGenerator.getInRange(-0.3, 0.3);
			particleInfo.scale = MathUtils.map(Equations.expoIn(Equations.quadIn(Math.random())), 0, 1, 0.2, 0.65) * particlesSizeScale; // Small particles are more frequent than big ones // Was: expoIn
			particleInfo.alpha = particleColor.a;
			particleInfo.path = curve;
			particles.push(particleInfo);
		}

		private function update(__currentTimeSeconds:Number, __tickDeltaTimeSeconds:Number, __currentTick:int):void {

			var particleInterval:Number = (1 / particlesPerSecond);

			// Create particles as needed
			while (lastTimeCreatedParticle <= __currentTimeSeconds - particleInterval) {
				createParticle();
				lastTimeCreatedParticle += particleInterval;
			}

			// Updates all particles, removing old ones
			var linearPhase:Number;
			var inOutPhase:Number;
			var p:Point;
			for (var i:int = 0; i < particles.length; i++) {
				if (particles[i].stopTime > __currentTimeSeconds) {
					// Just update
					linearPhase = MathUtils.map(__currentTimeSeconds, particles[i].startTime, particles[i].stopTime, 0, 1, true);
					inOutPhase = linearPhase < 0.5 ? Equations.quadOut(linearPhase * 2) : (1 - Equations.none((linearPhase-0.5)*2)); // quart in
					p = particles[i].path.getPointOnCurve(Equations.quadIn(linearPhase));
					particles[i].particle.x = p.x;
					particles[i].particle.y = p.y;
					particles[i].particle.alpha = inOutPhase * particles[i].alpha;
					particles[i].particle.scaleX = particles[i].particle.scaleY = particles[i].scale * linearPhase; // Equations.quadOut(linearPhase);
					particles[i].particle.rotation = MathUtils.map(linearPhase, 0, 1, particles[i].startAngle, particles[i].stopAngle);
				} else {
					// Remove particle
					removeParticle(particles[i]);
					i--;
				}
			}
		}

		private function removeParticle(__particleInfo:ParticleInfo):void {
			if (particles.indexOf(__particleInfo) > -1) {
				removeChild(__particleInfo.particle);
				__particleInfo.particle.texture.dispose();
				__particleInfo.particle.dispose();
				particles.splice(particles.indexOf(__particleInfo), 1);
			}
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		override public function dispose():void {
			FountainFamily.looper.onTickedOncePerVisualFrame.remove(update);

			while (particles.length > 0) removeParticle(particles[0]);

			super.dispose();
		}

	}
}
import starling.display.Image;

import com.zehfernando.geom.QuadraticBezierCurve;

class ParticleInfo {
	public var particle:Image;
	public var path:QuadraticBezierCurve;
	public var startTime:Number;
	public var stopTime:Number;
	public var startAngle:Number;
	public var stopAngle:Number;
	public var alpha:Number;
	public var scale:Number;
}