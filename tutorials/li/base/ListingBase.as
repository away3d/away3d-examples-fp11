package li.base
{

	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.materials.lightpickers.StaticLightPicker;

	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;

	import flashx.textLayout.formats.TextAlign;

	public class ListingBase extends Sprite
	{
		// Protected.
		protected var _view:View3D;
		protected var _lightPicker:StaticLightPicker;
		protected var _cameraController:HoverController;

		// Private.
		private var _text:TextField;

		// Camera control.
		private var _mouseIsDown:Boolean;
		private var _lastPanAngle:Number;
		private var _lastTiltAngle:Number;
		private var _lastMouseX:Number;
		private var _lastMouseY:Number;
		private var _tiltIncrement:Number = 0;
		private var _panIncrement:Number = 0;

		private const WIDTH:Number = 800;
		private const HEIGHT:Number = 600;

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
			onSetup();
			addEventListener( Event.ENTER_FRAME, enterframeHandler );
		}

		private function initStage():void {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.frameRate = 60;
			stage.addEventListener( MouseEvent.MOUSE_DOWN, stageMouseDownHandler );
			stage.addEventListener( MouseEvent.MOUSE_UP, stageMouseUpHandler );
			stage.addEventListener( MouseEvent.MOUSE_WHEEL, stageMouseWheelHandler );
		}

		protected function initAway3d():void {
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

		// ---------------------------------------------------------------------
		// Event handlers.
		// ---------------------------------------------------------------------

		private function addedToStageHandler( event:Event ):void {
			removeEventListener( Event.ADDED_TO_STAGE, addedToStageHandler );
			initialize();
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

		private function enterframeHandler( event:Event ):void {
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
