﻿/*

3ds file loading example in Away3d

Demonstrates:

How to use the Loader3D object to load an embedded internal 3ds model.
How to map an external asset reference inside a file to an internal embedded asset
How to extract material data and use it to set custom material properties on a model.

Code by Rob Bateman
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk

This code is distributed under the MIT License

Copyright (c)  

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
	import away3d.animators.*;
	import away3d.animators.data.*;
	import away3d.animators.skeleton.*;
	import away3d.cameras.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.core.base.*;
	import away3d.debug.*;
	import away3d.entities.Mesh;
	import away3d.events.*;
	import away3d.library.*;
	import away3d.library.assets.*;
	import away3d.lights.*;
	import away3d.lights.shadowmaps.PartialDirectionalShadowMapper;
	import away3d.loaders.*;
	import away3d.loaders.parsers.*;
	import away3d.materials.*;
	import away3d.materials.methods.*;
	import away3d.materials.utils.CubeMap;
	import away3d.primitives.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.text.AntiAliasType;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	
	[SWF(backgroundColor="#000000", frameRate="60", quality="LOW")]
	
	public class Intermediate_CharacterAnimation extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf:Class;
		
		//polar bear color map
		[Embed(source="/../embeds/snow-colour.png")]
		private var SnowColor:Class;
		
		//polar bear normal map
		[Embed(source="/../embeds/snow-normal-tangent.png")]
		private var SnowNormal:Class;
		
		//polar bear specular map
		[Embed(source="/../embeds/snow-specular.png")]
		private var SnowSpecular:Class;
		
		//snow color map
		[Embed(source="/../embeds/PolarBear_colour.jpg")]
		private var BearColor:Class;
		
		//snow normal map
		[Embed(source="/../embeds/PolarBear_normal.jpg")]
		private var BearNormal:Class;
		
		//snow specular map
		[Embed(source="/../embeds/PolarBear_specular.jpg")]
		private var BearSpecular:Class;
		
		//ground texture
		[Embed(source="/../embeds/CoarseRedSand.jpg")]
		private var SandTexture:Class;
		
		//skybox textures
		[Embed(source="/../embeds/skybox/sky_posX.jpg")]
		private var PosX:Class;
		[Embed(source="/../embeds/skybox/sky_negX.jpg")]
		private var NegX:Class;
		[Embed(source="/../embeds/skybox/sky_posY.jpg")]
		private var PosY:Class;
		[Embed(source="/../embeds/skybox/sky_negY.jpg")]
		private var NegY:Class;
		[Embed(source="/../embeds/skybox/sky_posZ.jpg")]
		private var PosZ:Class;
		[Embed(source="/../embeds/skybox/sky_negZ.jpg")]
		private var NegZ:Class;
		
		//engine variables
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var cameraController:LookAtController;
		
		//animation variables
		private var animation:SkeletonAnimation;
		private var animator:SmoothSkeletonAnimator;
		private var breatheSequence:SkeletonAnimationSequence;
		private var walkSequence:SkeletonAnimationSequence;
		private var runSequence:SkeletonAnimationSequence;
		private var isRunning:Boolean;
		private var isMoving:Boolean;
		private var movementDirection:Number;
		private var currentAnim:String;
		private var currentRotation:Number = 0;
		
		//animation constants
		private const ANIM_BREATHE:String = "Breathe";
		private const ANIM_WALK:String = "Walk";
		private const ANIM_RUN:String = "Run";
		private const XFADE_TIME:Number = 0.5;
		private const ROTATION_SPEED : Number = 3;
		private const RUN_SPEED : Number = 2;
		private const WALK_SPEED : Number = 1;
		private const BREATHE_SPEED : Number = 1;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//light objects
		private var sunLight:DirectionalLight;
		private var skyLight:PointLight;
		private var nearShadowMethod:NearShadowMapMethod;
		private var filteredShadowMapMethod:TripleFilteredShadowMapMethod
		private var fogMethod:FogMethod
		//material objects
		private var bearMaterial:BitmapMaterial;
		private var groundMaterial:BitmapMaterial;
		private var cubeMap:CubeMap;
		
		//scene objects
		private var mesh:Mesh;
		private var ground:Plane;
		private var skyBox:SkyBox;
		
		/**
		 * Constructor
		 */
		public function Intermediate_CharacterAnimation()
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
			camera.lens.far = 5000;
			camera.lens.near = 20;
			camera.y = 500;
			camera.z = 0;
			camera.lookAt(new Vector3D(0, 0, 1000));
				
			view = new View3D();
			view.scene = scene;
			view.camera = camera;
			
			//setup controller to be used on the camera
			cameraController = new LookAtController(camera);
			
			//view.addSourceURL("srcview/index.html");
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
		
		private function initLights():void
		{
			//create a light for shadows that mimics the sun's position in the skybox
			sunLight = new DirectionalLight(-1, -0.4, 1);
			sunLight.color = 0xFFFFFF;
			sunLight.castsShadows = true;
			sunLight.diffuse = 1;
			sunLight.specular = 1;
			scene.addChild(sunLight);
			
			//create a light for ambient effect that mimics the sky
			skyLight = new PointLight();
			skyLight.y = 500;
			skyLight.color = 0xFFFFFF;
			skyLight.diffuse = 1;
			skyLight.specular = 0.5;
			skyLight.radius = 2000;
			skyLight.fallOff = 2500;
			scene.addChild(skyLight);
			
			filteredShadowMapMethod = new TripleFilteredShadowMapMethod(sunLight);
			fogMethod = new FogMethod(500, 0x5f5e6e);
		}
		
		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			
			AssetLibrary.enableParser(AWDParser);
			
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			AssetLibrary.load(new URLRequest("assets/PolarBear.awd"));
			
			//create a snowy ground plane
			groundMaterial = new BitmapMaterial((new SnowColor()).bitmapData, true, true, true);
			groundMaterial.lights = [sunLight, skyLight];
			groundMaterial.specularMap = new SnowSpecular().bitmapData;
			groundMaterial.normalMap = new SnowNormal().bitmapData;
			groundMaterial.shadowMethod = filteredShadowMapMethod;
			groundMaterial.addMethod(fogMethod);
			ground = new Plane(groundMaterial, 50000, 50000);
			ground.geometry.scaleUV(50);
			ground.castsShadows = true;
			scene.addChild(ground);
			
			//create a skybox
			cubeMap = new CubeMap(new PosX().bitmapData, new NegX().bitmapData, new PosY().bitmapData, new NegY().bitmapData, new PosZ().bitmapData, new NegZ().bitmapData);
			skyBox = new SkyBox(cubeMap);
			scene.addChild(skyBox);
		}
		
		/**
		 * Initialise the listeners
		 */
		private function initListeners():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		/**
		 * Navigation and render loop
		 */
		private function onEnterFrame(event:Event):void
		{
			//update character animation
			if (mesh) {
				mesh.rotationY += currentRotation;
				
			}
			
			view.render();
		}
		
		/**
		 * Listener function for asset complete event on loader
		 */
		private function onAssetComplete(event:AssetEvent):void
		{
			if (event.asset.assetType == AssetType.SKELETON)
			{
				//create an animation object
				animation = new SkeletonAnimation(event.asset as Skeleton, 3, true);
			}
			else if (event.asset.assetType == AssetType.MESH)
			{
				//create material object and assign it to our mesh
				bearMaterial = new BitmapMaterial(new BearColor().bitmapData);
				bearMaterial.shadowMethod = filteredShadowMapMethod;
				bearMaterial.normalMap = new BearNormal().bitmapData;
				bearMaterial.specularMap = new BearSpecular().bitmapData;
				bearMaterial.addMethod(fogMethod);
				bearMaterial.lights = [sunLight, skyLight];
				bearMaterial.gloss = 50;
				bearMaterial.specular = 0.5;
				bearMaterial.ambientColor = 0xAAAAAA;
				bearMaterial.ambient = 1;
				
				//create mesh object and assign our animation object and material object
				mesh = event.asset as Mesh;
				mesh.geometry.animation = animation;
				mesh.material = bearMaterial;
				mesh.castsShadows = true;
				mesh.scale(50);
				mesh.z = 1000;
				mesh.rotationY = -45;
				scene.addChild(mesh);
				
				//wrap our mesh animation state in an animator object and add our sequence objects
				animator = new SmoothSkeletonAnimator(mesh.animationState as SkeletonAnimationState);
				animator.addSequence(breatheSequence);
				animator.addSequence(walkSequence);
				animator.addSequence(runSequence);
				
				//register our mesh as the lookAt target
				cameraController.lookAtObject = mesh;
				
				//default to breathe sequence
				stop();
			}
			else if (event.asset.assetType == AssetType.ANIMATION)
			{
				//create sequence objects for each animation sequence encountered
				if (event.asset.name == ANIM_BREATHE)
					breatheSequence = event.asset as SkeletonAnimationSequence;
				else if (event.asset.name == ANIM_WALK)
					walkSequence = event.asset as SkeletonAnimationSequence;
				else if (event.asset.name == ANIM_RUN)
					runSequence = event.asset as SkeletonAnimationSequence;
			}
		}
		
		/**
		 * Key down listener for animation
		 */
		private function onKeyDown(event : KeyboardEvent) : void
		{
			switch (event.keyCode) {
				case Keyboard.SHIFT:
					isRunning = true;
					if (isMoving)
						updateMovement(movementDirection);
					break;
				case Keyboard.UP:
					updateMovement(movementDirection = 1);
					break;
				case Keyboard.DOWN:
					updateMovement(movementDirection = -1);
					break;
				case Keyboard.LEFT:
					currentRotation = -ROTATION_SPEED;
					break;
				case Keyboard.RIGHT:
					currentRotation = ROTATION_SPEED;
					break;
			}
		}
		
		private function onKeyUp(event : KeyboardEvent) : void
		{
			switch (event.keyCode) {
				case Keyboard.SHIFT:
					isRunning = false;
					if (isMoving)
						updateMovement(movementDirection);
					break;
				case Keyboard.UP:
				case Keyboard.DOWN:
					stop();
					break;
				case Keyboard.LEFT:
				case Keyboard.RIGHT:
					currentRotation = 0;
					break;
			}
		}
		
		private function updateMovement(dir:Number) : void
		{
			isMoving = true;
			
			//update animator speed
			animator.timeScale = dir*(isRunning? RUN_SPEED : WALK_SPEED);
			
			//update animator sequence
			var anim:String = isRunning? ANIM_RUN : ANIM_WALK;
			if (currentAnim == anim)
				return;
			
			currentAnim = anim;
			
			animator.play(currentAnim, XFADE_TIME);
		}
		
		private function stop() : void
		{
			isMoving = false;
			
			//update animator speed
			animator.timeScale = BREATHE_SPEED;
			
			//update animator sequence
			if (currentAnim == ANIM_BREATHE)
				return;
			
			currentAnim = ANIM_BREATHE;
			
			animator.play(currentAnim, XFADE_TIME);
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