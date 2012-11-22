/*

Real time planar reflections

Demonstrates:

How to use the PlanarReflectionTexture to render dynamic planar reflections
How to use EnvMapMethod to apply the dynamic environment map to a material

Code by David Lenaerts
david.lenaerts@gmail.com
http://www.derschmale.com

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
	import away3d.cameras.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.debug.*;
	import away3d.entities.Mesh;
	import away3d.events.*;
	import away3d.extrusions.Elevation;
	import away3d.library.AssetLibrary;
	import away3d.library.assets.*;
	import away3d.lights.*;
	import away3d.loaders.parsers.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.*;
	import away3d.materials.methods.*;
	import away3d.primitives.PlaneGeometry;
	import away3d.primitives.SkyBox;
	import away3d.textures.BitmapCubeTexture;
	import away3d.textures.BitmapTexture;
	import away3d.textures.PlanarReflectionTexture;
	import away3d.utils.*;

	import flash.display.*;
	import flash.events.*;
	import flash.filters.DropShadowFilter;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;

	[SWF(backgroundColor="#000000", frameRate="30", quality="LOW")]
	
	public class Intermediate_PlanarReflections extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf:Class;

		[Embed(source="/../embeds/r2d2_diffuse.jpg")]
		public static var R2D2Albedo:Class;

		[Embed(source="/../embeds/skybox/space_negX.jpg")]
		public static var SkyBoxMinX:Class;

		[Embed(source="/../embeds/skybox/space_posX.jpg")]
		public static var SkyBoxMaxX:Class;

		[Embed(source="/../embeds/skybox/space_negY.jpg")]
		public static var SkyBoxMinY:Class;

		[Embed(source="/../embeds/skybox/space_posY.jpg")]
		public static var SkyBoxMaxY:Class;

		[Embed(source="/../embeds/skybox/space_negZ.jpg")]
		public static var SkyBoxMinZ:Class;

		[Embed(source="/../embeds/skybox/space_posZ.jpg")]
		public static var SkyBoxMaxZ:Class;

		[Embed(source="/../embeds/desertsand.jpg")]
		public static var DesertAlbedo:Class;

		[Embed(source="/../embeds/desertHeightMap.jpg")]
		public static var HeightMap:Class;

		[Embed(source="/../embeds/R2D2.obj", mimeType="application/octet-stream")]
		public static var R2D2_Obj:Class;

		public static const MAX_SPEED : Number = 1;
		public static const MAX_ROTATION_SPEED : Number = 10;
		public static const ACCELERATION : Number = .5;
		public static const ROTATION : Number = .5;

		//engine variables
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var cameraController:HoverController;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//material objects
		private var floorMaterial : TextureMaterial;
		private var desertMaterial : TextureMaterial;
		private var reflectiveMaterial : ColorMaterial;
		private var r2d2Material : TextureMaterial;
		private var lightPicker : StaticLightPicker;
		private var fogMethod : FogMethod;
		private var skyboxTexture : BitmapCubeTexture;


		//scene objects
		private var light:DirectionalLight;
		private var r2d2:Mesh;

		//navigation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		private var _rotationAccel : Number = 0;
		private var _acceleration : Number = 0;
		private var _speed : Number = 0;
		private var _rotationSpeed : Number = 0;

		// reflection variables
		private var reflectionTexture:PlanarReflectionTexture;


		/**
		 * Constructor
		 */
		public function Intermediate_PlanarReflections()
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
			initReflectionTexture();
			initSkyBox();
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

			view = new View3D();

			scene = view.scene;
			camera = view.camera;
			camera.lens.far = 4000;

			//setup controller to be used on the camera
			cameraController = new HoverController(camera, null, 45, 10, 400, 3, 90);
			cameraController.autoUpdate = false;	// will update manually to be sure it happens before any rendering in a frame

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
		 * Create an instructions overlay
		 */
		private function initText():void
		{
			var text : TextField = new TextField();
			text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
			text.width = 240;
			text.height = 100;
			text.y = 100;
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
			light = new DirectionalLight(-1, -2, 1);
			light.color = 0xeedddd;
			light.ambient = 1;
			light.ambientColor = 0x808090;
			scene.addChild(light);
		}

		/**
		 * Initialized the PlanarReflectionTexture that will contain the environment map render
		 */
		private function initReflectionTexture() : void
		{
			reflectionTexture = new PlanarReflectionTexture();
		}


		/**
		 * Initialise the materials
		 */
		private function initMaterials():void
		{
			var desertTexture : BitmapTexture = Cast.bitmapTexture(DesertAlbedo);
			lightPicker = new StaticLightPicker([light]);
			fogMethod = new FogMethod(0, 2000, 0x100215);

			floorMaterial = new TextureMaterial(desertTexture);
			floorMaterial.lightPicker = lightPicker;
			floorMaterial.addMethod(fogMethod);
			floorMaterial.repeat = true;
			floorMaterial.gloss = 5;
			floorMaterial.specular = .1;

			desertMaterial = new TextureMaterial(desertTexture);
			desertMaterial.lightPicker = lightPicker;
			desertMaterial.addMethod(fogMethod);
			desertMaterial.repeat = true;
			desertMaterial.gloss = 5;
			desertMaterial.specular = .1;

			r2d2Material = new TextureMaterial(Cast.bitmapTexture(R2D2Albedo));
			r2d2Material.lightPicker = lightPicker;
			r2d2Material.addMethod(fogMethod);
			r2d2Material.addMethod(new EnvMapMethod(skyboxTexture,.2));

			// create a PlanarReflectionMethod
			var reflectionMethod : PlanarReflectionMethod = new PlanarReflectionMethod(reflectionTexture);
			reflectiveMaterial = new ColorMaterial(0x000000,.9);
			reflectiveMaterial.addMethod(reflectionMethod);
		}

		/**
		 * Initialise the skybox
		 */
		private function initSkyBox() : void
		{
			skyboxTexture = new BitmapCubeTexture(
					Cast.bitmapData(SkyBoxMaxX), Cast.bitmapData(SkyBoxMinX),
					Cast.bitmapData(SkyBoxMaxY), Cast.bitmapData(SkyBoxMinY),
					Cast.bitmapData(SkyBoxMaxZ), Cast.bitmapData(SkyBoxMinZ)
			);

			scene.addChild(new SkyBox(skyboxTexture));
		}
		
		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			initDesert();
			initMirror();

			//default available parsers to all
			Parsers.enableAllBundled();
			
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			AssetLibrary.loadData(new R2D2_Obj());
		}

		/**
		 * Creates the objects forming the desert, including a small "floor" patch able to receive shadows.
		 */
		private function initDesert() : void
		{
			var desert:Elevation = new Elevation(desertMaterial, Cast.bitmapData(HeightMap), 5000, 600, 5000, 75, 75);
			desert.y = -3;
			desert.geometry.scaleUV(25, 25);
			scene.addChild(desert);

			// small desert patch that can receive shadows
			var floor:Mesh = new Mesh(new PlaneGeometry(800, 800, 1, 1), floorMaterial);
			floor.geometry.scaleUV(800 / 5000 * 25, 800 / 5000 * 25);	// match uv coords with that of the desert
			scene.addChild(floor);
		}

		/**
		 * Creates the sphere that will reflect its environment
		 */
		private function initMirror() : void
		{
			var geometry:PlaneGeometry = new PlaneGeometry(400, 200, 1, 1, false);
			var mesh:Mesh = new Mesh(geometry, reflectiveMaterial);
			mesh.y = mesh.maxY;
			mesh.z = -200;
			mesh.rotationY = 180;
			scene.addChild(mesh);

			// need to apply plane's transform to the reflection, compatible with PlaneGeometry created in this manner
			// other ways is to set reflectionTexture.plane = new Plane3D(...)
			reflectionTexture.applyTransform(mesh.sceneTransform);
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

			if (r2d2)
				updateR2D2();

			cameraController.update();

			// render the view's scene to the reflection texture (view is required to use the correct stage3DProxy)
			reflectionTexture.render(view);
			view.render();
		}

		private function updateR2D2() : void
		{
			_speed *= .95;
			_speed += _acceleration;
			if (_speed > MAX_SPEED) _speed = MAX_SPEED;
			else if (_speed < -MAX_SPEED) _speed = -MAX_SPEED;

			_rotationSpeed += _rotationAccel;
			_rotationSpeed *= .9;
			if (_rotationSpeed > MAX_ROTATION_SPEED) _rotationSpeed = MAX_ROTATION_SPEED;
			else if (_rotationSpeed < -MAX_ROTATION_SPEED) _rotationSpeed = -MAX_ROTATION_SPEED;

			r2d2.moveForward(_speed);
			r2d2.rotationY += _rotationSpeed;
		}
		
		/**
		 * Listener function for asset complete event on loader
		 */
		private function onAssetComplete(event:AssetEvent):void
		{
			if (event.asset.assetType == AssetType.MESH) {
				r2d2 = event.asset as Mesh;
				r2d2.scale(5);
				r2d2.material = r2d2Material;
				r2d2.x = 200;
				r2d2.y = 30;
				r2d2.z = 0;
				scene.addChild(r2d2);
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
		 * stage listener for resize events
		 */
		private function onResize(event:Event = null):void
		{
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
			SignatureBitmap.y = stage.stageHeight - Signature.height;
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
	}
}