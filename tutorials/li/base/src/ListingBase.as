package li.base.src
{

	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.lights.PointLight;
	import away3d.materials.lightpickers.StaticLightPicker;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getTimer;

	import flashx.textLayout.formats.TextAlign;

	public class ListingBase extends Sprite
	{
		// Protected.
		protected var _view:View3D;
		protected var _lightPicker:StaticLightPicker;
		protected var _cameraController:HoverController;

		// Private.
		private var _overlay:Sprite;
		private var _bitmap:Bitmap;
		private var _text:TextField;
		private var _lastMouseMoveTime:uint;
		private var _enabled:Boolean;

		// Camera control.
		private var _mouseIsDown:Boolean;
		private var _lastPanAngle:Number;
		private var _lastTiltAngle:Number;
		private var _lastMouseX:Number;
		private var _lastMouseY:Number;
		private var _tiltIncrement:Number = 0;
		private var _panIncrement:Number = 0;

		private const WIDTH:Number = 540;
		private const HEIGHT:Number = 400;

		public function ListingBase() {
			super();
			addEventListener( Event.ADDED_TO_STAGE, addedToStageHandler );
		}

		// ---------------------------------------------------------------------
		// Private.
		// ---------------------------------------------------------------------

		private function initialize():void {
			initStage();
			initAway3d();
			initCanvas();
			onSetup();
			enable();
		}

		private function initStage():void {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.frameRate = 60;
			stage.addEventListener( MouseEvent.MOUSE_MOVE, stageMouseMoveHandler );
			stage.addEventListener( MouseEvent.MOUSE_DOWN, stageMouseDownHandler );
			stage.addEventListener( MouseEvent.MOUSE_UP, stageMouseUpHandler );
			stage.addEventListener( MouseEvent.MOUSE_WHEEL, stageMouseWheelHandler );
			stage.addEventListener( Event.MOUSE_LEAVE, stageMouseLeaveHandler );
		}

		private function initCanvas():void {
			_overlay = new Sprite();
			_bitmap = new Bitmap();
			_bitmap.transform.colorTransform = new ColorTransform( 0.5, 0.5, 0.5, 1, 150, 150, 150, 0 );
			_bitmap.bitmapData = new BitmapData( WIDTH, HEIGHT, false, 0 );
			_overlay.addChild( _bitmap );
			_text = new TextField();
			_text.multiline = true;
			_text.width = 110;
			_text.selectable = false;
			var format:TextFormat = new TextFormat();
			format.font = "Arial";
			format.align = TextAlign.CENTER;
			_text.defaultTextFormat = format;
			_text.text = "MOUSE OVER TO\nENABLE DEMO";
			_text.x = WIDTH / 2 - _text.width / 2;
			_text.y = HEIGHT / 2 - _text.height / 2;
			_overlay.addChild( _text );
			addChild( _overlay );
		}

		private function initAway3d():void {
			// View.
			_view = new View3D();
			_view.backgroundColor = 0x000000;
			_view.width = WIDTH;
			_view.height = HEIGHT;
			_view.antiAlias = 4;
			_view.addSourceURL( "srcview/index.html" );
			_view.forceMouseMove = true;
			addChild( _view );
			// Camera.
			_cameraController = new HoverController( _view.camera, null, 0, 0, 300 );
			_cameraController.yFactor = 1;
			// Lights.
			_lightPicker = new StaticLightPicker( [] );
		}

		private function update():void {
			onUpdate();
			if( _mouseIsDown ) {
				_cameraController.panAngle = 0.4 * ( _view.mouseX - _lastMouseX ) + _lastPanAngle;
				_cameraController.tiltAngle = 0.4 * ( _view.mouseY - _lastMouseY ) + _lastTiltAngle;
			}
			_cameraController.panAngle += _panIncrement;
			_cameraController.tiltAngle += _tiltIncrement;
			_view.render();
		}

		private function disable():void {
			if( !_enabled ) return;
			if( !_overlay.hasEventListener( MouseEvent.MOUSE_OVER ) ) _overlay.addEventListener( MouseEvent.MOUSE_OVER, onOverlayMouseOver );
			if( hasEventListener( Event.ENTER_FRAME ) ) removeEventListener( Event.ENTER_FRAME, enterframeHandler );
			_overlay.visible = true;
			updateOverlay();
			_enabled = false;
		}

		private function enable():void {
			if( _enabled ) return;
			if( _overlay.hasEventListener( MouseEvent.MOUSE_OVER ) ) _overlay.removeEventListener( MouseEvent.MOUSE_OVER, onOverlayMouseOver );
			if( !_view.hasEventListener( MouseEvent.ROLL_OUT ) ) _view.addEventListener( MouseEvent.ROLL_OUT, onViewMouseOut );
			if( !hasEventListener( Event.ENTER_FRAME ) ) addEventListener( Event.ENTER_FRAME, enterframeHandler );
			_overlay.visible = false;
			_enabled = true;
		}

		private function updateOverlay():void {
			_view.renderer.queueSnapshot( _bitmap.bitmapData );
			_view.render();
			_bitmap.bitmapData.applyFilter( _bitmap.bitmapData, _bitmap.bitmapData.rect, new Point(), new BlurFilter( 4, 4, 3 ) );
		}

		// ---------------------------------------------------------------------
		// Event handlers.
		// ---------------------------------------------------------------------

		private function addedToStageHandler( event:Event ):void {
			removeEventListener( Event.ADDED_TO_STAGE, addedToStageHandler );
			initialize();
		}

		private function onOverlayMouseOver( event:MouseEvent ):void {
			enable();
		}

		private function onViewMouseOut( event:MouseEvent ):void {
			disable();
		}

		private function stageMouseMoveHandler( event:MouseEvent ):void {
			_lastMouseMoveTime = getTimer();
		}

		private function stageMouseDownHandler( event:MouseEvent ):void {
			_mouseIsDown = true;
			_lastPanAngle = _cameraController.panAngle;
			_lastTiltAngle = _cameraController.tiltAngle;
			_lastMouseX = stage.mouseX;
			_lastMouseY = stage.mouseY;
		}

		private function stageMouseWheelHandler( event:MouseEvent ):void {
			_cameraController.distance -= event.delta * 5;
			if( _cameraController.distance < 200 )
				_cameraController.distance = 200;
			else if( _cameraController.distance > 1000 )
				_cameraController.distance = 1000;
		}

		private function stageMouseUpHandler( event:MouseEvent ):void {
			_mouseIsDown = false;
		}

		private function stageMouseLeaveHandler( event:Event ):void {
			disable();
		}

		private function enterframeHandler( event:Event ):void {
			var time:uint = getTimer();
			var elapsedSinceLastMouseMove:uint = time - _lastMouseMoveTime;
			if( elapsedSinceLastMouseMove > 2000 ) disable();
			else enable();
			update();
		}

		// ---------------------------------------------------------------------
		// Protected.
		// ---------------------------------------------------------------------

		protected function onSetup():void {
			// Override me.
		}

		protected function onUpdate():void {
			// Override me.
		}
	}
}
