package away3d.primitives
{
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	import away3d.textures.BitmapCubeTexture;
	
	import flash.display.Sprite;
	import flash.events.Event;
	
	[SWF(width="800", height="600", frameRate="60", backgroundColor="#000000")]
	public class SkyBoxExample extends Sprite
	{
		
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
		protected var userTransform:UserTransform;
		
		public function SkyBoxExample()
		{
			super();
			
			// create a viewport and add geometry to its scene
			view = new View3D();
			view.scene.addChild(createGeo());
			addChild(view);
			
			// let user manipulate camera orientation
			userTransform = new UserTransform(stage);
			
			// listen for enterframe to to render updates
			addEventListener(Event.ENTER_FRAME,update);
		}
		
		protected function update(e:Event):void
		{
			// apply current user rotations
			userTransform.update();
			view.camera.transform = userTransform.value;
			
			// render the view
			view.render();
		}
		
		protected function createGeo():ObjectContainer3D
		{
			// skybox has its own mesh primitive, and uses a BitmapCubeTexture as its material
			var material:BitmapCubeTexture = new BitmapCubeTexture
				(
					new SkyPosX().bitmapData, new SkyNegX().bitmapData,
					new SkyPosY().bitmapData, new SkyNegY().bitmapData,
					new SkyPosZ().bitmapData, new SkyNegZ().bitmapData
				);
			var geometry:SkyBox = new SkyBox(material);
			return geometry;
		}
		
	}
}