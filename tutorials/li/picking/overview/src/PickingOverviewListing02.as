package li.picking.overview.src
{

	import away3d.entities.Mesh;
	import away3d.events.MouseEvent3D;
	import away3d.materials.ColorMaterial;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.SphereGeometry;

	public class PickingOverviewListing02 extends PickingOverviewListingBase
	{
		public function PickingOverviewListing02() {
		 	super();
		}

		private var _inactiveMaterial:ColorMaterial;
		private var _activeMaterial:ColorMaterial;

		override protected function onSetup():void {

			_cameraController.panAngle = -63;
			_cameraController.tiltAngle = 10;

			// Init materials.
			_activeMaterial = new ColorMaterial( 0xFF0000 );
			_activeMaterial.lightPicker = _lightPicker;
			_inactiveMaterial = new ColorMaterial( 0xCCCCCC );
			_inactiveMaterial.lightPicker = _lightPicker;
			var disabledMaterial:ColorMaterial = new ColorMaterial( 0x666666 );
			disabledMaterial.lightPicker = _lightPicker;

			// Create 2 objects.
			var cube:Mesh = new Mesh( new CubeGeometry(), disabledMaterial );
			cube.x = -75;
			_view.scene.addChild( cube );
			var sphere:Mesh = new Mesh( new SphereGeometry(), _inactiveMaterial );
			sphere.x = 75;
			_view.scene.addChild( sphere );

			// Enable mouse interactivity.
			cube.mouseEnabled = true;
			sphere.mouseEnabled = true;

			// Attach mouse event listeners.
//			cube.addEventListener( MouseEvent3D.MOUSE_OVER, onObjectMouseOver ); // By attaching no listeners to the object, it simply occludes picking ( if mouseEnabled = true ).
//			cube.addEventListener( MouseEvent3D.MOUSE_OUT, onObjectMouseOut );
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
