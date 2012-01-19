package
{
	import away3d.cameras.Camera3D;
    import away3d.containers.ObjectContainer3D;
	import away3d.cameras.lenses.PerspectiveLens;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.primitives.*;

	import flash.display.*;
	import flash.events.*;
    import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
    import flash.ui.Keyboard;

    [SWF(width="800", height="600", frameRate="60", backgroundColor="#000000")]
	public class WireGridTest extends Sprite
	{
		private var _primitive : WireframePrimitiveBase;
		private var _view : View3D;
		private var camera : Camera3D;
		private var origin : Vector3D = new Vector3D(0, 0, 0);
		
		protected var geo:ObjectContainer3D;
		protected const spinRate:Number = .625;
		protected var keysDown:Vector.<Boolean> = new <Boolean>[false, false, false, false];
		protected var yaw:Matrix3D = new Matrix3D(); // looking left / right
		protected var pitch:Matrix3D = new Matrix3D(); // looking up / down

		private var wave : Number = 0;

		public function WireGridTest()
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e : Event) : void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			initView();
			populate();
		}

		private function initView() : void
		{
			_view = new View3D();
			_view.antiAlias = 4;
			_view.backgroundColor = 0x333333;
			camera = _view.camera;
			camera.lens = new PerspectiveLens();

			//camera.x = 500;
			//camera.y = 1;
			//camera.z = 500;
			addChild(_view);
			//addChild(new AwayStats(_view));

			camera.lookAt(new Vector3D(0, 0, 0));
			camera.lens.near = 10;
			camera.lens.far = 3000;
			
			// listen for key events and frame updates
			stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP,onKeyUp);
			addEventListener(Event.ENTER_FRAME,update);
		}

		private function populate() : void
		{
			geo = new WireframeAxesGrid(10, 500);
			_view.scene.addChild(geo);

			_primitive = new WireframeSphere(100);
			_primitive.x = 0;
			_primitive.y = 0;
			_primitive.z = 0;
			_view.scene.addChild(_primitive);
		}

		private function update(e : Event) : void
		{
			/*
			wave += .02;
			_primitive.y = 200 * Math.sin(wave);

			_view.camera.position = origin;
			_view.camera.rotationY += .5;
			_view.camera.moveBackward(500);
			_view.camera.y = 50 * Math.sin(wave);
			*/
			// adjust geo rotations if user is pressing keys
			if(keysDown[0]) adjustPitch(-spinRate);
			if(keysDown[1]) adjustPitch(+spinRate);
			if(keysDown[2]) adjustYaw(-spinRate);
			if(keysDown[3]) adjustYaw(+spinRate);
            
            // apply current user rotations
            geo.transform = userTransform;
            
            // render the view
			_view.render();
		}
		
		protected function get userTransform():Matrix3D
		{
			var xform:Matrix3D = geo.transform;
			xform.identity();
			xform.prepend(pitch);
			xform.append(yaw);
			return xform;
		}
		
		protected function adjustYaw(value:Number):void
		{
			yaw.prependRotation(value, Vector3D.Y_AXIS);
		}
		
		protected function adjustPitch(value:Number):void
		{
			pitch.prependRotation(value, Vector3D.X_AXIS);
		}
		
		protected function onKeyDown(e:KeyboardEvent):void
		{
			switch(e.keyCode)
			{
				case Keyboard.UP    : keysDown[0] = true; break;
				case Keyboard.DOWN  : keysDown[1] = true; break;
				case Keyboard.LEFT  : keysDown[2] = true; break;
				case Keyboard.RIGHT : keysDown[3] = true; break;
			}
		}
		
		protected function onKeyUp(e:KeyboardEvent):void
		{
			switch(e.keyCode)
			{
				case Keyboard.UP    : keysDown[0] = false; break;
				case Keyboard.DOWN  : keysDown[1] = false; break;
				case Keyboard.LEFT  : keysDown[2] = false; break;
				case Keyboard.RIGHT : keysDown[3] = false; break;
			}
		}

	}
}
