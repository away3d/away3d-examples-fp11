package
{
	import away3d.cameras.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.debug.*;
	import away3d.entities.Mesh;
	import away3d.extrusions.*;
	import away3d.filters.*;
	import away3d.lights.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.*;
	import away3d.materials.methods.*;
	import away3d.primitives.*;
	import away3d.textures.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.ui.*;
	
	[SWF(backgroundColor="#000000", frameRate="60", quality="LOW")]
	
	public class Advanced_TerrainDemo extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf:Class;

		// Environment map.
		[Embed(source="/../embeds/skybox/snow_positive_x.jpg")]
		private var EnvPosX:Class;
		[Embed(source="/../embeds/skybox/snow_positive_y.jpg")]
		private var EnvPosY:Class;
		[Embed(source="/../embeds/skybox/snow_positive_z.jpg")]
		private var EnvPosZ:Class;
		[Embed(source="/../embeds/skybox/snow_negative_x.jpg")]
		private var EnvNegX:Class;
		[Embed(source="/../embeds/skybox/snow_negative_y.jpg")]
		private var EnvNegY:Class;
		[Embed(source="/../embeds/skybox/snow_negative_z.jpg")]
		private var EnvNegZ:Class;
		
		//water normal map
		[Embed(source="/../embeds/w_normalmap.jpg")]
		private var WaterNormals : Class;
		
		[Embed(source="/../embeds/terrain/Heightmap.jpg")]
		private var HeightMap : Class;

		[Embed(source="/../embeds/terrain/terrain_tex.jpg")]
		private var Albedo : Class;

		[Embed(source="/../embeds/terrain/terrain_norms.jpg")]
		private var Normals : Class;

		[Embed(source="/../embeds/terrain/grass.jpg")]
		private var Grass : Class;

		[Embed(source="/../embeds/terrain/rock.jpg")]
		private var Rock : Class;

		[Embed(source="/../embeds/terrain/beach.jpg")]
		private var Beach : Class;

		[Embed(source="/../embeds/terrain/terrainBlend.png")]
		private var Blend : Class;
		
		//engine variables
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var cameraController:FirstPersonController;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//light objects
		private var sunLight:DirectionalLight;
		private var lightPicker:StaticLightPicker;
		private var fogMethod:FogMethod;
		
		//material objects
		private var terrainMethod:TerrainDiffuseMethod;
		private var waterMethod:SimpleWaterNormalMethod;
		private var fresnelMethod:FresnelSpecularMethod;
		private var terrainMaterial:TextureMaterial;
		private var waterMaterial:TextureMaterial;
		private var cubeTexture:BitmapCubeTexture;
		
		//scene objects
		private var _terrain : Elevation;
		private var _plane:Mesh;
		private var _stickToFloor : Boolean = true;
		private var _motionBlur : MotionBlurFilter3D;

		private var _prevX : Number = 0;
		private var _prevY : Number = 0;
		private var _strength : Number = 0;
		
		//rotation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		
		//movement variables
		private var drag:Number = 0.5;
		private var walkIncrement:Number = 2;
		private var strafeIncrement:Number = 2;
		private var walkSpeed:Number = 0;
		private var strafeSpeed:Number = 0;
		private var walkAcceleration:Number = 0;
		private var strafeAcceleration:Number = 0;
		
		/**
		 * Constructor
		 */
		public function Advanced_TerrainDemo()
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
			
			camera.lens.far = 14000;
			camera.lens.near = .05;
			camera.y = 300;
			
			_motionBlur = new MotionBlurFilter3D();
			//view.filters3d = [ new BloomFilter3D(40, 40, .75, 1, 3) ];
			//view.filters3d = [ new DepthOfFieldFilter3D(10, 10) ];
			view.antiAlias = 4;
			
			//setup controller to be used on the camera
			cameraController = new FirstPersonController(camera, 180, 0, -80, 80);
			
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
		
		/**
		 * Initialise the lights
		 */
		private function initLights():void
		{
			sunLight = new DirectionalLight(-300, -300, -5000);
			sunLight.color = 0xfffdc5;
			sunLight.ambient = 1;
			scene.addChild(sunLight);
			
			lightPicker = new StaticLightPicker([sunLight]);
			
			//create a global fog method
			fogMethod = new FogMethod(4000, 0xcfd9de);
		}
		
		/**
		 * Initialise the material
		 */
		private function initMaterials():void
		{
			cubeTexture = new BitmapCubeTexture(new EnvPosX().bitmapData, new EnvNegX().bitmapData, new EnvPosY().bitmapData, new EnvNegY().bitmapData, new EnvPosZ().bitmapData, new EnvNegZ().bitmapData);

			terrainMethod = new TerrainDiffuseMethod([new BitmapTexture(new Beach().bitmapData), new BitmapTexture(new Grass().bitmapData), new BitmapTexture(new Rock().bitmapData)], new BitmapTexture(new Blend().bitmapData) , [1, 50, 150, 100]);

			terrainMaterial = new TextureMaterial(new BitmapTexture(new Albedo().bitmapData));
			terrainMaterial.diffuseMethod = terrainMethod;
			terrainMaterial.normalMap = new BitmapTexture(new Normals().bitmapData);
			terrainMaterial.lightPicker = lightPicker;
			terrainMaterial.ambientColor = 0x303040;
			terrainMaterial.ambient = 1;
			terrainMaterial.specular = .2;
			terrainMaterial.addMethod(fogMethod);
			
			waterMethod = new SimpleWaterNormalMethod(new BitmapTexture(new WaterNormals().bitmapData), new BitmapTexture(new WaterNormals().bitmapData));
			fresnelMethod = new FresnelSpecularMethod();
			fresnelMethod.normalReflectance = .3;
			
			waterMaterial = new TextureMaterial(new BitmapTexture(new BitmapData(512, 512, true, 0xaa404070)));
			waterMaterial.alphaBlending = true;
			waterMaterial.lightPicker = lightPicker;
			waterMaterial.repeat = true;
			waterMaterial.normalMethod = waterMethod;
			waterMaterial.addMethod(new EnvMapMethod(cubeTexture));
			waterMaterial.specularMethod = fresnelMethod;
			waterMaterial.gloss = 100;
			waterMaterial.specular = 1;
		}

		
		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			//create skybox.
			scene.addChild(new SkyBox(cubeTexture));
			
			//create mountain like terrain
			_terrain = new Elevation(terrainMaterial, new HeightMap().bitmapData, 5000, 1300, 5000, 250, 250);
			scene.addChild(_terrain);
			
			//create water
			_plane = new Mesh(new PlaneGeometry(5000, 5000), waterMaterial);
			_plane.geometry.scaleUV(50, 50);
			_plane.y = 285;
			scene.addChild(_plane);
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
			var mx : Number = mouseX, my : Number = mouseY;
			var dx : Number = mx - _prevX, dy : Number = my - _prevY;
			var dist : Number = .4 + (dx * dx + dy * dy) / 300;
			if (dist > .9) dist = .9;
			_strength += (dist - _strength) * .05;
			//			_motionBlur.strength = _strength;
			_prevX = mx;
			_prevY = my;
			
			var h : Number = _terrain.getHeightAt(view.camera.x, view.camera.z) + 20;
			if (_stickToFloor || h > view.camera.y) view.camera.y += (h - view.camera.y) * .2;
			
			if (move) {
				cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
				
			}
			
			if (walkSpeed || walkAcceleration) {
				walkSpeed = (walkSpeed + walkAcceleration)*drag;
				if (Math.abs(walkSpeed) < 0.01)
					walkSpeed = 0;
				cameraController.incrementWalk(walkSpeed);
			}
			
			if (strafeSpeed || strafeAcceleration) {
				strafeSpeed = (strafeSpeed + strafeAcceleration)*drag;
				if (Math.abs(strafeSpeed) < 0.01)
					strafeSpeed = 0;
				cameraController.incrementStrafe(strafeSpeed);
			}
			
			waterMethod.water1OffsetX += .001;
			waterMethod.water1OffsetY += .001;
			waterMethod.water2OffsetX += .0007;
			waterMethod.water2OffsetY += .0006;
			
			view.render();
		}
		
		/**
		 * Key down listener for camera control
		 */
		private function onKeyDown(event : KeyboardEvent) : void
		{
			switch (event.keyCode) {
				case Keyboard.UP:
				case Keyboard.W:
					walkAcceleration = walkIncrement;
					break;
				case Keyboard.DOWN:
				case Keyboard.S:
					walkAcceleration = -walkIncrement;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
					strafeAcceleration = -strafeIncrement;
					break;
				case Keyboard.RIGHT:
				case Keyboard.D:
					strafeAcceleration = strafeIncrement;
					break;
			}
		}
		
		/**
		 * Key up listener for camera control
		 */
		private function onKeyUp(event : KeyboardEvent) : void
		{
			switch (event.keyCode) {
				case Keyboard.UP:
				case Keyboard.W:
				case Keyboard.DOWN:
				case Keyboard.S:
					walkAcceleration = 0;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
				case Keyboard.RIGHT:
				case Keyboard.D:
					strafeAcceleration = 0;
					break;
				case Keyboard.SPACE:
					_stickToFloor = !_stickToFloor;
					
					break;
			}
		}
		
		/**
		 * Mouse down listener for navigation
		 */
		private function onMouseDown(event:MouseEvent):void
		{
			move = true;
			lastPanAngle = cameraController.panAngle;
			lastTiltAngle = cameraController.tiltAngle;
			lastMouseX = stage.mouseX;
			lastMouseY = stage.mouseY;
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