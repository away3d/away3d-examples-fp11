package
{
	import away3d.bounds.*;
	import away3d.cameras.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.core.base.*;
	import away3d.core.raycast.*;
	import away3d.debug.*;
	import away3d.entities.*;
	import away3d.events.*;
	import away3d.lights.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.*;
	import away3d.primitives.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.ui.*;
	
	[SWF(backgroundColor="#000000", frameRate="30", quality="LOW")]
	
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
		private var activeMaterial:ColorMaterial;
		private var offMaterial:ColorMaterial;
		private var inactiveMaterial:ColorMaterial;
		
		//scene objects
		private var text:TextField;
		private var dataText:TextField;
		private var meshIntersectionTracer:Mesh;
		private var meshes:Vector.<Mesh>;
		private var mouseHitMethod:uint = MouseHitMethod.MESH_ANY_HIT;
		
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
			text.width = 240;
			text.height = 100;
			text.selectable = false;
			text.mouseEnabled = false;
			text.text = "Click and drag on the stage to rotate camera.\n";
			text.appendText("Keyboard arrows and WASD also rotate camera.\n");
			text.appendText("Keyboard Z and X zoom camera.\n");
			text.appendText("- Press SPACE to change picking method. \n");
			text.appendText("- All scene objects are mouseEnabled, except the small sphere under the mouse. \n");
			text.appendText("- Red objects have mouse listeners, gray objects don't. \n");
			text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
			
			addChild(text);
			
			//trace data
			dataText = new TextField();
			dataText.defaultTextFormat = new TextFormat("Verdana", 11, 0xFF0000);
			dataText.width = 240;
			dataText.height = 40;
			dataText.selectable = false;
			dataText.mouseEnabled = false;
			dataText.y = 100;
			dataText.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
			addChild(dataText);
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
			// locator materials
			inactiveMaterial = new ColorMaterial( 0xFF0000 );
			inactiveMaterial.lightPicker = lightPicker;
			activeMaterial = new ColorMaterial( 0x0000FF );
			activeMaterial.lightPicker = lightPicker;
			offMaterial = new ColorMaterial( 0xFFFFFF );
			offMaterial.lightPicker = lightPicker;
		}
		
		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			// intersection points
			meshIntersectionTracer = new Mesh( new SphereGeometry( 2 ), new ColorMaterial( 0x00FF00, 0.5 ) );
			meshIntersectionTracer.visible = false;
			meshIntersectionTracer.mouseEnabled = false;
			scene.addChild(meshIntersectionTracer);
			
			meshes = new Vector.<Mesh>();
			
			// cubes
			var i:uint;
			var mesh:Mesh;
			var len:uint = 201;
			var cubeGeometry:CubeGeometry = new CubeGeometry(30*Math.random() + 20, 30*Math.random() + 20, 30*Math.random() + 20, 10, 10, 10);
			
			for(i = 0; i < len; ++i) {
				if (i) {
					mesh = new Mesh(cubeGeometry, inactiveMaterial);
					mesh.rotationX = 360*Math.random();
					mesh.rotationY = 360*Math.random();
					mesh.rotationZ = 360*Math.random();
					mesh.bakeTransformations();
					mesh.position = new Vector3D(1500*Math.random() - 750, 0, 1500*Math.random() - 750);
					if( Math.random() > 0.75 ) {
						mesh.bounds = new BoundingSphere();
					}
					mesh.rotationX = 360*Math.random();
					mesh.rotationY = 360*Math.random();
					mesh.rotationZ = 360*Math.random();
				} else {
					mesh = new Mesh(new PlaneGeometry(1000, 1000), inactiveMaterial);
				}
				
				if(i && Math.random() > 0.5) { //add listener and update hit method
					mesh.addEventListener( MouseEvent3D.MOUSE_MOVE, onMeshMouseMove);
					mesh.addEventListener( MouseEvent3D.MOUSE_OVER, onMeshMouseOver);
					mesh.addEventListener( MouseEvent3D.MOUSE_OUT, onMeshMouseOut);
				} else { //leave mesh 
					mesh.material = offMaterial;
				}
				
				mesh.mouseHitMethod = mouseHitMethod;
				mesh.mouseEnabled = true;
				mesh.showBounds = true;
				mesh.bounds.boundingRenderable.color = 0x333333;
				
				meshes.push(mesh);
				scene.addChild(mesh);
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
			if (move) {
				cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
			}
			
			cameraController.panAngle += panIncrement;
			cameraController.tiltAngle += tiltIncrement;
			cameraController.distance += distanceIncrement;
			
			pointLight.position = camera.position;
			
			//update data text
			var modeMsg:String;
			switch(mouseHitMethod) {
				case MouseHitMethod.BOUNDS_ONLY:
					modeMsg = "bounds only";
					break;
				case MouseHitMethod.MESH_CLOSEST_HIT:
					modeMsg = "mesh closest hit";
					break;
				case MouseHitMethod.MESH_ANY_HIT:
					modeMsg = "mesh any hit";
					break;
				case 99:
					modeMsg = "none";
					break;
			}
			dataText.text = "Mouse mode: " + modeMsg + "\n";
			dataText.appendText("Test time: " + view.mouse3DManager.testTime + "ms");
			
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
				case Keyboard.SPACE:
					switch( mouseHitMethod ) {
						case MouseHitMethod.MESH_ANY_HIT:
							mouseHitMethod = MouseHitMethod.BOUNDS_ONLY;
							break;
						case MouseHitMethod.BOUNDS_ONLY:
							mouseHitMethod = MouseHitMethod.MESH_CLOSEST_HIT;
							break;
						case MouseHitMethod.MESH_CLOSEST_HIT:
							mouseHitMethod = 99;
							break;
						case 99:
							mouseHitMethod = MouseHitMethod.MESH_ANY_HIT;
							break;
					}
					
					for each(var mesh:Mesh in meshes) {
						if(mouseHitMethod == 99) {
							mesh.mouseEnabled = false;
						} else {
							mesh.mouseEnabled = true;
							mesh.mouseHitMethod = mouseHitMethod;
						}
					}
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
		 * mesh listener for mouse over interaction
		 */
		private function onMeshMouseOver(event:MouseEvent3D):void
		{
			(event.object as Mesh).material = activeMaterial;
			
			meshIntersectionTracer.visible = true;
			onMeshMouseMove(event);
		}
		
		/**
		 * mesh listener for mouse out interaction
		 */
		private function  onMeshMouseOut(event:MouseEvent3D):void
		{
			(event.object as Mesh).material = inactiveMaterial;
			
			meshIntersectionTracer.visible = false;
			meshIntersectionTracer.position = new Vector3D();
		}
		
		/**
		 * mesh listener for mouse move interaction
		 */
		private function  onMeshMouseMove(event:MouseEvent3D):void
		{
			meshIntersectionTracer.visible = true;
			meshIntersectionTracer.position = new Vector3D( event.sceneX, event.sceneY, event.sceneZ );
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
			awayStats.x = stage.stageWidth - awayStats.width;
		}
	}
}
