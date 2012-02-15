package
{

	import away3d.cameras.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.core.raytracing.picking.MouseHitMethod;
	import away3d.debug.*;
	import away3d.entities.*;
	import away3d.events.MouseEvent3D;
	import away3d.lights.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.*;
	import away3d.materials.methods.*;
	import away3d.primitives.*;
	import away3d.textures.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.ui.Keyboard;
	import flash.utils.*;
	
	import shallowwater.*;
	
	import uk.co.soulwire.gui.*;

	
	[SWF(backgroundColor="#000000", frameRate="30", quality="LOW")]
	
	public class Advanced_ShallowWaterDemo extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf:Class;
		
		// Environment map.
		[Embed(source="../embeds/skybox/snow_positive_x.jpg")]
		private var EnvPosX : Class;
		[Embed(source="../embeds/skybox/snow_positive_y.jpg")]
		private var EnvPosY : Class;
		[Embed(source="../embeds/skybox/snow_positive_z.jpg")]
		private var EnvPosZ : Class;
		[Embed(source="../embeds/skybox/snow_negative_x.jpg")]
		private var EnvNegX : Class;
		[Embed(source="../embeds/skybox/snow_negative_y.jpg")]
		private var EnvNegY : Class;
		[Embed(source="../embeds/skybox/snow_negative_z.jpg")]
		private var EnvNegZ : Class;

		// Liquid image assets.
		[Embed(source="../embeds/assets.swf", symbol="ImageClip")]
		private var ImageClip : Class;
		[Embed(source="../embeds/assets.swf", symbol="ImageClip1")]
		private var ImageClip1 : Class;
		[Embed(source="../embeds/assets.swf", symbol="ImageClip2")]
		private var ImageClip2 : Class;

		// Disturbance brushes.
		[Embed(source="../embeds/assets.swf", symbol="Brush1")]
		private var Brush1 : Class;
		[Embed(source="../embeds/assets.swf", symbol="Brush2")]
		private var Brush2 : Class;
		[Embed(source="../embeds/assets.swf", symbol="Brush3")]
		private var Brush3 : Class;
		[Embed(source="../embeds/assets.swf", symbol="Brush4")]
		private var Brush4 : Class;
		[Embed(source="../embeds/assets.swf", symbol="Brush5")]
		private var Brush5 : Class;
		[Embed(source="../embeds/assets.swf", symbol="Brush6")]
		private var Brush6 : Class;
		
		//engine variables
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var awayStats:AwayStats;
		private var cameraController:HoverController;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//light objects
		private var skyLight:PointLight;
		private var lightPicker:StaticLightPicker;
		private var fogMethod:FogMethod;
		
		//material objects
		private var _colorMaterial : ColorMaterial;
		private var _liquidMaterial : ColorMaterial;
		private var poolMaterial:TextureMaterial;
		private var cubeTexture:BitmapCubeTexture;
		
		//fluid simulation variables
		private var gridDimension:uint = 200;
		private var gridSpacing:uint = 2;
		private var planeSize:Number;
		
		
		//scene objects
		public var fluid:ShallowFluid;
		private var _plane:Mesh;
		private var _fluidDisturb:FluidDisturb;
		private var _gui:SimpleGUI;
		
		//gui variables
		public var mouseBrushStrength:Number = 5;
		public var rainBrushStrength:Number = 10;
		public var mouseBrushLife:uint = 0;
		private var _rainBrush:DisturbanceBrush;
		private var _imageBrush:DisturbanceBrush;
		private var _mouseBrush:DisturbanceBrush;
		private var _showingLiquidImage:Boolean;
		private var _showingLiquidImage1:Boolean;
		private var _showingLiquidImage2:Boolean;
		private var _activeMouseBrushClip:Sprite;
		
		
		//interaction variables
		private var _dropTmr:Timer;
		private var _rain : Boolean;
		private var _liquidShading : Boolean = true;
		private var planeDisturb:Boolean = false;
		private var planeX:Number;
		private var planeY:Number;
		
		//navigation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		private var tiltSpeed:Number = 2;
		private var panSpeed:Number = 2;
		private var distanceSpeed:Number = 2;
		private var tiltIncrement:Number = 0;
		private var panIncrement:Number = 0;
		private var distanceIncrement:Number = 0;
		
		/**
		 * Constructor
		 */
		public function Advanced_ShallowWaterDemo()
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
			initFluid();
			initGUI();
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
			
			//setup controller to be used on the camera
			cameraController = new HoverController(camera, null, 180, 20, 320, 5);
			
			//view.addSourceURL("srcview/index.html");
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
		 * Initialise the lights
		 */
		private function initLights():void
		{
			skyLight = new PointLight();
			skyLight.color = 0x0000FF;
			skyLight.specular = 0.5;
			skyLight.diffuse = 2;
			scene.addChild(skyLight);
			
			lightPicker = new StaticLightPicker([skyLight]);
			
			//create a global fog method
			fogMethod = new FogMethod(0, 2500, 0x000000);
		}
		
		/**
		 * Initialise the material
		 */
		private function initMaterials():void
		{
			cubeTexture = new BitmapCubeTexture(new EnvPosX().bitmapData, new EnvNegX().bitmapData, new EnvPosY().bitmapData, new EnvNegY().bitmapData, new EnvPosZ().bitmapData, new EnvNegZ().bitmapData);
			
			_liquidMaterial = new ColorMaterial(0xFFFFFF);
			_liquidMaterial.specular = 0.5;
			_liquidMaterial.ambient = 0.25;
			_liquidMaterial.ambientColor = 0x111199;
			_liquidMaterial.ambient = 1;
			_liquidMaterial.addMethod(new EnvMapMethod(cubeTexture, 1));
			_liquidMaterial.lightPicker = lightPicker;
			
			_colorMaterial = new ColorMaterial(_liquidMaterial.color);
			_colorMaterial.specular = 0.5;
			_colorMaterial.ambient = 0.25;
			_colorMaterial.ambientColor = 0x555555;
			_colorMaterial.ambient = 1;
			_colorMaterial.diffuseMethod = new BasicDiffuseMethod();
			_colorMaterial.lightPicker = lightPicker;
			
			var tex : BitmapData = new BitmapData(512, 512, false, 0);
			tex.perlinNoise(25, 25, 8, 1, false, true, 7, true);
			tex.colorTransform(tex.rect, new ColorTransform(0.1, 0.1, 0.1, 1, 0, 0, 0, 0));
			poolMaterial = new TextureMaterial(new BitmapTexture(tex));
			poolMaterial.addMethod(fogMethod);
			
		}
		
		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{		
			//create skybox.
			scene.addChild(new SkyBox(cubeTexture));

			//create water plane.
			var planeSegments:uint = (gridDimension - 1);
			planeSize = planeSegments*gridSpacing;
			_plane = new Mesh(new PlaneGeometry(planeSize, planeSize, planeSegments, planeSegments), _liquidMaterial);
			_plane.rotationX = 90;
			_plane.x -= planeSize/2;
			_plane.z -= planeSize/2;
			_plane.mouseEnabled = true;
			_plane.mouseHitMethod = MouseHitMethod.BOUNDS_ONLY;
			_plane.geometry.subGeometries[0].autoDeriveVertexNormals = false;
			_plane.geometry.subGeometries[0].autoDeriveVertexTangents = false;
			scene.addChild(_plane);

			//create pool
			var poolHeight:Number = 500000;
			var poolThickness:Number = 5;
			var poolVOffset:Number = 5 - poolHeight/2;
			var poolHOffset:Number = planeSize/2 + poolThickness/2;
			
			var left:Mesh = new Mesh(new CubeGeometry(poolThickness, poolHeight, planeSize + poolThickness*2), poolMaterial);
			left.x = -poolHOffset;
			left.y = poolVOffset;
			scene.addChild(left);
			
			var right:Mesh = new Mesh(new CubeGeometry(poolThickness, poolHeight, planeSize + poolThickness*2), poolMaterial);
			right.x = poolHOffset;
			right.y = poolVOffset;
			scene.addChild(right);
			
			var back:Mesh = new Mesh(new CubeGeometry(planeSize, poolHeight, poolThickness), poolMaterial);
			back.z = poolHOffset;
			back.y = poolVOffset;
			scene.addChild(back);
			
			var front:Mesh = new Mesh(new CubeGeometry(planeSize, poolHeight, poolThickness), poolMaterial);
			front.z = -poolHOffset;
			front.y = poolVOffset;
			scene.addChild(front);
		}
		
		/**
		 * Initialise the fluid
		 */
		private function initFluid():void
		{		
			// Fluid.
			var dt:Number = 1 / stage.frameRate;
			var viscosity:Number = 0.3;
			var waveVelocity:Number = 0.99; // < 1 or the sim will collapse.
			fluid = new ShallowFluid(gridDimension, gridDimension, gridSpacing, dt, waveVelocity, viscosity);

			// Disturbance util.
			_fluidDisturb = new FluidDisturb(fluid);

		}
		
		/**
		 * Initialise the GUI
		 */
		private function initGUI() : void
		{
			// Init brush clips.
			var drop:Sprite = new Brush3() as Sprite;
			
			var brushClips:Array = [
				{label:"drop", data:drop},
				{label:"star", data:new Brush1()},
				{label:"box", data:new Brush2()},
				{label:"triangle", data:new Brush4()},
				{label:"stamp", data:new Brush5()},
				{label:"butter", data:new Brush6()}
			];
			
			_activeMouseBrushClip = drop;

			// Init brushes.
			_rainBrush = new DisturbanceBrush();
			_rainBrush.fromSprite(drop);
			_mouseBrush = new DisturbanceBrush();
			_mouseBrush.fromSprite(_activeMouseBrushClip);
			_imageBrush = new DisturbanceBrush();
			_imageBrush.fromSprite(new ImageClip() as Sprite);

			// Rain.
			_dropTmr = new Timer(50);
			_dropTmr.addEventListener(TimerEvent.TIMER, _dropTmr_timerHandler);
			
			_gui = new SimpleGUI(this, "");

			_gui.addColumn("Simulation");
			_gui.addSlider("fluid.speed", 0.0, 0.95, {label:"speed", tick:0.01});
			_gui.addSlider("fluid.viscosity", 0.0, 1.7, {label:"viscosity", tick:0.01});
			_gui.addToggle("toggleShading", {label:"reflective shading"});

			var instr : String = "Instructions:\n";
			instr += "Click and drag on the stage to rotate camera.\n";
			instr += "Click on the fluid to disturb it.\n";
			instr += "Keyboard arrows and WASD also rotate camera.\n";
			instr += "Keyboard Z and X zoom camera.\n";
			_gui.addLabel(instr);

			_gui.addColumn("Rain");
			_gui.addToggle("toggleRain", {label:"enabled"});
			_gui.addSlider("rainTime", 10, 1000, {label:"speed", tick:10});
			_gui.addSlider("rainBrushStrength", 1, 50, {label:"strength", tick:0.01});

			_gui.addColumn("Mouse Brush");
			_gui.addComboBox("activeMouseBrushClip", brushClips, {label:"brush"});
			_gui.addSlider("mouseBrushStrength", -10, 10, {label:"strength", tick:0.01});
			_gui.addSlider("mouseBrushLife", 0, 10000, {label:"life", tick:10});

			_gui.addColumn("Liquid Image");
			_gui.addToggle("toggleLiquidImage", {label:"away"});
			_gui.addToggle("toggleLiquidImage2", {label:"mustang"});
			_gui.addToggle("toggleLiquidImage1", {label:"winston"});
			_gui.show();
		}
		
		/**
		 * Initialise the listeners
		 */
		private function initListeners():void
		{
			_plane.addEventListener(MouseEvent3D.MOUSE_MOVE, onPlaneMouseMove);
			_plane.addEventListener(MouseEvent3D.MOUSE_DOWN, onPlaneMouseDown);
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(Event.RESIZE, onResize);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			onResize();
		}
		
		private function updatePlaneCoords(x:Number, y:Number):void
		{
			planeX = x/planeSize;
			planeY = y/planeSize;
		}
		
		/**
		 * Navigation and render loop
		 */
		private function onEnterFrame(event:Event):void
		{
			// Update fluid.
			fluid.evaluate();

			// Update memory disturbances.
			_fluidDisturb.updateMemoryDisturbances();

			// Update plane to fluid.
			_plane.geometry.subGeometries[0].updateVertexData(fluid.points);
			_plane.geometry.subGeometries[0].updateVertexNormalData(fluid.normals);
			_plane.geometry.subGeometries[0].updateVertexTangentData(fluid.tangents);

			
			if (planeDisturb) {
				if (mouseBrushLife == 0)
					_fluidDisturb.disturbBitmapInstant(planeX, planeY, -mouseBrushStrength, _mouseBrush.bitmapData);
				else
					_fluidDisturb.disturbBitmapMemory(planeX, planeY, -5*mouseBrushStrength, _mouseBrush.bitmapData, mouseBrushLife, 0.2);
			} else if (move) {
				cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
			}
			
			cameraController.panAngle += panIncrement;
			cameraController.tiltAngle += tiltIncrement;
			cameraController.distance += distanceIncrement;
			
			// Update light.
			skyLight.transform = camera.transform.clone();
			
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
					tiltIncrement = tiltSpeed;
					break;
				case Keyboard.DOWN:
				case Keyboard.S:
					tiltIncrement = -tiltSpeed;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
					panIncrement = panSpeed;
					break;
				case Keyboard.RIGHT:
				case Keyboard.D:
					panIncrement = -panSpeed;
					break;
				case Keyboard.Z:
					distanceIncrement = distanceSpeed;
					break;
				case Keyboard.X:
					distanceIncrement = -distanceSpeed;
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
					tiltIncrement = 0;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
				case Keyboard.RIGHT:
				case Keyboard.D:
					panIncrement = 0;
					break;
				case Keyboard.Z:
				case Keyboard.X:
					distanceIncrement = 0;
					break;
			}
		}
		
		/**
		 * mesh listener for fluid interaction with the mouse
		 */
		private function onPlaneMouseMove(event:MouseEvent3D):void
		{
			if (planeDisturb)
				updatePlaneCoords(event.localX, event.localY);
		}
		
		/**
		 * mesh listener for fluid interaction with the mouse
		 */
		private function onPlaneMouseDown(event:MouseEvent3D):void
		{
				planeDisturb = true;
				updatePlaneCoords(event.localX, event.localY);
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
			planeDisturb = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * Mouse stage leave listener for navigation
		 */
		private function onStageMouseLeave(event:Event):void
		{
			move = false;
			planeDisturb = false;
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
			awayStats.x = stage.stageWidth - awayStats.width;
		}
		
		public function set activeMouseBrushClip(value : Sprite) : void
		{
			_activeMouseBrushClip = value;
			_mouseBrush.fromSprite(_activeMouseBrushClip, 2);
		}

		public function get activeMouseBrushClip() : Sprite
		{
			return _activeMouseBrushClip;
		}

		public function set rainTime(delay : uint) : void
		{
			_dropTmr.delay = delay;
		}

		public function get rainTime() : uint
		{
			return _dropTmr.delay;
		}

		// ---------------
		// MATERIALS.
		// ---------------

		public function set toggleShading(value : Boolean) : void
		{
			_liquidShading = value;
			if (_liquidShading)
				_plane.material = _liquidMaterial;
			else
				_plane.material = _colorMaterial;
		}

		public function get toggleShading() : Boolean
		{
			return _liquidShading;
		}

		// ---------------
		// LIQUID IMAGE.
		// ---------------

		public function set toggleLiquidImage(value : Boolean) : void
		{
			_showingLiquidImage = value;
			if (_showingLiquidImage) {
				_imageBrush.fromSprite(new ImageClip() as Sprite);
				_fluidDisturb.disturbBitmapMemory(0.5, 0.5, -10, _imageBrush.bitmapData, -1, 0.01);
			}
			else
				_fluidDisturb.releaseMemoryDisturbances();
		}

		public function get toggleLiquidImage() : Boolean
		{
			return _showingLiquidImage;
		}

		public function set toggleLiquidImage1(value : Boolean) : void
		{
			_showingLiquidImage1 = value;
			if (_showingLiquidImage1) {
				_imageBrush.fromSprite(new ImageClip1() as Sprite);
				_fluidDisturb.disturbBitmapMemory(0.5, 0.5, -15, _imageBrush.bitmapData, -1, 0.01);
			}
			else
				_fluidDisturb.releaseMemoryDisturbances();
		}

		public function get toggleLiquidImage1() : Boolean
		{
			return _showingLiquidImage1;
		}

		public function set toggleLiquidImage2(value : Boolean) : void
		{
			_showingLiquidImage2 = value;
			if (_showingLiquidImage2) {
				_imageBrush.fromSprite(new ImageClip2() as Sprite);
				_fluidDisturb.disturbBitmapMemory(0.5, 0.5, -15, _imageBrush.bitmapData, -1, 0.01);
			}
			else
				_fluidDisturb.releaseMemoryDisturbances();
		}

		public function get toggleLiquidImage2() : Boolean
		{
			return _showingLiquidImage2;
		}

		// ---------------
		// RAIN.
		// ---------------

		public function set toggleRain(value : Boolean) : void
		{
			_rain = value;
			if (_rain)
				_dropTmr.start();
			else
				_dropTmr.stop();
		}

		public function get toggleRain() : Boolean
		{
			return _rain;
		}

		private function _dropTmr_timerHandler(event : TimerEvent) : void
		{
			_fluidDisturb.disturbBitmapInstant(randNum(0.1, 0.9), randNum(0.1, 0.9), rainBrushStrength, _rainBrush.bitmapData);
		}

		private function randNum(min : Number, max : Number) : Number
		{
			return (max - min) * Math.random() + min;
		}
	}
}
