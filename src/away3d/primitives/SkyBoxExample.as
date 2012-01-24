package away3d.primitives
{
	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.textures.BitmapCubeTexture;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;
	
	[SWF(width="800", height="600", frameRate="60", backgroundColor="#000000")]
	public class SkyBoxExample extends Sprite
	{
		protected const spinRate:Number = .625;
		
		[Embed(source="/../embeds/skybox/sky_negX.jpg")]
		protected const SkyNegX:Class;
		[Embed(source="/../embeds/skybox/sky_negY.jpg")]
		protected const SkyNegY:Class;
		[Embed(source="/../embeds/skybox/sky_negZ.jpg")]
		protected const SkyNegZ:Class;
		
		[Embed(source="/../embeds/skybox/sky_posX.jpg")]
		protected const SkyPosX:Class;
		[Embed(source="/../embeds/skybox/sky_posY.jpg")]
		protected const SkyPosY:Class;
		[Embed(source="/../embeds/skybox/sky_posZ.jpg")]
		protected const SkyPosZ:Class;
		
		protected var view:View3D;
		protected var cam:Camera3D;
		protected var scene:Scene3D;
		protected var geo:ObjectContainer3D;
		
		protected var keysDown:Vector.<Boolean> = new <Boolean>[false, false, false, false];
		protected var yaw:Matrix3D = new Matrix3D(); // looking left / right
		protected var pitch:Matrix3D = new Matrix3D(); // looking up / down
		
		public function SkyBoxExample()
		{
			// initialize view angle matrices
			yaw.identity();
			pitch.identity();
			
			// create a viewport and add geometry to its scene
			view = new View3D();
			view.backgroundColor = 0x333333;
			addChild(view);
			
			geo = createGeo();
			
			scene = view.scene;
			scene.addChild(geo);
			
			cam = view.camera;
			
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
			cam.transform = userTransform;
			
			// render the view
			view.render();
		}
		
		protected function createGeo():ObjectContainer3D
		{
			var material:BitmapCubeTexture = new BitmapCubeTexture
				(
					new SkyPosX().bitmapData, new SkyNegX().bitmapData,
					new SkyPosY().bitmapData, new SkyNegY().bitmapData,
					new SkyPosZ().bitmapData, new SkyNegZ().bitmapData
				);
			var geometry:SkyBox = new SkyBox(material);
			return geometry;
		}
		
		protected function get userTransform():Matrix3D
		{
			var xform:Matrix3D = cam.transform;
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