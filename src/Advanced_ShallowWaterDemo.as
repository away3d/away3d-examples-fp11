package
{
	import away3d.cameras.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.core.math.Matrix3DUtils;
	import away3d.debug.*;
	import away3d.entities.*;
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
	import flash.utils.*;
	
	import shallowwater.*;
	
	import uk.co.soulwire.gui.*;

	
	[SWF(backgroundColor="#000000", frameRate="60", quality="LOW")]
	
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
		private var cameraController:HoverController;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//light objects
		private var skyLight:PointLight;
		private var lightPicker:StaticLightPicker;
		private var fogMethod:FogMethod;
		
		//material objects
		private var poolMaterial:TextureMaterial;
		private var cubeTexture:BitmapCubeTexture;
		
		//fluid simulation variables
		private var gridDimension:uint = 200;
		private var gridSpacing:uint = 2;
		
		public var mouseBrushStrength : Number = 5;
		public var rainBrushStrength : Number = 10;
		public var mouseBrushLife : uint = 0;
		
		//scene objects
		public var fluid : ShallowFluid;
		private var _plane : Mesh;
		private var _pressing : Boolean;
		private var _dropTmr : Timer;
		private var _fluidDisturb : FluidDisturb;
		public var brushClip1 : Sprite;
		public var brushClip2 : Sprite;
		public var brushClip3 : Sprite;
		public var brushClip4 : Sprite;
		public var brushClip5 : Sprite;
		public var brushClip6 : Sprite;
		public var brushClips : Array;
		private var _activeMouseBrushClip : Sprite;
		private var _rainBrush : DisturbanceBrush;
		private var _imageBrush : DisturbanceBrush;
		private var _mouseBrush : DisturbanceBrush;
		private var _liquidShading : Boolean = true;
		private var _showingLiquidImage : Boolean;
		private var _showingLiquidImage1 : Boolean;
		private var _showingLiquidImage2 : Boolean;
		private var _gui : SimpleGUI;
		private var _rain : Boolean;
		private var _inverse : Matrix3D = new Matrix3D();
		private var _projX : Number, _projY : Number;
		public var hx : Number, hy : Number, hz : Number;
		private var _min : Number;
		private var _max : Number;
		private var _colorMaterial : ColorMaterial;
		private var _liquidMaterial : ColorMaterial;
		
		//navigation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		
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
			cameraController = new HoverController(camera, null, 45, 20, 320, 5);
			
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
			skyLight = new PointLight();
			skyLight.color = 0x0000FF;
			skyLight.specular = 0.5;
			skyLight.diffuse = 2;
			scene.addChild(skyLight);
			
			lightPicker = new StaticLightPicker([skyLight]);
			
			//create a global fog method
			fogMethod = new FogMethod(2500, 0x000000);
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
			var planeSize:Number = planeSegments*gridSpacing;
			_plane = new Mesh(new PlaneGeometry(planeSize, planeSize, planeSegments, planeSegments), _liquidMaterial);
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
			var dt : Number = 1 / stage.frameRate;
			var viscosity : Number = 0.3;
			var waveVelocity : Number = 0.99; // < 1 or the sim will collapse.
			fluid = new ShallowFluid(gridDimension, gridDimension, gridSpacing, dt, waveVelocity, viscosity);

			// Disturbance util.
			_fluidDisturb = new FluidDisturb(fluid);

			// Init brush clips.
			brushClip1 = new Brush1() as Sprite;
			brushClip2 = new Brush2() as Sprite;
			brushClip3 = new Brush3() as Sprite;
			brushClip4 = new Brush4() as Sprite;
			brushClip5 = new Brush5() as Sprite;
			brushClip6 = new Brush6() as Sprite;
			brushClips = [
				{label:"drop", data:brushClip3},
				{label:"star", data:brushClip1},
				{label:"box", data:brushClip2},
				{label:"triangle", data:brushClip4},
				{label:"stamp", data:brushClip5},
				{label:"butter", data:brushClip6}
			];
			_activeMouseBrushClip = brushClip3;

			// Init brushes.
			_rainBrush = new DisturbanceBrush();
			_rainBrush.fromSprite(brushClip3);
			_mouseBrush = new DisturbanceBrush();
			_mouseBrush.fromSprite(_activeMouseBrushClip);
			_imageBrush = new DisturbanceBrush();
			_imageBrush.fromSprite(new ImageClip() as Sprite);

			// Rain.
			_dropTmr = new Timer(50);
			_dropTmr.addEventListener(TimerEvent.TIMER, _dropTmr_timerHandler);

			// Start loop.
			//addEventListener(Event.ENTER_FRAME, enterFrameHandler);

			// Stage clicks.
			//stage.addEventListener(MouseEvent.MOUSE_DOWN, stage_mouseDownHandler);
			//stage.addEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler);
		}
		
		/**
		 * Initialise the GUI
		 */
		private function initGUI() : void
		{
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
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		/**
		 * Navigation and render loop
		 */
		private function onEnterFrame(event:Event):void
		{
			if (move) {
				cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
			}
			
			// Update light.
			skyLight.transform = camera.transform.clone();
			
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

		// ---------------
		// MOUSE.
		// ---------------
/*
		private function stage_mouseDownHandler(event : MouseEvent) : void
		{
			_pressing = true;

			updateMouse();

			if (hx > _min && hx < _max && hz > _min && hz < _max)
				_cameraController.mouseInteractionEnabled = false;
			else
				_pressing = false;
		}

		private function stage_mouseUpHandler(event : MouseEvent) : void
		{
			_pressing = false;
			_cameraController.mouseInteractionEnabled = true;
		}
*/
		/*
		 Decided not to use built in mouse interactivity.
		 Using this chunk of code I stole from the engine instead.
		private function updateMouse() : void
		{
			_projX = 1 - 2 * stage.mouseX / stage.stageWidth;
			_projY = 2 * stage.mouseY / stage.stageHeight - 1;

			// calculate screen ray and find exact intersection position with triangle
			var rx : Number, ry : Number, rz : Number;
			var ox : Number, oy : Number, oz : Number, ow : Number;
			var t : Number;
			var raw : Vector.<Number>;

			_inverse.copyFrom(_view.camera.lens.matrix);
			_inverse.invert();
			raw = Matrix3DUtils.RAW_DATA_CONTAINER;
			_inverse.copyRawDataTo(raw);

			// unproject projection point, gives ray dir in cam space
			ox = raw[0] * _projX + raw[4] * _projY + raw[12];
			oy = raw[1] * _projX + raw[5] * _projY + raw[13];
			oz = raw[2] * _projX + raw[6] * _projY + raw[14];
			ow = raw[3] * _projX + raw[7] * _projY + raw[15];
			ox /= -ow;
			oy /= -ow;
			oz /= ow;

			// transform ray dir and origin (cam pos) to object space
			_inverse.copyFrom(_view.camera.sceneTransform);
			_inverse.copyRawDataTo(raw);
			rx = raw[0] * ox + raw[4] * oy + raw[8] * oz;
			ry = raw[1] * ox + raw[5] * oy + raw[9] * oz;
			rz = raw[2] * ox + raw[6] * oy + raw[10] * oz;

			ox = raw[12];
			oy = raw[13];
			oz = raw[14];

			t = -oy / ry;

			hx = ox + rx * t;
			hy = oy + ry * t;
			hz = oz + rz * t;

			if (hx > _min && hx < _max && hz > _min && hz < _max) {
				// Disturb mouse.
				var evtx : Number = 0.5 * (hx + _max) / _max;
				var evty : Number = 0.5 * (hz + _max) / _max;
				if (mouseBrushLife == 0)
					_fluidDisturb.disturbBitmapInstant(evtx, evty, -mouseBrushStrength, _mouseBrush.bitmapData);
				else
					_fluidDisturb.disturbBitmapMemory(evtx, evty,
							-5 * mouseBrushStrength,
							_mouseBrush.bitmapData,
							mouseBrushLife,
							0.2);
			}
		}
		 */

		// ---------------
		// LOOP.
		// ---------------
/*
		private function enterFrameHandler(event : Event) : void
		{
			// Update camera.
			_cameraController.update();

			// Update fluid.
			fluid.evaluate();

			// Update memory disturbances.
			_fluidDisturb.updateMemoryDisturbances();

			// Update plane to fluid.
			_plane.geometry.subGeometries[0].updateVertexData(fluid.points);
			_plane.geometry.subGeometries[0].updateVertexNormalData(fluid.normals);
			_plane.geometry.subGeometries[0].updateVertexTangentData(fluid.tangents);

			// Update light.
			_light.transform = _view.camera.transform.clone();

			// Render.
			_view.render();

			if (_pressing)
				updateMouse();
		}
*/
		// ---------------
		// UTILS.
		// ---------------

		private function randNum(min : Number, max : Number) : Number
		{
			return (max - min) * Math.random() + min;
		}

		private function clampNum(value : Number, min : Number, max : Number) : Number
		{
			if (value < min)
				return min;
			else if (value > max)
				return max;
			else
				return value;
		}
	}
}
