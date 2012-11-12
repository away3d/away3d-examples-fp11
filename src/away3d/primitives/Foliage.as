package away3d.primitives
{

	import away3d.core.base.*;
	import away3d.utils.GeometryUtil;

	import flash.geom.*;

	public class Foliage extends PrimitiveBase
	{
	    private var _rawVertices:Vector.<Number>;
	    private var _rawNormals:Vector.<Number>;
	    private var _rawIndices:Vector.<uint>;
	    private var _rawUvs:Vector.<Number>;
	    private var _rawTangents:Vector.<Number>;
		private var _bufferData:Vector.<Number>;
	
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

	    override protected function buildGeometry( target:CompactSubGeometry ):void
	    {
	        // Init raw buffers.
	        _rawVertices = new Vector.<Number>();
	        _rawNormals = new Vector.<Number>();
	        _rawIndices = new Vector.<uint>();
	        _rawUvs = new Vector.<Number>();
	        _rawTangents = new Vector.<Number>();
			_bufferData = new Vector.<Number>();
	
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
	        target.updateIndexData(_rawIndices);
	    }
	
	    private function createRandomDoubleSidedTriangleAt(p0:Vector3D, radius:Number):void
	    {
	        // Calculate vertices.
	//        var p1:Vector3D = sphericalToCartesian(new Vector3D(2*_pi*Math.random(), 2*_pi*Math.random(), radius));
	//        var p2:Vector3D = sphericalToCartesian(new Vector3D(2*_pi*Math.random(), 2*_pi*Math.random(), radius));
	        var p1:Vector3D = new Vector3D(rand(-radius, radius), rand(-radius, radius), rand(-radius, radius));
	        var p2:Vector3D = new Vector3D(rand(-radius, radius), rand(-radius, radius), rand(-radius, radius));
	        var norm:Vector3D = p1.crossProduct(p2);
	        norm.normalize();
	
	        // Set vertices.
	        p1 = p0.add(p1);
	        p2 = p0.add(p2);
	        _rawVertices.push(p0.x, p0.y, p0.z);
	        _rawVertices.push(p1.x, p1.y, p1.z);
	        _rawVertices.push(p2.x, p2.y, p2.z);
	        _rawVertices.push(p0.x, p0.y, p0.z);
	        _rawVertices.push(p1.x, p1.y, p1.z);
	        _rawVertices.push(p2.x, p2.y, p2.z);
	
	        // Set indices.
	        _rawIndices.push(_off, _off + 1, _off + 2);
	        _rawIndices.push(_off + 5, _off + 4, _off + 3);
	        _off += 6;
	
	        // Set normals.
	        _rawNormals.push(norm.x, norm.y, norm.z);
	        _rawNormals.push(norm.x, norm.y, norm.z);
	        _rawNormals.push(norm.x, norm.y, norm.z);
	        norm.negate();
	        _rawNormals.push(norm.x, norm.y, norm.z);
	        _rawNormals.push(norm.x, norm.y, norm.z);
	        _rawNormals.push(norm.x, norm.y, norm.z);
	
	        // Set Tangents.
	        _rawTangents.push(0, 0, 0);
	        _rawTangents.push(0, 0, 0);
	        _rawTangents.push(0, 0, 0);
	        _rawTangents.push(0, 0, 0);
	        _rawTangents.push(0, 0, 0);
	        _rawTangents.push(0, 0, 0);
	
	        // Set UVs.
	        _rawUvs.push(0, 0, 1, 0, 1, 1);
	        _rawUvs.push(0, 0, 1, 0, 1, 1);
	    }
	
	    private function sphericalToCartesian(sphericalCoords:Vector3D):Vector3D
	    {
	        var cartesianCoords:Vector3D = new Vector3D();
	        cartesianCoords.x = sphericalCoords.z*Math.sin(sphericalCoords.x)*Math.sin(sphericalCoords.y);
	        cartesianCoords.y = sphericalCoords.z*Math.cos(sphericalCoords.y);
	        cartesianCoords.z = sphericalCoords.z*Math.cos(sphericalCoords.x)*Math.sin(sphericalCoords.y);
	        return cartesianCoords;
	    }
	
	    override protected function buildUVs( target:CompactSubGeometry ):void
	    {
			target.updateData( GeometryUtil.interleaveBuffers( _rawVertices.length / 3, _rawVertices, _rawNormals, _rawTangents, _rawUvs ) );
	    }

	    private function rand(min:Number, max:Number):Number
	    {
	        return (max - min)*Math.random() + min;
	    }
	}
}