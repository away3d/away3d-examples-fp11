package li.picking.overview.src
{

	import away3d.core.pick.PickingColliderType;
	import away3d.entities.Mesh;
	import away3d.entities.SegmentSet;
	import away3d.events.AssetEvent;
	import away3d.events.MouseEvent3D;
	import away3d.library.assets.AssetType;
	import away3d.loaders.parsers.OBJParser;
	import away3d.materials.ColorMaterial;
	import away3d.materials.TextureMaterial;
	import away3d.primitives.LineSegment;
	import away3d.primitives.SphereGeometry;
	import away3d.textures.BitmapTexture;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Vector3D;

	public class PickingOverviewListing06 extends PickingOverviewListingBase
	{
		// Assets.
		[Embed(source="../../../../embeds/head/head.obj", mimeType="application/octet-stream")]
		private var HeadAsset:Class;

		private const TEXTURE_SIZE:uint = 2048;

		private var _painting:Boolean;
		private var _bitmap:Bitmap;
		private var _painter:Sprite;
		private var _material:TextureMaterial;
		private var _texture:BitmapTexture;
		private var _locationTracer:Mesh;
		private var _normalTracer:SegmentSet;

		public function PickingOverviewListing06() {
		 	super();
		}

		override protected function onSetup():void {

			_cameraController.panAngle = 158;
			_cameraController.tiltAngle = -2;

			_view.forceMouseMove = true;

			// To trace picking positions.
			_locationTracer = new Mesh( new SphereGeometry( 5 ), new ColorMaterial( 0x00FF00 ) );
			_locationTracer.mouseEnabled = _locationTracer.mouseChildren = false;
			_locationTracer.visible = false;
			_view.scene.addChild( _locationTracer );

			// To trace picking normals.
			_normalTracer = new SegmentSet();
			_normalTracer.mouseEnabled = _normalTracer.mouseChildren = false;
			var lineSegment:LineSegment = new LineSegment( new Vector3D(), new Vector3D(), 0xFFFFFF, 0xFFFFFF, 3 );
			_normalTracer.addSegment( lineSegment );
			_normalTracer.visible = false;
			_view.scene.addChild( _normalTracer );

			// uv _painter
			_painter = new Sprite();
			_painter.graphics.beginFill( 0x0000FF );
			_painter.graphics.drawCircle( 0, 0, 50 );
			_painter.graphics.endFill();

			// Load head model.
			var parser:OBJParser = new OBJParser( 30 );
			parser.addEventListener( AssetEvent.ASSET_COMPLETE, onAssetComplete );
			parser.parseAsync( new HeadAsset() );
		}

		private function onAssetComplete( event:AssetEvent ):void {
			if( event.asset.assetType == AssetType.MESH ) {
				initializeModel( event.asset as Mesh );
			}
		}

		private function initializeModel( model:Mesh ):void {

			// Apply materials.
			var bmd:BitmapData = new BitmapData( TEXTURE_SIZE, TEXTURE_SIZE, false, 0xFF0000 );
			bmd.perlinNoise( 50, 50, 8, 1, false, true, 7, true );
			_bitmap = new Bitmap( bmd );
			_bitmap.scaleX = _bitmap.scaleY = 0.1;
			addChildAt( _bitmap, 1 );
			_texture = new BitmapTexture( bmd );
			_material = new TextureMaterial( _texture );
			_material.lightPicker = _lightPicker;
			model.material = _material;

			// Set up interactivity.
			model.pickingCollider = PickingColliderType.PB_BEST_HIT;

			// Apply interactivity.
			model.mouseEnabled = model.mouseChildren = model.shaderPickingDetails = true;
			model.addEventListener( MouseEvent3D.MOUSE_MOVE, onMeshMouseMove );
			model.addEventListener( MouseEvent3D.MOUSE_DOWN, onMeshMouseDown );
			model.addEventListener( MouseEvent3D.MOUSE_UP, onMeshMouseUp );
			model.addEventListener( MouseEvent3D.MOUSE_OVER, onMeshMouseOver );
			model.addEventListener( MouseEvent3D.MOUSE_OUT, onMeshMouseOut );
			stage.addEventListener( MouseEvent.MOUSE_UP, onStageMouseUp )

			_view.scene.addChild( model );
		}

		private function onMeshMouseMove( event:MouseEvent3D ):void {
			if( _painting ) {
				var uv:Point = event.uv;
				var bmd:BitmapData = _bitmap.bitmapData;
				var x:uint = uint( TEXTURE_SIZE * uv.x );
				var y:uint = uint( TEXTURE_SIZE * uv.y );
				var matrix:Matrix = new Matrix();
				matrix.translate( x, y );
				bmd.draw( _painter, matrix );
				_texture.invalidateContent();
			}
			// Update tracers.
			_locationTracer.position = event.scenePosition;
			_normalTracer.position = _locationTracer.position;
			var normal:Vector3D = event.sceneNormal.clone();
			normal.scaleBy( 25 );
			var lineSegment:LineSegment = _normalTracer.getSegment( 0 ) as LineSegment;
			lineSegment.end = normal.clone();
		}

		private function onMeshMouseDown( event:MouseEvent3D ):void {
			_painting = true;
		}

		private function onMeshMouseUp( event:MouseEvent3D ):void {
			_painting = false;
		}

		private function onMeshMouseOver( event:MouseEvent3D ):void {
			_locationTracer.visible = _normalTracer.visible = true;
		}

		private function onMeshMouseOut( event:MouseEvent3D ):void {
			_locationTracer.visible = _normalTracer.visible = false;
			_painting = false;
		}

		private function onStageMouseUp( event:MouseEvent ):void {
			_painting = false;
		}
	}
}
