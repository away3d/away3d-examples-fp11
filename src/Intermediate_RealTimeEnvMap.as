/*

Real time environment map reflections

Demonstrates:

How to use the CubeReflectionTexture to dynamically render environment maps.
How to use EnvMapMethod to apply the dynamic environment map to a material.
How to use the Elevation extrusions class to create a terrain from a heightmap.

Code by David Lenaerts & Rob Bateman
david.lenaerts@gmail.com
http://www.derschmale.com
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk

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
	import flash.filters.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.ui.*;
	
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.debug.*;
	import away3d.entities.*;
	import away3d.events.*;
	import away3d.extrusions.*;
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
	
	[SWF(backgroundColor="#000000", frameRate="30", quality="LOW")]
	
	public class Intermediate_RealTimeEnvMap extends Sprite
	{
		//constants for R2D2 movement
		public static const MAX_SPEED : Number = 1;
		public static const MAX_ROTATION_SPEED : Number = 10;
		public static const DRAG : Number = .95;
		public static const ACCELERATION : Number = .5;
		public static const ROTATION : Number = .5;
		
		// signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf:Class;
		
		// R2D2 Model
		[Embed(source="/../embeds/R2D2.obj", mimeType="application/octet-stream")]
		public static var R2D2Model:Class;
		
		// R2D2 Texture
		[Embed(source="/../embeds/r2d2_diffuse.jpg")]
		public static var R2D2Texture:Class;
		
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
		
		// desert texture
		[Embed(source="/../embeds/arid.jpg")]
		public static var DesertTexture:Class;
		
		//desert height map
		[Embed(source="/../embeds/desertHeightMap.jpg")]
		public static var DesertHeightMap:Class;
		
		// head Model
		[Embed(source="/../embeds/head.obj", mimeType="application/octet-stream")]
		public static var HeadModel:Class;
		
		//engine variables
		private var view:View3D;
		private var cameraController:HoverController;
		private var awayStats:AwayStats;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//material objects
		private var skyboxTexture : BitmapCubeTexture;
		private var reflectionTexture:CubeReflectionTexture;
		//private var floorMaterial : TextureMaterial;
		private var desertMaterial : TextureMaterial;
		private var reflectiveMaterial : ColorMaterial;
		private var r2d2Material : TextureMaterial;
		private var lightPicker : StaticLightPicker;
		private var fogMethod : FogMethod;
		
		//scene objects
		private var light:DirectionalLight;
		private var head:Mesh;
		private var r2d2:Mesh;
		
		//navigation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		
		//R2D2 motion variables
		//private var _drag : Number = 0.95;
		private var _acceleration : Number = 0;
		//private var _rotationDrag : Number = 0.95;
		private var _rotationAccel : Number = 0;
		private var _speed : Number = 0;
		private var _rotationSpeed : Number = 0;
		
		/**
		 * Constructor
		 */
		public function Intermediate_RealTimeEnvMap()
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
			initReflectionCube();
			initMaterials();
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
			
			//setup view
			view = new View3D();
			view.camera.lens.far = 4000;
			
			view.addSourceURL("srcview/index.html");
			addChild(view);

			//setup controller to be used on the camera
			cameraController = new HoverController(view.camera, null, 90, 10, 600, 2, 90);
			cameraController.lookAtPosition = new Vector3D(0, 120, 0);
			cameraController.wrapPanAngle = true;

			//add signature
			Signature = Sprite(new SignatureSwf());
			SignatureBitmap = new Bitmap(new BitmapData(Signature.width, Signature.height, true, 0));
			stage.quality = StageQuality.HIGH;
			SignatureBitmap.bitmapData.draw(Signature);
			stage.quality = StageQuality.LOW;
			addChild(SignatureBitmap);

			addChild(awayStats = new AwayStats(view));
		}

		/**
		 * Create an instructions overlay
		 */
		private function initText():void
		{
			var text : TextField = new TextField();
			text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
			text.embedFonts = true;
			text.antiAliasType = AntiAliasType.ADVANCED;
			text.gridFitType = GridFitType.PIXEL;
			text.width = 240;
			text.height = 100;
			text.selectable = false;
			text.mouseEnabled = false;
			text.text = "Cursor keys / WSAD - Move R2D2\n";
			text.appendText("Click+drag: Move camera\n");
			text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];

			addChild(text);
		}

		/**
		 * Initialise the lights in a scene
		 */
		private function initLights():void
		{
			//create global light
			light = new DirectionalLight(-1, -2, 1);
			light.color = 0xeedddd;
			light.ambient = 1;
			light.ambientColor = 0x808090;
			view.scene.addChild(light);
			
			//create global lightpicker
			lightPicker = new StaticLightPicker([light]);
			
			//create global fog method
			fogMethod = new FogMethod(500, 2000, 0x5f5e6e);
		}

		/**
		 * Initialized the ReflectionCubeTexture that will contain the environment map render
		 */
		private function initReflectionCube() : void
		{
		}


		/**
		 * Initialise the materials
		 */
		private function initMaterials():void
		{
			// create reflection texture with a dimension of 256x256x256
			reflectionTexture = new CubeReflectionTexture(256);
			reflectionTexture.farPlaneDistance = 3000;
			reflectionTexture.nearPlaneDistance = 50;
			
			// center the reflection at (0, 100, 0) where our reflective object will be
			reflectionTexture.position = new Vector3D(0, 100, 0);
			
			//setup the skybox texture
			skyboxTexture = new BitmapCubeTexture(
				Cast.bitmapData(PosX), Cast.bitmapData(NegX),
				Cast.bitmapData(PosY), Cast.bitmapData(NegY),
				Cast.bitmapData(PosZ), Cast.bitmapData(NegZ)
			);
			
			// setup desert floor material
			desertMaterial = new TextureMaterial(Cast.bitmapTexture(DesertTexture));
			desertMaterial.lightPicker = lightPicker;
			desertMaterial.addMethod(fogMethod);
			desertMaterial.repeat = true;
			desertMaterial.gloss = 5;
			desertMaterial.specular = .1;
			
			//setup R2D2 material
			r2d2Material = new TextureMaterial(Cast.bitmapTexture(R2D2Texture));
			r2d2Material.lightPicker = lightPicker;
			r2d2Material.addMethod(fogMethod);
			r2d2Material.addMethod(new EnvMapMethod(skyboxTexture,.2));

			// setup fresnel method using our reflective texture in the place of a static environment map
			var fresnelMethod : FresnelEnvMapMethod = new FresnelEnvMapMethod(reflectionTexture);
			fresnelMethod.normalReflectance = .6;
			fresnelMethod.fresnelPower = 2;
			
			//setup the reflective material
			reflectiveMaterial = new ColorMaterial(0x000000);
			reflectiveMaterial.addMethod(fresnelMethod);
		}
		
		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			//create the skybox
			view.scene.addChild(new SkyBox(skyboxTexture));
			
			//create the desert ground
			var desert:Elevation = new Elevation(desertMaterial, Cast.bitmapData(DesertHeightMap), 5000, 300, 5000, 250, 250);
			desert.y = -3;
			desert.geometry.scaleUV(25, 25);
			view.scene.addChild(desert);
			
			//enabled the obj parser
			AssetLibrary.enableParser(OBJParser);
			
			// load model data
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			AssetLibrary.loadData(new HeadModel());
			AssetLibrary.loadData(new R2D2Model());
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
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			onResize();
		}

		/**
		 * Navigation and render loop
		 */
		private function onEnterFrame(event:Event):void
		{
			if (move) {
				cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
			}
			
			if (r2d2) {
				//drag
				_speed *= DRAG;
				
				//acceleration
				_speed += _acceleration;
				
				//speed bounds
				if (_speed > MAX_SPEED)
					_speed = MAX_SPEED;
				else if (_speed < -MAX_SPEED)
					_speed = -MAX_SPEED;
				
				//rotational drag
				_rotationSpeed *= DRAG;
				
				//rotational acceleration
				_rotationSpeed += _rotationAccel;
				
				//rotational speed bounds
				if (_rotationSpeed > MAX_ROTATION_SPEED)
					_rotationSpeed = MAX_ROTATION_SPEED;
				else if (_rotationSpeed < -MAX_ROTATION_SPEED)
					_rotationSpeed = -MAX_ROTATION_SPEED;
				
				//apply motion to R2D2
				r2d2.moveForward(_speed);
				r2d2.rotationY += _rotationSpeed;
				
				//keep R2D2 within max and min radius
				var radius:Number = Math.sqrt(r2d2.x*r2d2.x + r2d2.z*r2d2.z);
				if (radius < 200) {
					r2d2.x = 200*r2d2.x/radius;
					r2d2.z = 200*r2d2.z/radius;
				} else if (radius > 500) {
					r2d2.x = 500*r2d2.x/radius;
					r2d2.z = 500*r2d2.z/radius;
				}
				
				//pan angle overridden by R2D2 position
				cameraController.panAngle = 90 - 180*Math.atan2(r2d2.z, r2d2.x)/Math.PI;
			}

			// render the view's scene to the reflection texture (view is required to use the correct stage3DProxy)
			reflectionTexture.render(view);
			view.render();
		}
		
		/**
		 * Listener function for asset complete event on loader
		 */
		private function onAssetComplete(event:AssetEvent):void
		{
			if (event.asset.assetType == AssetType.MESH) {
				if( event.asset.name == "g0" ) { // Head
					head = event.asset as Mesh;
					head.scale(60);
					head.y = 180;
					head.rotationY = -90;
					head.material = reflectiveMaterial;
					view.scene.addChild(head);
				}
				else { // R2D2
					r2d2 = event.asset as Mesh;
					r2d2.scale( 5 );
					r2d2.material = r2d2Material;
					r2d2.x = 200;
					r2d2.y = 30;
					r2d2.z = 0;
					view.scene.addChild(r2d2);
				}
			}
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
		 * Listener for keyboard down events
		 */
		private function onKeyDown(event:KeyboardEvent):void
		{
			switch(event.keyCode) {
				case Keyboard.W:
				case Keyboard.UP:
					_acceleration = ACCELERATION;
					break;
				case Keyboard.S:
				case Keyboard.DOWN:
					_acceleration = -ACCELERATION;
					break;
				case Keyboard.A:
				case Keyboard.LEFT:
					_rotationAccel = -ROTATION;
					break;
				case Keyboard.D:
				case Keyboard.RIGHT:
					_rotationAccel = ROTATION;
					break;
			}
		}

		/**
		 * Listener for keyboard up events
		 */
		private function onKeyUp(event:KeyboardEvent):void
		{
			switch(event.keyCode) {
				case Keyboard.W:
				case Keyboard.S:
				case Keyboard.UP:
				case Keyboard.DOWN:
					_acceleration = 0;
					break;
				case Keyboard.A:
				case Keyboard.D:
				case Keyboard.LEFT:
				case Keyboard.RIGHT:
					_rotationAccel = 0;
					break;
			}
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
