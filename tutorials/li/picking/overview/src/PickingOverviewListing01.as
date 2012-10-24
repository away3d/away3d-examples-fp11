package li.picking.overview.src
{

	import away3d.entities.Mesh;
	import away3d.events.MouseEvent3D;
	import away3d.materials.ColorMaterial;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.SphereGeometry;

	public class PickingOverviewListing01 extends PickingOverviewListingBase
	{
		public function PickingOverviewListing01() {
		 	super();
		}

		private var _inactiveMaterial:ColorMaterial;
		private var _activeMaterial:ColorMaterial;

		override protected function onSetup():void {

			_cameraController.panAngle = 20;
			_cameraController.tiltAngle = 20;

			// Init materials.
			_activeMaterial = new ColorMaterial( 0xFF0000 );
			_activeMaterial.lightPicker = _lightPicker;
			_inactiveMaterial = new ColorMaterial( 0xCCCCCC );
			_inactiveMaterial.lightPicker = _lightPicker;

			// Create 2 objects.
			var cube:Mesh = new Mesh( new CubeGeometry(), _inactiveMaterial );
			cube.x = -75;
			_view.scene.addChild( cube );
			var sphere:Mesh = new Mesh( new SphereGeometry(), _inactiveMaterial );
			sphere.x = 75;
			_view.scene.addChild( sphere );

			// Enable mouse interactivity.
			cube.mouseEnabled = true;
			sphere.mouseEnabled = true;

			// Attach mouse event listeners.
			cube.addEventListener( MouseEvent3D.MOUSE_OVER, onObjectMouseOver );
			cube.addEventListener( MouseEvent3D.MOUSE_OUT, onObjectMouseOut );
			sphere.addEventListener( MouseEvent3D.MOUSE_OVER, onObjectMouseOver );
			sphere.addEventListener( MouseEvent3D.MOUSE_OUT, onObjectMouseOut );

		}

		private function onObjectMouseOver( event:MouseEvent3D ):void {
			event.target.material = _activeMaterial;
		}

		private function onObjectMouseOut( event:MouseEvent3D ):void {
			event.target.material = _inactiveMaterial;
		}
	}
}
