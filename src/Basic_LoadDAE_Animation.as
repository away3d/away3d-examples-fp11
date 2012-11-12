package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	
	import away3d.animators.SkeletonAnimationSet;
	import away3d.animators.SkeletonAnimator;
	import away3d.animators.data.Skeleton;
	import away3d.animators.nodes.SkeletonClipNode;
	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.core.pick.PickingType;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.entities.SegmentSet;
	import away3d.events.AssetEvent;
	import away3d.events.LoaderEvent;
	import away3d.library.AssetLibrary;
	import away3d.library.assets.AssetType;
	import away3d.lights.DirectionalLight;
	import away3d.loaders.Loader3D;
	import away3d.loaders.misc.AssetLoaderContext;
	import away3d.loaders.parsers.DAEParser;
	import away3d.materials.TextureMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.methods.FilteredShadowMapMethod;
	import away3d.primitives.PlaneGeometry;
	import away3d.primitives.WireframeSphere;
	import away3d.utils.Cast;

	[SWF(backgroundColor = "#000000", width = "600", height = "400", frameRate = "60")]
	public class Basic_LoadDAE_Animation extends Sprite
	{
		//[Embed(source = "/../embeds/collada/a_box_smooth_translate.dae", mimeType = "application/octet-stream")]
		//[Embed(source = "/../embeds/collada/c_astroboy_maya.dae", mimeType = "application/octet-stream")]
		[Embed(source = "/../embeds/collada/b_mario_testrun.dae", mimeType = "application/octet-stream")]
		public static var _dae_clazz:Class;

		// tableTexture
		[Embed(source = "/../embeds/floor_diffuse.jpg")]
		private var tableTex:Class;

		//signature swf
		[Embed(source = "/../embeds/signature.swf", symbol = "Signature")]
		public var SignatureSwf:Class;

		//engine variables
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var awayStats:AwayStats;
		private var cameraController:HoverController;

		//signature variables
		private var Signature:Sprite;
		private var _signature:Bitmap;
		private var SignatureBitmap:Bitmap;

		//light objects
		private var light:DirectionalLight;
		private var lightPicker:StaticLightPicker;
		private var direction:Vector3D;

		//navigation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		private var tiltSpeed:Number = 4;
		private var panSpeed:Number = 4;
		private var distanceSpeed:Number = 4;
		private var tiltIncrement:Number = 0;
		private var panIncrement:Number = 0;
		private var distanceIncrement:Number = 0;

		private var char:ObjectContainer3D;

		//animation variables
		private var _mesh:Mesh;
		private var _animator:SkeletonAnimator;
		private var _animationSet:SkeletonAnimationSet;
		private var _skeleton:Skeleton;

		//debug variables
		private var _debugSegmentSets:Vector.<SegmentSet> = new Vector.<SegmentSet>;

		/**
		 * Constructor
		 */
		public function Basic_LoadDAE_Animation()
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
			initListeners();

			initialize();
		}

		private function initialize():void
		{
			// create ground mesh
			var matground:TextureMaterial = new TextureMaterial(Cast.bitmapTexture(tableTex));
			matground.shadowMethod = new FilteredShadowMapMethod(light);
			matground.lightPicker = lightPicker;
			matground.ambient = 0.5;
			matground.specular = 0.5;
			var mesh:Mesh = new Mesh(new PlaneGeometry(5000, 5000), matground);
			mesh.mouseEnabled = true;
			view.scene.addChild(mesh);
			
			//debug purpose
			DAEParser.IS_DEBUG = true;

			//Parsers.enableAllBundled();
			var context:AssetLoaderContext = new AssetLoaderContext();
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, loaded, false, 0, true);
			var loader:Loader3D = new Loader3D();
			loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, complete, false, 0, true);
			loader.loadData(new _dae_clazz(), context, null, new DAEParser());
		}

		/**
		 * Initialise the engine
		 */
		private function initEngine():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;

			view = new View3D();
			view.forceMouseMove = true;
			scene = view.scene;
			camera = view.camera;
			//setup controller to be used on the camera
			cameraController = new HoverController(camera, null, 45, 20, 1000, -90);

			// Chose global picking method ( chose one ).
			view.mousePicker = PickingType.RAYCAST_BEST_HIT; // Uses the CPU, guarantees accuracy with a little performance cost.

			view.addSourceURL("srcview/index.html");
			addChild(view);

			//add signature
			Signature = Sprite(new SignatureSwf());
			SignatureBitmap = new Bitmap(new BitmapData(Signature.width, Signature.height, true, 0));
			stage.quality = StageQuality.HIGH;
			SignatureBitmap.bitmapData.draw(Signature);
			addChild(SignatureBitmap);

			awayStats = new AwayStats(view);
			addChild(awayStats);
		}

		/**
		 * Initialise the lights
		 */
		private function initLights():void
		{
			//setup the lights for the scene
			light = new DirectionalLight(1, -1, 1);
			light.ambient = 0.8;
			light.color = 0xffffff;

			lightPicker = new StaticLightPicker([light]);
			scene.addChild(light);
		}

		/**
		 * Initialise the listeners
		 */
		private function initListeners():void
		{
			view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}

		/**
		 * Navigation and render loop
		 */
		private function onEnterFrame(event:Event):void
		{
			// Update camera.
			if (move)
			{
				cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;

				cameraController.panAngle += panIncrement;
				cameraController.tiltAngle += tiltIncrement;
				cameraController.distance += distanceIncrement;
			}

			var _debugSegmentSet:SegmentSet;
			for (var i:int = 0; i < _debugSegmentSets.length; i++)
			{
				_debugSegmentSet = _debugSegmentSets[i];
				_debugSegmentSet.transform = _animator.globalPose.jointPoses[i].toMatrix3D();
			}

			// Render 3D.
			view.render();
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

		/**
		 * capture while load events
		 * @param event
		 */
		private function loaded(event:AssetEvent):void
		{
			switch (event.asset.assetType)
			{
				case AssetType.CONTAINER:
				{
					char = ObjectContainer3D(event.asset);
					char.scale(25);
					char.y = 250;
					break;
				}

				case AssetType.MATERIAL:
				{
					var material:TextureMaterial = TextureMaterial(event.asset);
					material.lightPicker = lightPicker;
					material.ambient = 1;
					break;
				}

				case AssetType.SKELETON:
				{
					_skeleton = event.asset as Skeleton;
					break;
				}

				case AssetType.ANIMATION_NODE:
				{
					var node:SkeletonClipNode = event.asset as SkeletonClipNode;
					var name:String = event.asset.assetNamespace;

					if (_animationSet)
						_animationSet.addAnimation(name, node);

					break;
				}

				case AssetType.ANIMATION_SET:
				{
					_animationSet = event.asset as SkeletonAnimationSet;
					_animator = new SkeletonAnimator(_animationSet, _skeleton);

					_mesh.animator = _animator;

					_animator.play("node_0");
					_animator.playbackSpeed = 1;

					break;
				}

				case AssetType.MESH:
				{
					_mesh = event.asset as Mesh;

					break;
				}

				default:
				{
					break;
				}
			}
		}

		/**
		 * capture complete event
		 * @param event
		 */
		private function complete(event:LoaderEvent):void
		{
			AssetLibrary.removeEventListener(AssetEvent.ASSET_COMPLETE, loaded);
			event.target.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, complete);

			scene.addChild(char);
		}

		/**
		 * Mouse up listener for navigation
		 */
		private function onMouseUp(event:MouseEvent):void
		{
			move = false;
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

			debugJoint();
		}

		//--------------------------------------------------------------------- DEBUG

		/**
		 * for debug purpose
		 */
		private function debugJoint():void
		{
			var _debugSegmentSet:SegmentSet;

			if (_debugSegmentSets.length > 0)
				return;
			
			if(!_animator)
				return;

			for (var i:int = 0; i < _animator.globalPose.jointPoses.length; i++)
			{
				_debugSegmentSet = new WireframeSphere(2, 4, 3);
				_debugSegmentSets.push(_mesh.addChild(_debugSegmentSet));
			}
		}
	}
}
