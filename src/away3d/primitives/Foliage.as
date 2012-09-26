package away3d.primitives
{
	import away3d.core.base.CompactSubGeometry;
	import away3d.core.base.CompactSubGeometry;

	import flash.geom.Vector3D;

	public class Foliage extends PrimitiveBase
	{
	    private var _rawData:Vector.<Number>;
	    private var _rawIndices:Vector.<uint>;

	    private var _off:uint;
	    private var _leafSize:Number;
	    private var _radius:Number;
	    private var _leafCount:uint;
	    private var _positions:Vector.<Number>;
	
	    private var _pi:Number = Math.PI;
	
	    public function Foliage(positions:Vector.<Number>, leafCount:uint, leafSize:Number, radius:Number)
	    {
	        super();
	        _leafCount = leafCount;
	        _leafSize = leafSize;
	        _radius = radius;
	        _positions = positions;
	    }
	
	    override protected function buildGeometry(target:CompactSubGeometry):void
	    {
	        // Init raw buffers.
	        _rawData = new Vector.<Number>();
	        _rawIndices = new Vector.<uint>();

	        // Create clusters.
	        var i:uint, j:uint, index:uint;
	        var loop:uint = _positions.length/3;
	        var subloop:uint = _leafCount;
	        var posx:Number, posy:Number, posz:Number;
	        for(i = 0; i < loop; ++i)
	        {
	            index = 3*i;
	            posx = _positions[index];
	            posy = _positions[index + 1];
	            posz = _positions[index + 2];
	            for(j = 0; j < subloop; ++j)
	            {
	                var leafPoint:Vector3D = sphericalToCartesian(new Vector3D(_pi*Math.random(), _pi*Math.random(), _radius));
	                leafPoint.x += posx;
	                leafPoint.y += posy;
	                leafPoint.z += posz;
	                createRandomDoubleSidedTriangleAt(leafPoint, _leafSize);
	            }
	        }
	
	        // Report geom data.
	        target.updateData(_rawData);
	        target.updateIndexData(_rawIndices);
	    }
	
	    private function createRandomDoubleSidedTriangleAt(p0:Vector3D, radius:Number):void
	    {
	        var p1:Vector3D = new Vector3D(rand(-radius, radius), rand(-radius, radius), rand(-radius, radius));
	        var p2:Vector3D = new Vector3D(rand(-radius, radius), rand(-radius, radius), rand(-radius, radius));
	        var norm:Vector3D = p1.crossProduct(p2);
	        norm.normalize();

			// Set indices.
			_rawIndices.push(_off, _off + 1, _off + 2);
			_rawIndices.push(_off + 5, _off + 4, _off + 3);
			_off += 6;

	        p1 = p0.add(p1);
	        p2 = p0.add(p2);
	        _rawData.push(p0.x, p0.y, p0.z, norm.x, norm.y, norm.z, 0, 0, 0, 0, 0, 0, 0);
			_rawData.push(p1.x, p1.y, p1.z, norm.x, norm.y, norm.z, 0, 0, 0, 1, 0, 1, 0);
			_rawData.push(p2.x, p2.y, p2.z, norm.x, norm.y, norm.z, 0, 0, 0, 1, 1, 1, 1);
			norm.negate();
			_rawData.push(p0.x, p0.y, p0.z, norm.x, norm.y, norm.z, 0, 0, 0, 0, 0, 0, 0);
			_rawData.push(p1.x, p1.y, p1.z, norm.x, norm.y, norm.z, 0, 0, 0, 1, 0, 1, 0);
			_rawData.push(p2.x, p2.y, p2.z, norm.x, norm.y, norm.z, 0, 0, 0, 1, 1, 1, 1);
	    }
	
	    private function sphericalToCartesian(sphericalCoords:Vector3D):Vector3D
	    {
	        var cartesianCoords:Vector3D = new Vector3D();
	        cartesianCoords.x = sphericalCoords.z*Math.sin(sphericalCoords.x)*Math.sin(sphericalCoords.y);
	        cartesianCoords.y = sphericalCoords.z*Math.cos(sphericalCoords.y);
	        cartesianCoords.z = sphericalCoords.z*Math.cos(sphericalCoords.x)*Math.sin(sphericalCoords.y);
	        return cartesianCoords;
	    }
	
	    override protected function buildUVs(target:CompactSubGeometry):void
	    {
			if (_geomDirty) {
				buildGeometry(target);
				_geomDirty = false;
			}
	    }
	
	    private function rand(min:Number, max:Number):Number
	    {
	        return (max - min)*Math.random() + min;
	    }
	}
}