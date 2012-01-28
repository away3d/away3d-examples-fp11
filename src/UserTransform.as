package
{
	import flash.display.Stage;
	import flash.events.KeyboardEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;

	public class UserTransform
	{
		protected var _spinRate:Number;
		protected var keysDown:Vector.<Boolean> = new <Boolean>[false, false, false, false];
		protected var yaw:Matrix3D = new Matrix3D(); // looking left / right
		protected var pitch:Matrix3D = new Matrix3D(); // looking up / down
		protected var xform:Matrix3D = new Matrix3D(); // composite result
		
		public function UserTransform(stage:Stage, spinRate:Number=.625)
		{
			_spinRate = spinRate;
			
			yaw.identity();
			pitch.identity();
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP,onKeyUp);
		}
		
		public function update():void
		{
			if(keysDown[0]) adjustPitch(-spinRate);
			if(keysDown[1]) adjustPitch(+spinRate);
			if(keysDown[2]) adjustYaw(-spinRate);
			if(keysDown[3]) adjustYaw(+spinRate);
		}
		
		public function get value():Matrix3D
		{
			xform.identity();
			xform.prepend(pitch);
			xform.append(yaw);
			return xform;
		}
		
		public function set spinRate(value:Number):void { _spinRate = value; }
		public function get spinRate():Number { return _spinRate; }
		
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