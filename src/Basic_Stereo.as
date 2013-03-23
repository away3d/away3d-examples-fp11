package {
	import away3d.entities.Mesh;
	import away3d.materials.ColorMaterial;
	import away3d.primitives.CubeGeometry;
	import away3d.stereo.StereoCamera3D;
	import away3d.stereo.StereoView3D;
	import away3d.stereo.methods.AnaglyphStereoRenderMethod;

	import flash.display.Sprite;
	import flash.events.Event;
	
	[SWF(width="960", height="540")]
	public class Basic_Stereo extends Sprite
	{
		private var _view : StereoView3D;
		private var _camera : StereoCamera3D;
		
		private var _cube : Mesh;
		
		public function Basic_Stereo()
		{
			super();
			
			_camera = new StereoCamera3D();
			_camera.stereoOffset = 50;
			
			_view = new StereoView3D();
			_view.antiAlias = 4;
			_view.camera = _camera;
			_view.stereoEnabled = true;
			_view.stereoRenderMethod = new AnaglyphStereoRenderMethod();
			//_view.stereoRenderMethod = new InterleavedStereoRenderMethod();
			addChild(_view);
			
			_cube = new Mesh(new CubeGeometry(), new ColorMaterial(0xffcc00));
			_cube.scale(5);
			_view.scene.addChild(_cube);
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		
		private function onEnterFrame(ev : Event) : void
		{
			_cube.rotationY += 2;
			_view.render();
		}
	}
}