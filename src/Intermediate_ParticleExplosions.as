/*

Particle explosions in Away3D using the Adobe AIR and Adobe Flash Player logos

Demonstrates:

How to split images into particles.
How to share particle geometries and animation sets between meshes and animators.
How to manually update the playhead of a particle animator using the update() function.

Code by Rob Bateman & Liao Cheng
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
liaocheng210@126.com

This code is distributed under the MIT License

Copyright (c) The Away Foundation http://www.theawayfoundation.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

package
{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	import away3d.animators.*;
	import away3d.animators.data.*;
	import away3d.animators.nodes.*;
	import away3d.cameras.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.core.base.*;
	import away3d.debug.*;
	import away3d.entities.*;
	import away3d.lights.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.*;
	import away3d.primitives.*;
	import away3d.tools.helpers.*;
	import away3d.utils.*;
	
	[SWF(backgroundColor="#000000", frameRate="60", quality="LOW")]
	
	public class Intermediate_ParticleExplosions extends Sprite
	{
		private const PARTICLE_SIZE:uint = 3;
		private const NUM_ANIMATORS:uint = 4;
		
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf:Class;
		
		//ADobe AIR image
		[Embed(source="/../embeds/air.png")]
		private var AIRImage:Class;
		
		//Adobe Flash player image
		[Embed(source="/../embeds/player.png")]
		private var PlayerImage:Class;
		
		//engine variables
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var cameraController:HoverController;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//light variables
		private var greenLight:PointLight;
		private var blueLight:PointLight;
		//private var whitelight:DirectionalLight;
		//private var direction:Vector3D = new Vector3D();
		private var lightPicker:StaticLightPicker;
		
		//data variables
		private var redPoints:Vector.<Vector3D> = new Vector.<Vector3D>();
		private var whitePoints:Vector.<Vector3D> = new Vector.<Vector3D>();
		private var redSeparation:int;
		private var whiteSeparation:int;
		
		//material objects
		private var whiteMaterial:ColorMaterial;
		private var redMaterial:ColorMaterial;
		
		//particle objects
		private var redGeometry:ParticleGeometry;
		private var whiteGeometry:ParticleGeometry;
		private var redAnimationSet:ParticleAnimationSet;
		private var whiteAnimationSet:ParticleAnimationSet;
		
		//scene objects
		private var redParticleMesh:Mesh;
		private var whiteParticleMesh:Mesh;
		private var redAnimators:Vector.<ParticleAnimator>;
		private var whiteAnimators:Vector.<ParticleAnimator>;
		
		//navigation variables
		private var angle:Number = 0;
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		
		/**
		 * Constructor
		 */
		public function Intermediate_ParticleExplosions()
		{
			init();
		}
		
		/**
		 * Global initialise function
		 */
		private function init():void
		{
			initEngine();
			initLights();
			initMaterials();
			initParticles();
			initObjects();
			initListeners();
		}
		
		/**
		 * Initialise the engine
		 */
		private function initEngine():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			scene = new Scene3D();
			
			camera = new Camera3D();
			
			view = new View3D();
			view.scene = scene;
			view.camera = camera;
			
			//setup controller to be used on the camera
			cameraController = new HoverController(camera, null, 225, 10, 1000);
			
			view.addSourceURL("srcview/index.html");
			addChild(view);
			
			//add signature
			Signature = Sprite(new SignatureSwf());
			SignatureBitmap = new Bitmap(new BitmapData(Signature.width, Signature.height, true, 0));
			stage.quality = StageQuality.HIGH;
			SignatureBitmap.bitmapData.draw(Signature);
			stage.quality = StageQuality.LOW;
			addChild(SignatureBitmap);
			
			addChild(new AwayStats(view));
		}
		
		/**
		 * Initialise the lights
		 */
		private function initLights():void
		{
			//create a green point light
			greenLight = new PointLight();
			greenLight.color = 0x00FF00;
			greenLight.ambient = 1;
			greenLight.fallOff = 600;
			greenLight.radius = 100;
			greenLight.specular = 2;
			scene.addChild(greenLight);
			
			//create a red pointlight
			blueLight = new PointLight();
			blueLight.color = 0x0000FF;
			blueLight.fallOff = 600;
			blueLight.radius = 100;
			blueLight.specular = 2;
			scene.addChild(blueLight);
			
			//create a lightpicker for the green and red light
			lightPicker = new StaticLightPicker([greenLight, blueLight]);
		}
		
		/**
		 * Initialise the materials
		 */
		private function initMaterials():void
		{
			
			//setup the red particle material
			redMaterial = new ColorMaterial(0xBE0E0E);
			redMaterial.alphaPremultiplied = true;
			redMaterial.bothSides = true;
			redMaterial.lightPicker = lightPicker;
			
			//setup the white particle material
			whiteMaterial = new ColorMaterial(0xBEBEBE);
			whiteMaterial.alphaPremultiplied = true;
			whiteMaterial.bothSides = true;
			whiteMaterial.lightPicker = lightPicker;
		}
		
		/**
		 * Initialise the particles
		 */
		private function initParticles():void
		{
			var bitmapData:BitmapData;
			var i:int;
			var j:int;
			var point:Vector3D;
			
			//create red and white point vectors for the Adobe Flash Player image
			bitmapData = Cast.bitmapData(PlayerImage);
			
			for (i = 0; i < bitmapData.width; i++) {
				for (j = 0; j < bitmapData.height; j++) {
					point = new Vector3D(PARTICLE_SIZE*(i - bitmapData.width / 2 - 100), PARTICLE_SIZE*( -j + bitmapData.height / 2));
					if (((bitmapData.getPixel(i, j) >> 8) & 0xff) <= 0xb0)
						redPoints.push(point);
					else
						whitePoints.push(point);
				}
			}
			
			//define where one logo stops and another starts
			redSeparation = redPoints.length;
			whiteSeparation = whitePoints.length;
			
			//create red and white point vectors for the Adobe AIR image
			bitmapData = Cast.bitmapData(AIRImage);
			
			for (i = 0; i < bitmapData.width; i++) {
				for (j = 0; j < bitmapData.height; j++) {
					point = new Vector3D(PARTICLE_SIZE*(i - bitmapData.width / 2 + 100), PARTICLE_SIZE*( -j + bitmapData.height / 2));
					if (((bitmapData.getPixel(i, j) >> 8) & 0xff) <= 0xb0)
						redPoints.push(point);
					else
						whitePoints.push(point);
				}
			}
			
			var numRed:uint = redPoints.length;
			var numWhite:uint = whitePoints.length;
			
			//setup the base geometry for one particle
			var plane:PlaneGeometry = new PlaneGeometry(PARTICLE_SIZE, PARTICLE_SIZE,1,1,false);
			
			//combine them into a list
			var redGeometrySet:Vector.<Geometry> = new Vector.<Geometry>;
			for (i = 0; i < numRed; i++)
				redGeometrySet.push(plane);
			
			var whiteGeometrySet:Vector.<Geometry> = new Vector.<Geometry>;
			for (i = 0; i < numWhite; i++)
				whiteGeometrySet.push(plane);
			
			//generate the particle geometries
			redGeometry = ParticleGeometryHelper.generateGeometry(redGeometrySet);
			whiteGeometry = ParticleGeometryHelper.generateGeometry(whiteGeometrySet);
			
			//define the red particle animations and init function
			redAnimationSet = new ParticleAnimationSet(true);
			redAnimationSet.addAnimation(new ParticleBillboardNode());
			redAnimationSet.addAnimation(new ParticleBezierCurveNode(ParticlePropertiesMode.LOCAL_STATIC));
			redAnimationSet.addAnimation(new ParticlePositionNode(ParticlePropertiesMode.LOCAL_STATIC));
			redAnimationSet.initParticleFunc = initRedParticleFunc;
			
			//define the white particle animations and init function
			whiteAnimationSet = new ParticleAnimationSet();
			whiteAnimationSet.addAnimation(new ParticleBillboardNode());
			whiteAnimationSet.addAnimation(new ParticleBezierCurveNode(ParticlePropertiesMode.LOCAL_STATIC));
			whiteAnimationSet.addAnimation(new ParticlePositionNode(ParticlePropertiesMode.LOCAL_STATIC));
			whiteAnimationSet.initParticleFunc = initWhiteParticleFunc;
		}
		
		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			//initialise animators vectors
			redAnimators = new Vector.<ParticleAnimator>(NUM_ANIMATORS, true);
			whiteAnimators = new Vector.<ParticleAnimator>(NUM_ANIMATORS, true);
			
			//create the red particle mesh
			redParticleMesh = new Mesh(redGeometry, redMaterial);
			
			//create the white particle mesh
			whiteParticleMesh = new Mesh(whiteGeometry, whiteMaterial);
			
			var i:uint = 0;
			for (i=0; i<NUM_ANIMATORS; i++) {
				//clone the red particle mesh
				redParticleMesh = redParticleMesh.clone() as Mesh;
				redParticleMesh.rotationY = 45*(i-1);
				scene.addChild(redParticleMesh);
				
				//clone the white particle mesh
				whiteParticleMesh = whiteParticleMesh.clone() as Mesh;
				whiteParticleMesh.rotationY = 45*(i-1);
				scene.addChild(whiteParticleMesh);
				
				//create and start the red particle animator
				redAnimators[i] = new ParticleAnimator(redAnimationSet);
				redParticleMesh.animator = redAnimators[i];
				scene.addChild(redParticleMesh);
				
				//create and start the white particle animator
				whiteAnimators[i] = new ParticleAnimator(whiteAnimationSet);
				whiteParticleMesh.animator = whiteAnimators[i];
				scene.addChild(whiteParticleMesh);
			}
		}
		
		/**
		 * Initialise the listeners
		 */
		private function initListeners():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		/**
		 * Initialiser function for red particle properties
		 */
		private function initRedParticleFunc(properties:ParticleProperties):void
		{
			properties.startTime = 0;
			properties.duration = 1;
			var degree1:Number = Math.random() * Math.PI * 2;
			var degree2:Number = Math.random() * Math.PI * 2;
			var r:Number = 500;
			
			if (properties.index < redSeparation)
				properties[ParticleBezierCurveNode.BEZIER_END_VECTOR3D] = new Vector3D(200*PARTICLE_SIZE, 0, 0);
			else
				properties[ParticleBezierCurveNode.BEZIER_END_VECTOR3D] = new Vector3D(-200*PARTICLE_SIZE, 0, 0);
			
			properties[ParticleBezierCurveNode.BEZIER_CONTROL_VECTOR3D] = new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), 2*r * Math.sin(degree2));
			properties[ParticlePositionNode.POSITION_VECTOR3D] = redPoints[properties.index];
		}
		
		/**
		 * Initialiser function for white particle properties
		 */
		private function initWhiteParticleFunc(properties:ParticleProperties):void
		{
			properties.startTime = 0;
			properties.duration = 1;
			var degree1:Number = Math.random() * Math.PI * 2;
			var degree2:Number = Math.random() * Math.PI * 2;
			var r:Number = 500;
			
			if (properties.index < whiteSeparation)
				properties[ParticleBezierCurveNode.BEZIER_END_VECTOR3D] = new Vector3D(200*PARTICLE_SIZE, 0, 0);
			else
				properties[ParticleBezierCurveNode.BEZIER_END_VECTOR3D] = new Vector3D(-200*PARTICLE_SIZE, 0, 0);
			
			properties[ParticleBezierCurveNode.BEZIER_CONTROL_VECTOR3D] = new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), r * Math.sin(degree2));
			properties[ParticlePositionNode.POSITION_VECTOR3D] = whitePoints[properties.index];
		}
		
		/**
		 * Navigation and render loop
		 */
		private function onEnterFrame(event:Event):void
		{
			//update the camera position
			cameraController.panAngle += 0.2;
			
			//update the particle animator playhead positions
			var i:uint;
			var time:uint;
			for (i=0; i<NUM_ANIMATORS; i++) {
				time = 1000*(Math.sin(getTimer()/5000 + Math.PI*i/4) + 1);
				redAnimators[i].update(time);
				whiteAnimators[i].update(time);
			}
			
			if (move) {
				cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
			}
			
			//update the light positions
			angle += Math.PI / 180;
			greenLight.x = Math.sin(angle) * 600;
			greenLight.z = Math.cos(angle) * 600;
			blueLight.x = Math.sin(angle+Math.PI) * 600;
			blueLight.z = Math.cos(angle+Math.PI) * 600;
			
			view.render();
		}
		
		/**
		 * Mouse down listener for navigation
		 */
		private function onMouseDown(event:MouseEvent):void
		{
			lastPanAngle = cameraController.panAngle;
			lastTiltAngle = cameraController.tiltAngle;
			lastMouseX = stage.mouseX;
			lastMouseY = stage.mouseY;
			move = true;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * Mouse up listener for navigation
		 */
		private function onMouseUp(event:MouseEvent):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * Mouse stage leave listener for navigation
		 */
		private function onStageMouseLeave(event:Event):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * stage listener for resize events
		 */
		private function onResize(event:Event = null):void
		{
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
			SignatureBitmap.y = stage.stageHeight - Signature.height;
		}
	}
}