package
{
	import away3d.bounds.*;
	import away3d.cameras.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.core.base.*;
	import away3d.core.pick.*;
	import away3d.debug.*;
	import away3d.entities.*;
	import away3d.events.*;
	import away3d.library.assets.*;
	import away3d.lights.*;
	import away3d.loaders.parsers.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.*;
	import away3d.primitives.*;
	import away3d.textures.*;

	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.ui.*;
	
	[SWF(backgroundColor="#000000", frameRate="60")]
	public class Intermediate_MouseInteraction extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf:Class;
		
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
		private var pointLight:PointLight;
		private var lightPicker:StaticLightPicker;
		
		//material objects
		private var painter:Sprite;
		private var blackMaterial:ColorMaterial;
		private var whiteMaterial:ColorMaterial;
		private var grayMaterial:ColorMaterial;
		private var blueMaterial:ColorMaterial;
		private var redMaterial:ColorMaterial;

		//scene objects
		private var text:TextField;
		private var pickingPositionTracer:Mesh;
		private var pickingNormalTracer:SegmentSet;
		private var head:Mesh;
		private var cubeGeometry:CubeGeometry;
		private var sphereGeometry:SphereGeometry;
		private var cylinderGeometry:CylinderGeometry;
		private var torusGeometry:TorusGeometry;

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

		// Assets.
		[Embed(source="../embeds/head.obj", mimeType="application/octet-stream")]
		private var HeadAsset:Class;

		private const PAINT_TEXTURE_SIZE:uint = 1024;

		/**
		 * Constructor
		 */
		public function Intermediate_MouseInteraction()
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
			view.forceMouseMove = true;
			scene = view.scene;
			camera = view.camera;

			// Chose global picking method ( chose one ).
//			view.mousePicker = PickingType.SHADER; // Uses the GPU, considers gpu animations, and suffers from Stage3D's drawToBitmapData()'s bottleneck.
//			view.mousePicker = PickingType.RAYCAST_FIRST_ENCOUNTERED; // Uses the CPU, fast, but might be inaccurate with intersecting objects.
			view.mousePicker = PickingType.RAYCAST_BEST_HIT; // Uses the CPU, guarantees accuracy with a little performance cost.

			//setup controller to be used on the camera
			cameraController = new HoverController(camera, null, 180, 20, 320, 5);
			
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
			text.width = 1000;
			text.height = 200;
			text.x = 25;
			text.y = 50;
			text.selectable = false;
			text.mouseEnabled = false;
			text.text = "Camera controls -----\n";
			text.text = "  Click and drag on the stage to rotate camera.\n";
			text.appendText("  Keyboard arrows and WASD also rotate camera and Z and X zoom camera.\n");
			text.appendText("Picking ----- \n");
			text.appendText("  Click on the head model to draw on its texture. \n");
			text.appendText("  Red objects have triangle picking precision. \n" );
			text.appendText("  Blue objects have bounds picking precision. \n" );
			text.appendText("  Gray objects are disabled for picking but occlude picking on other objects. \n" );
			text.appendText("  Black objects are completely ignored for picking. \n" );
			text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
			addChild(text);
		}
		
		/**
		 * Initialise the lights
		 */
		private function initLights():void
		{
			//create a light for the camera
			pointLight = new PointLight();
			scene.addChild(pointLight);
			lightPicker = new StaticLightPicker([pointLight]);
		}
		
		/**
		 * Initialise the material
		 */
		private function initMaterials():void
		{
			// uv painter
			painter = new Sprite();
			painter.graphics.beginFill( 0xFF0000 );
			painter.graphics.drawCircle( 0, 0, 10 );
			painter.graphics.endFill();

			// locator materials
			whiteMaterial = new ColorMaterial( 0xFFFFFF );
			whiteMaterial.lightPicker = lightPicker;
			blackMaterial = new ColorMaterial( 0x333333 );
			blackMaterial.lightPicker = lightPicker;
			grayMaterial = new ColorMaterial( 0xCCCCCC );
			grayMaterial.lightPicker = lightPicker;
			blueMaterial = new ColorMaterial( 0x0000FF );
			blueMaterial.lightPicker = lightPicker;
			redMaterial = new ColorMaterial( 0xFF0000 );
			redMaterial.lightPicker = lightPicker;
		}
		
		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			// To trace mouse hit position.
			pickingPositionTracer = new Mesh( new SphereGeometry( 2 ), new ColorMaterial( 0x00FF00, 0.5 ) );
			pickingPositionTracer.visible = false;
			pickingPositionTracer.mouseEnabled = false;
			scene.addChild(pickingPositionTracer);

			// To trace picking normals.
			pickingNormalTracer = new SegmentSet();
			pickingNormalTracer.mouseEnabled = pickingNormalTracer.mouseChildren = false;
			var lineSegment:LineSegment = new LineSegment( new Vector3D(), new Vector3D(), 0xFFFFFF, 0xFFFFFF, 3 );
			pickingNormalTracer.addSegment( lineSegment );
			pickingNormalTracer.visible = false;
			view.scene.addChild( pickingNormalTracer );

			// Load a head model that we will be able to paint on on mouse down.
			var parser:OBJParser = new OBJParser( 25 );
			parser.addEventListener( AssetEvent.ASSET_COMPLETE, onAssetComplete );
			parser.parseAsync( new HeadAsset() );

			// Produce a bunch of objects to be around the scene.
			createABunchOfObjects();
		}

		private function onAssetComplete( event:AssetEvent ):void {
			if( event.asset.assetType == AssetType.MESH ) {
				initializeHeadModel( event.asset as Mesh );
			}
		}

		private function initializeHeadModel( model:Mesh ):void {

			head = model;

			// Apply a bitmap material that can be painted on.
			var bmd:BitmapData = new BitmapData( PAINT_TEXTURE_SIZE, PAINT_TEXTURE_SIZE, false, 0xFF0000 );
			bmd.perlinNoise( 50, 50, 8, 1, false, true, 7, true );
			var bitmapTexture:BitmapTexture = new BitmapTexture( bmd );
			var textureMaterial:TextureMaterial = new TextureMaterial( bitmapTexture );
			textureMaterial.lightPicker = lightPicker;
			model.material = textureMaterial;

			// Set up a ray picking collider.
			// The head model has quite a lot of triangles, so its best to use pixel bender for ray picking calculations.
			// NOTE: Pixel bender will not produce faster results on devices with only one cpu core, and will not work on iOS.
			model.pickingCollider = PickingColliderType.PB_BEST_HIT;
//			model.pickingCollider = PickingColliderType.PB_FIRST_ENCOUNTERED; // is faster, but causes weirdness around the eyes

			// Apply mouse interactivity.
			model.mouseEnabled = model.mouseChildren = model.shaderPickingDetails = true;
			enableMeshMouseListeners( model );

			view.scene.addChild( model );
		}

		private function createABunchOfObjects():void {

			cubeGeometry = new CubeGeometry( 25, 25, 25 );
			sphereGeometry = new SphereGeometry( 12 );
			cylinderGeometry = new CylinderGeometry( 12, 12, 25 );
			torusGeometry = new TorusGeometry( 12, 12 );

			for( var i:uint; i < 40; i++ ) {

				// Create object.
				var object:Mesh = createSimpleObject();

				// Random orientation.
				object.rotationX = 360 * Math.random();
				object.rotationY = 360 * Math.random();
				object.rotationZ = 360 * Math.random();

				// Random position.
				var r:Number = 200 + 100 * Math.random();
				var azimuth:Number = 2 * Math.PI * Math.random();
				var elevation:Number = 0.25 * Math.PI * Math.random();
				object.x = r * Math.cos(elevation) * Math.sin(azimuth);
				object.y = r * Math.sin(elevation);
				object.z = r * Math.cos(elevation) * Math.cos(azimuth);
			}
		}

		private function createSimpleObject():Mesh {

			var geometry:Geometry;
			var bounds:BoundingVolumeBase;
			
			// Chose a random geometry.
			var randGeometry:Number = Math.random();
			if( randGeometry > 0.75 ) {
				geometry = cubeGeometry;
			}
			else if( randGeometry > 0.5 ) {
				geometry = sphereGeometry;
				bounds = new BoundingSphere(); // better on spherical meshes with bound picking colliders
			}
			else if( randGeometry > 0.25 ) {
				geometry = cylinderGeometry;
				
			}
			else {
				geometry = torusGeometry;
			}
			
			var mesh:Mesh = new Mesh(geometry);
			
			if (bounds)
				mesh.bounds = bounds;

			// For shader based picking.
			mesh.shaderPickingDetails = true;

			// Randomly decide if the mesh has a triangle collider.
			var usesTriangleCollider:Boolean = Math.random() > 0.5;
			if( usesTriangleCollider ) {
				// AS3 triangle pickers for meshes with low poly counts are faster than pixel bender ones.
//				mesh.pickingCollider = PickingColliderType.BOUNDS_ONLY; // this is the default value for all meshes
				mesh.pickingCollider = PickingColliderType.AS3_FIRST_ENCOUNTERED;
//				mesh.pickingCollider = PickingColliderType.AS3_BEST_HIT; // slower and more accurate, best for meshes with folds
//				mesh.pickingCollider = PickingColliderType.AUTO_FIRST_ENCOUNTERED; // automatically decides when to use pixel bender or actionscript
			}

			// Enable mouse interactivity?
			var isMouseEnabled:Boolean = Math.random() > 0.25;
			mesh.mouseEnabled = mesh.mouseChildren = isMouseEnabled;

			// Enable mouse listeners?
			var listensToMouseEvents:Boolean = Math.random() > 0.25;
			if( isMouseEnabled && listensToMouseEvents ) {
				enableMeshMouseListeners( mesh );
			}

			// Apply material according to the random setup of the object.
			choseMeshMaterial( mesh );

			// Add to scene and store.
			view.scene.addChild( mesh );

			return mesh;
		}

		private function choseMeshMaterial( mesh:Mesh ):void {
			if( !mesh.mouseEnabled ) {
				mesh.material = blackMaterial;
			}
			else {
				if( !mesh.hasEventListener( MouseEvent3D.MOUSE_MOVE ) ) {
					mesh.material = grayMaterial;
				}
				else {
					if( mesh.pickingCollider != PickingColliderType.BOUNDS_ONLY ) {
						mesh.material = redMaterial;
					}
					else {
						mesh.material = blueMaterial;
					}
				}
			}
		}

		/**
		 * Initialise the listeners
		 */
		private function initListeners():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
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
			// Update camera.
			if (move) {
				cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
			}
			cameraController.panAngle += panIncrement;
			cameraController.tiltAngle += tiltIncrement;
			cameraController.distance += distanceIncrement;

			// Move light with camera.
			pointLight.position = camera.position;

			// Render 3D.
			view.render();
		}
		
		/**
		 * Key down listener for camera control
		 */
		private function onKeyDown(event:KeyboardEvent):void
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
		private function onKeyUp(event:KeyboardEvent):void
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
			awayStats.x = stage.stageWidth - awayStats.width;
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

		// ---------------------------------------------------------------------
		// 3D mouse event handlers.
		// ---------------------------------------------------------------------

		protected function enableMeshMouseListeners( mesh:Mesh ):void {
			mesh.addEventListener( MouseEvent3D.MOUSE_OVER, onMeshMouseOver );
			mesh.addEventListener( MouseEvent3D.MOUSE_OUT, onMeshMouseOut );
			mesh.addEventListener( MouseEvent3D.MOUSE_MOVE, onMeshMouseMove );
			mesh.addEventListener( MouseEvent3D.MOUSE_DOWN, onMeshMouseDown );
		}

		/**
		 * mesh listener for mouse down interaction
		 */
		private function onMeshMouseDown( event:MouseEvent3D ):void {
			var mesh:Mesh = event.object as Mesh;
			// Paint on the head's material.
			if( mesh == head ) {
				var uv:Point = event.uv;
				var textureMaterial:TextureMaterial = Mesh( event.object ).material as TextureMaterial;
				var bmd:BitmapData = BitmapTexture( textureMaterial.texture ).bitmapData;
				var x:uint = uint( PAINT_TEXTURE_SIZE * uv.x );
				var y:uint = uint( PAINT_TEXTURE_SIZE * uv.y );
				var matrix:Matrix = new Matrix();
				matrix.translate( x, y );
				bmd.draw( painter, matrix );
				BitmapTexture( textureMaterial.texture ).invalidateContent();
			}
		}

		/**
		 * mesh listener for mouse over interaction
		 */
		private function onMeshMouseOver(event:MouseEvent3D):void
		{
			var mesh:Mesh = event.object as Mesh;
			mesh.showBounds = true;
			if( mesh != head ) mesh.material = whiteMaterial;
			pickingPositionTracer.visible = pickingNormalTracer.visible = true;
			onMeshMouseMove(event);
		}

		/**
		 * mesh listener for mouse out interaction
		 */
		private function  onMeshMouseOut(event:MouseEvent3D):void
		{
			var mesh:Mesh = event.object as Mesh;
			mesh.showBounds = false;
			if( mesh != head ) choseMeshMaterial( mesh );
			pickingPositionTracer.visible = pickingNormalTracer.visible = false;
			pickingPositionTracer.position = new Vector3D();
		}

		/**
		 * mesh listener for mouse move interaction
		 */
		private function  onMeshMouseMove(event:MouseEvent3D):void
		{
			// Show tracers.
			pickingPositionTracer.visible = pickingNormalTracer.visible = true;

			// Update position tracer.
			pickingPositionTracer.position = event.scenePosition;

			// Update normal tracer.
			pickingNormalTracer.position = pickingPositionTracer.position;
			var normal:Vector3D = event.sceneNormal.clone();
			normal.scaleBy( 25 );
			var lineSegment:LineSegment = pickingNormalTracer.getSegment( 0 ) as LineSegment;
			lineSegment.end = normal.clone();
		}
	}
}
