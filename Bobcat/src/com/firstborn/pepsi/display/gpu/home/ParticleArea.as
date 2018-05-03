package com.firstborn.pepsi.display.gpu.home {
	import starling.display.Image;
	import starling.display.Sprite;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.data.TextureProfile;
	import com.firstborn.pepsi.data.home.MenuItemDefinition;
	import com.firstborn.pepsi.data.inventory.Beverage;
	import com.firstborn.pepsi.display.gpu.home.menu.MainMenu;
	import com.zehfernando.data.types.Color;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.RandomGenerator;
	import com.zehfernando.utils.console.log;

	import flash.geom.Point;
	/**
	 * @author zeh fernando
	 */
	public class ParticleArea extends Sprite {

		// An area full of particles

		// Constants
		private static const MIN_DISTANCE_PARTICLES:int = 140; // Margin between a particle and other particles
		private static const MIN_PARTICLE_RADIUS:Number = 2; // Minimum radius, in pixels
		private static const MAX_PARTICLE_RADIUS:Number = 30; // Maximum radius, in pixels

		// Properties
		private var _width:Number;
		private var _height:Number;
		private var _particlesDensity:Number;
		private var _particleAlphaScale:Number;
		private var isPaused:Boolean;
		private var lastPausedTime:Number;
		private var totalPausedTime:Number;

		// Instances
		private var particles:Vector.<ParticleInfo>;
		private var textureInfo:TextureProfile;
		private var mainMenu:MainMenu;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function ParticleArea(__width:Number, __height:Number, __particlesDensity:Number, __particleAlphaScale:Number, __mainMenu:MainMenu) {
			_width = __width;
			_height = __height;
			_particlesDensity = __particlesDensity;
			_particleAlphaScale = __particleAlphaScale;
			mainMenu = __mainMenu;
			isPaused = false;
			lastPausedTime = 0;
			totalPausedTime = 0;

			particles = new Vector.<ParticleInfo>();
			textureInfo = FountainFamily.platform.getTextureProfile("blob-particles");

			createParticles();

			FountainFamily.looper.onTickedOncePerVisualFrame.add(update);
			FountainFamily.looper.updateOnce(update);
		}

		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function createParticles():void {
			//var ti:int = getTimer();

			var particlesToCreate:int = Math.round((_width * _height) / (1000 * 1000) * _particlesDensity);

			if (particlesToCreate > 0) {
				// Creates particles for all sprites
				var menuItems:Vector.<MenuItemDefinition> = MenuItemDefinition.getMenuItems();
				var menuItem:MenuItemDefinition;
				var beverage:Beverage;
				var i:int, j:int;
				var tries:int;
				var particleColor:Color;
				var particleRadius:Number;
				var particlePosition:Point;
				var particleAlpha:Number;
				var image:Image;
				var positionValid:Boolean;
				var particle:ParticleInfo;

				for (i = 0; i < particlesToCreate; i++) {
					menuItem = menuItems[RandomGenerator.getInIntegerRange(0, menuItems.length-1)];
					beverage = FountainFamily.inventory.getBeverageById(menuItem.beverageId);

					// Color
					particleColor = beverage.getDesign().getParticleHomeColor();

					// Create image
					image = new Image(FountainFamily.textureLibrary.getBlobParticlesTexture());
					image.pivotX = image.width * 0.5;
					image.pivotY = image.height * 0.5;
					image.smoothing = textureInfo.smoothing;
					image.color = particleColor.toRRGGBB();
					addChild(image);

					// Decide radius
					particleRadius = MathUtils.map(Equations.custom(1, Math.random()), 0, 1, MIN_PARTICLE_RADIUS, MAX_PARTICLE_RADIUS);

					// Decide alpha
					particleAlpha = particleColor.a;

					// Decide position (aligned to the bottom)
					tries = 20;
					positionValid = false;
					while (tries > 0 && !positionValid) {
						positionValid = true;
						particlePosition = new Point(MathUtils.map(Math.random(), 0, 1, particleRadius, _width - particleRadius), MathUtils.map(Equations.custom(-2, Math.random()), 0, 1, particleRadius, _height - particleRadius));

						for (j = 0; j < particles.length; j++) {
							if (Point.distance(particlePosition, particles[j].position) < MIN_DISTANCE_PARTICLES) {
								positionValid = false;
								break;
							}
						}

						tries--;
					}

					// The closer to the top, the smaller the radius, so clamp to the min-max range depending on y
					particleRadius = Math.min(particleRadius, MathUtils.map(particlePosition.y, 0, _height, MIN_PARTICLE_RADIUS, MAX_PARTICLE_RADIUS));

					// Create actual particle
					particle = new ParticleInfo(image, particleAlpha * _particleAlphaScale, particleRadius, particlePosition);
					particles.push(particle);
				}
			}

		}

		private function destroyParticles():void {
			while (particles.length > 0) {
				removeChild(particles[0].image);
				particles[0].image.texture.dispose();
				particles[0].image.dispose();
				particles.splice(0, 1);
			}
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function update(__currentTimeSeconds:Number, __tickDeltaTimeSeconds:Number, __currentTick:int):void {
			if (!isPaused && mainMenu.brandTransitionPhase < 1) {
				var vis:Number = MathUtils.map(mainMenu.brandTransitionPhase, 0, 0.5, 1, 0, true);
				for each (var particle:ParticleInfo in particles) {
					particle.visibility = vis;
					particle.update(__currentTimeSeconds, __tickDeltaTimeSeconds, __currentTick);
				}
			}
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

		public function recreate():void {
			destroyParticles();
			createParticles();
		}

		override public function dispose():void {
			FountainFamily.looper.onTickedOncePerVisualFrame.remove(update);
			destroyParticles();
			super.dispose();
		}

	}

}
import starling.display.Image;

import com.zehfernando.utils.MathUtils;
import com.zehfernando.utils.RandomGenerator;

import flash.geom.Point;
class ParticleInfo {

	// Properties
	private var alpha:Number;
	public var radius:Number;
	public var position:Point;

	private var rotationSpeed:Number;
	private var scaleCycleTime:Number;

	public var visibility:Number;

	// Instances
	public var image:Image;

	// Temp vars
	private var scale:Number;


	// ================================================================================================================
	// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

	public function ParticleInfo(__image:Image, __alpha:Number, __radius:Number, __position:Point) {
		image = __image;
		alpha = __alpha;
		radius = __radius;
		position = __position;

		image.x = position.x;
		image.y = position.y;
		image.scaleX = image.scaleY = __radius / __image.texture.nativeWidth;

		rotationSpeed = (RandomGenerator.getBoolean() ? 1 : -1) * RandomGenerator.getInRange(5, 18);
		scaleCycleTime = RandomGenerator.getInRange(4, 10);
		visibility = 1;

		// Radius and image cannot change later!
		scale = radius / (image.texture.frame == null ? image.texture.width : image.texture.frame.width) * 2;
	}

	// ================================================================================================================
	// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

	public function update(__currentTimeSeconds:Number, __tickDeltaTimeSeconds:Number, __currentTick:int):void {
		image.rotation = __currentTimeSeconds * Math.PI * 2 / rotationSpeed;
		image.alpha = visibility * alpha;
	}
}
