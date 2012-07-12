/*

Bones animation loading and interaction example in Away3d

Demonstrates:

How to load an AWD file with bones animation frmo external resources.
How to map animation data after loading in order to playback an animation sequence.
How to control the movement of a game character using the mouse.
How to use a skybox with a fog method to create a seamless play area.

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
	import away3d.animators.transitions.*;
	import away3d.cameras.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.debug.*;
	import away3d.entities.Mesh;
	import away3d.events.*;
	import away3d.library.*;
	import away3d.library.assets.*;
	import away3d.lights.*;
	import away3d.loaders.parsers.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.*;
	import away3d.materials.methods.*;
	import away3d.primitives.*;
	import away3d.textures.*;
	import away3d.utils.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.text.*;
	import flash.ui.*;
	
	[SWF(backgroundColor="#000000", frameRate="30", quality="LOW")]
	
	public class Intermediate_CharacterAnimation extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf:Class;
		
		//polar bear color map
		[Embed(source="/../embeds/snow_diffuse.png")]
		private var SnowDiffuse:Class;
		
		//polar bear normal map
		[Embed(source="/../embeds/snow_normals.png")]
		private var SnowNormal:Class;
		
		//polar bear specular map
		[Embed(source="/../embeds/snow_specular.png")]
		private var SnowSpecular:Class;
		
		//snow color map
		[Embed(source="/../embeds/polarbear_diffuse.jpg")]
		private var BearDiffuse:Class;
		
		//snow normal map
		[Embed(source="/../embeds/polarbear_normals.jpg")]
		private var BearNormal:Class;
		
		//snow specular map
		[Embed(source="/../embeds/polarbear_specular.jpg")]
		private var BearSpecular:Class;
		
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
		private var awayStats:AwayStats;
		
		//animation variables
		private var animator:SkeletonAnimator;
		private var animationSet:SkeletonAnimationSet;
		private var stateTransition:CrossfadeStateTransition = new CrossfadeStateTransition(0.5);
		private var isRunning:Boolean;
		private var isMoving:Boolean;
		private var movementDirection:Number;
		private var currentAnim:String;
		private var currentRotationInc:Number = 0;
		
		//animation constants
		private const ANIM_BREATHE:String = "Breathe";
		private const ANIM_WALK:String = "Walk";
		private const ANIM_RUN:String = "Run";
		private const ROTATION_SPEED:Number = 3;
		private const RUN_SPEED:Number = 2;
		private const WALK_SPEED:Number = 1;
		private const BREATHE_SPEED:Number = 1;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//light objects
		private var sunLight:DirectionalLight;
		private var skyLight:PointLight;
		private var lightPicker:StaticLightPicker;
		private var filteredShadowMapMethod:TripleFilteredShadowMapMethod;
		private var fogMethod:FogMethod;
		
		//material objects
		private var bearMaterial:TextureMaterial;
		private var groundMaterial:TextureMaterial;
		private var cubeTexture:BitmapCubeTexture;
		
		//scene objects
		private var text:TextField;
		private var mesh:Mesh;
		private var ground:Mesh;
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
			initText();
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
			var placeHolder:ObjectContainer3D = new ObjectContainer3D();
			placeHolder.z = 1000;
			cameraController = new LookAtController(camera, placeHolder);
			
			view.addSourceURL("srcview/index.html");
			addChild(view);
			
			//add signature
			Signature = Sprite(new SignatureSwf());
			SignatureBitmap = new Bitmap(new BitmapData(Signature.width, Signature.height, true, 0));
			stage.quality = StageQuality.HIGH;
			SignatureBitmap.bitmapData.draw(Signature);
			stage.quality = StageQuality.LOW;
			addChild(SignatureBitmap);
			
			awayStats = new AwayStats(view);
			addChild(awayStats);
		}
		
		/**
		 * Create an instructions overlay
		 */
		private function initText():void
		{
			text = new TextField();
			text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
			text.width = 240;
			text.height = 100;
			text.selectable = false;
			text.mouseEnabled = false;
			text.text = "Cursor keys / WSAD - move\n"; 
			text.appendText("SHIFT - hold down to run\n");
			
			text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
			
			addChild(text);
		}
		
		/**
		 * Initialise the lights
		 */
		private function initLights():void
		{
			//create a light for shadows that mimics the sun's position in the skybox
			sunLight = new DirectionalLight(-1, -0.4, 1);
			sunLight.color = 0xFFFFFF;
			sunLight.castsShadows = true;
			sunLight.ambient = 1;
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
			
			lightPicker = new StaticLightPicker([sunLight, skyLight]);
			
			//create a global shadow method
			filteredShadowMapMethod = new TripleFilteredShadowMapMethod(sunLight);
			//filteredShadowMapMethod.epsilon = 0.1;
			
			//create a global fog method
			fogMethod = new FogMethod(0, 3000, 0x5f5e6e);
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
			groundMaterial = new TextureMaterial(Cast.bitmapTexture(SnowDiffuse), true, true, true);
			groundMaterial.lightPicker = lightPicker;
			groundMaterial.specularMap = Cast.bitmapTexture(SnowSpecular);
			groundMaterial.normalMap = Cast.bitmapTexture(SnowNormal);
			groundMaterial.shadowMethod = filteredShadowMapMethod;
			groundMaterial.addMethod(fogMethod);
			groundMaterial.ambient = 0.5;
			ground = new Mesh(new PlaneGeometry(50000, 50000), groundMaterial);
			ground.geometry.scaleUV(50, 50);
			ground.castsShadows = true;
			scene.addChild(ground);
			
			//create a skybox
			cubeTexture = new BitmapCubeTexture(Cast.bitmapData(PosX), Cast.bitmapData(NegX), Cast.bitmapData(PosY), Cast.bitmapData(NegY), Cast.bitmapData(PosZ), Cast.bitmapData(NegZ));
			skyBox = new SkyBox(cubeTexture);
			scene.addChild(skyBox);
		}
		
		/**
		 * Initialise the listeners
		 */
		private function initListeners():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		/**
		 * Navigation and render loop
		 */
		private function onEnterFrame(event:Event):void
		{
			//update character animation
			if (mesh)
				mesh.rotationY += currentRotationInc;
			
			view.render();
		}
		
		/**
		 * Listener function for asset complete event on loader
		 */
		private function onAssetComplete(event:AssetEvent):void
		{
			if (event.asset.assetType == AssetType.SKELETON) {
				//create a new skeleton animation set
				animationSet = new SkeletonAnimationSet(3);
				
				//wrap our skeleton animation set in an animator object and add our sequence objects
				animator = new SkeletonAnimator(animationSet, event.asset as Skeleton, false);
				
				//apply our animator to our mesh
				mesh.animator = animator;
				
				//register our mesh as the lookAt target
				cameraController.lookAtObject = mesh;
				
				//default to breathe sequence
				//stop();
				
				//add key listeners
				stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
				stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			} else if (event.asset.assetType == AssetType.ANIMATION_STATE) {
				//create state objects for each animation state encountered
				var animationState:SkeletonAnimationState = event.asset as SkeletonAnimationState;
				animationSet.addState(animationState.name, animationState);
				if (animationState.name == ANIM_BREATHE)
					stop();
			} else if (event.asset.assetType == AssetType.MESH) {
				//create material object and assign it to our mesh
				bearMaterial = new TextureMaterial(Cast.bitmapTexture(BearDiffuse));
				bearMaterial.shadowMethod = filteredShadowMapMethod;
				bearMaterial.normalMap = Cast.bitmapTexture(BearNormal);
				bearMaterial.specularMap = Cast.bitmapTexture(BearSpecular);
				bearMaterial.addMethod(fogMethod);
				bearMaterial.lightPicker = lightPicker;
				bearMaterial.gloss = 50;
				bearMaterial.specular = 0.5;
				bearMaterial.ambientColor = 0xAAAAAA;
				bearMaterial.ambient = 0.5;
				
				//create mesh object and assign our animation object and material object
				mesh = event.asset as Mesh;
				mesh.material = bearMaterial;
				mesh.castsShadows = true;
				mesh.scale(1.5);
				mesh.z = 1000;
				mesh.rotationY = -45;
				scene.addChild(mesh);
				
			}
		}
		
		/**
		 * Key down listener for animation
		 */
		private function onKeyDown(event:KeyboardEvent):void
		{
			switch (event.keyCode) {
				case Keyboard.SHIFT:
					isRunning = true;
					if (isMoving)
						updateMovement(movementDirection);
					break;
				case Keyboard.UP:
				case Keyboard.W:
					updateMovement(movementDirection = 1);
					break;
				case Keyboard.DOWN:
				case Keyboard.S:
					updateMovement(movementDirection = -1);
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
					currentRotationInc = -ROTATION_SPEED;
					break;
				case Keyboard.RIGHT:
				case Keyboard.D:
					currentRotationInc = ROTATION_SPEED;
					break;
			}
		}
		
		private function onKeyUp(event:KeyboardEvent):void
		{
			switch (event.keyCode) {
				case Keyboard.SHIFT:
					isRunning = false;
					if (isMoving)
						updateMovement(movementDirection);
					break;
				case Keyboard.UP:
				case Keyboard.W:
				case Keyboard.DOWN:
				case Keyboard.S:
					stop();
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
				case Keyboard.RIGHT:
				case Keyboard.D:
					currentRotationInc = 0;
					break;
			}
		}
		
		private function updateMovement(dir:Number):void
		{
			isMoving = true;
			
			//update animator speed
			animator.playbackSpeed = dir*(isRunning? RUN_SPEED : WALK_SPEED);
			
			//update animator sequence
			var anim:String = isRunning? ANIM_RUN : ANIM_WALK;
			if (currentAnim == anim)
				return;
			
			currentAnim = anim;
			
			animator.play(currentAnim, stateTransition);
		}
		
		private function stop():void
		{
			isMoving = false;
			
			//update animator speed
			animator.playbackSpeed = BREATHE_SPEED;
			
			//update animator sequence
			if (currentAnim == ANIM_BREATHE)
				return;
			
			currentAnim = ANIM_BREATHE;
			
			animator.play(currentAnim, stateTransition);
		}
		
		/**
		 * stage listener for resize events
		 */
		private function onResize(event:Event = null):void
		{
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
			SignatureBitmap.y = stage.stageHeight - Signature.height;
			awayStats.x = stage.stageWidth - awayStats.width;
		}
	}
}
