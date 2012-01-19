package
{
    import away3d.cameras.Camera3D;
    import away3d.containers.ObjectContainer3D;
    import away3d.containers.Scene3D;
    import away3d.containers.View3D;
    import away3d.entities.Mesh;
    import away3d.materials.SegmentMaterial;
    import away3d.primitives.WireframeCube;

    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;
    import flash.ui.Keyboard;

    [SWF(width="800", height="600", frameRate="60", backgroundColor="#000000")]
	public class Basic_Cube_Wireframe extends Sprite
	{
		protected const spinRate:Number = .625;
		
		protected var view:View3D;
		protected var cam:Camera3D;
		protected var scene:Scene3D;
		protected var geo:ObjectContainer3D;
		
		protected var keysDown:Vector.<Boolean> = new <Boolean>[false, false, false, false];
		protected var yaw:Matrix3D = new Matrix3D(); // looking left / right
		protected var pitch:Matrix3D = new Matrix3D(); // looking up / down
		
		public function Basic_Cube_Wireframe()
		{
			// initialize view angle matrices
			yaw.identity();
			pitch.identity();
			
			// create a viewport and add geometry to its scene
			view = new View3D();
			view.antiAlias = 4;
			view.backgroundColor = 0x333333;
			addChild(view);
			
			geo = createGeo(0xee7722);
			
			scene = view.scene;
			scene.addChild(geo);
			
			cam = view.camera;
			cam.z = -100;
			cam.y = 100;
			cam.lookAt(geo.position);
			
			// listen for key events and frame updates
			stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP,onKeyUp);
			addEventListener(Event.ENTER_FRAME,update);
		}
		
		protected function update(e:Event):void
		{
			// adjust geo rotations if user is pressing keys
			if(keysDown[0]) adjustPitch(-spinRate);
			if(keysDown[1]) adjustPitch(+spinRate);
			if(keysDown[2]) adjustYaw(-spinRate);
			if(keysDown[3]) adjustYaw(+spinRate);
            
            // apply current user rotations
            geo.transform = userTransform;
            
            // render the view
            view.render();
		}
		
		protected function createGeo(color:uint=0x888888):ObjectContainer3D
		{
			var geometry:WireframeCube = new WireframeCube(75, 50, 25, color, 4);
			var material:SegmentMaterial = new SegmentMaterial();
			var mesh:Mesh = new Mesh(null, material);
			mesh.addChild(geometry);
			return mesh;
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
