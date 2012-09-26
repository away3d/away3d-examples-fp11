package away3d.primitives
{
	import away3d.core.base.CompactSubGeometry;

	import flash.geom.Matrix3D;

	import flash.geom.Point;

	import flash.geom.Vector3D;

	public class FractalTreeRound extends PrimitiveBase
	{
	    private var _rawData:Vector.<Number>;
	    private var _rawIndices:Vector.<uint>;
	    private var _size:Number;
	    private var _off:uint;
	    private var _level:uint;
	    private var _v0:Vector3D, _v1:Vector3D, _v2:Vector3D, _v3:Vector3D;
	    private var _d0:Vector3D, _d1:Vector3D;
	    private var _mid:Vector3D, _boxNorm:Vector3D, _triNorm:Vector3D;
	    private var _sideLength:Number;
	    private var _firstBaseToHeightFactor:Number;
	    private var _baseToHeightFactor:Number;
	    private var _baseToTriangleHeightFactorRange:Point;
	    private var _triangleOffsetFactorRange:Point;
	    private var _leafPositions:Vector.<Number>;
	    private var _built:Boolean;
	
	    public function FractalTreeRound(width:Number, height:Number, stretching:Number,
	                                     minAperture:Number, maxAperture:Number,
	                                     minTwist:Number, maxTwist:Number,
	                                     level:uint)
	    {
	        super();
	
	        _size = width;
	        _level = level;
	
	        _firstBaseToHeightFactor = height;
	        _baseToHeightFactor = stretching;
	        _baseToTriangleHeightFactorRange = new Point(minAperture, maxAperture);
	        _triangleOffsetFactorRange = new Point(minTwist, maxTwist);
	
	        _v0 = new Vector3D();
	        _v1 = new Vector3D();
	        _v2 = new Vector3D();
	        _v3 = new Vector3D();
	        _d0 = new Vector3D();
	        _d1 = new Vector3D();
	        _boxNorm = new Vector3D();
	
	        _leafPositions = new Vector.<Number>();
	
	        buildGeometry(CompactSubGeometry(subGeometries[0]));
	    }
	
	    override protected function buildGeometry(target:CompactSubGeometry):void
	    {
	        if(_built)
	            return;
	
	        _built = true;
	
	        // Init raw buffers.
	        _rawData = new Vector.<Number>();
	        _rawIndices = new Vector.<uint>();

	        // Start recursive method.
	        buildOpenBox(Vector.<Number>([-_size/2, 0, -_size/2,
	                                       _size/2, 0, -_size/2,
	                                       _size/2, 0,  _size/2,
	                                      -_size/2, 0,  _size/2]), _firstBaseToHeightFactor);
	        step(1);
	
	        // Report geom data.
	        target.updateData(_rawData);
	        target.updateIndexData(_rawIndices);
	    }
	
	    private function step(level:uint):void
	    {
	        // Obtain the last set of quads (make sure rotation occurs).
	        var last:Vector.<Number> = _rawData.slice(_rawData.length - 78);
	        var front:Vector.<Number> = Vector.<Number>([last[13], last[14], last[15],
	                                                     last[52], last[53], last[54],
	                                                     last[65], last[66], last[67],
	                                                     last[0], last[1], last[2]]);
	        var back:Vector.<Number> = Vector.<Number>([last[52], last[53], last[54],
	                                                    last[26], last[27], last[28],
	                                                    last[39], last[40], last[41],
	                                                    last[65], last[66], last[67]]);
	
	        // If level reached, remember position and end process.
	        if(level > _level)
	        {
	            // Store the position of the leaves.
	            var leaf0:Vector3D = new Vector3D(front[0], front[1], front[2]);
	            var leaf1:Vector3D = new Vector3D(back[3], back[4], back[5]);
	            _leafPositions.push(leaf0.x, leaf0.y, leaf0.z, leaf1.x, leaf1.y, leaf1.z);
	
	            return;
	        }
	
	        // Recurse.
	        buildOpenBox(front);
	        step(level + 1);
	        buildOpenBox(back);
	        step(level + 1);
	    }
	
	    // A box consists of a cube without top and bottom with
	    // 2 triangles instead at the top.
	    private function buildOpenBox(vertices:Vector.<Number>, forceBaseToHeightFactor:Number = -1):void
	    {
			// Set indices.
			_rawIndices.push(_off + 0, _off + 4, _off + 1, _off + 4, _off + 5, _off + 1); // Front.
			_rawIndices.push(_off + 2, _off + 6, _off + 3, _off + 6, _off + 7, _off + 3); // Back.
			_rawIndices.push(_off + 1, _off + 5, _off + 2, _off + 5, _off + 6, _off + 2); // Right.
			_rawIndices.push(_off + 3, _off + 7, _off + 0, _off + 7, _off + 4, _off + 0); // Left.
			_rawIndices.push(_off + 5, _off + 8, _off + 6, _off + 7, _off + 9, _off + 4); // Tris.
			_off += 10;

	        // Pre-calculate values for vertices and normals.
	        _v0.x = vertices[0];
	        _v0.y = vertices[1];
	        _v0.z = vertices[2];
	        _v1.x = vertices[3];
	        _v1.y = vertices[4];
	        _v1.z = vertices[5];
	        _v2.x = vertices[6];
	        _v2.y = vertices[7];
	        _v2.z = vertices[8];
	        _v3.x = vertices[9];
	        _v3.y = vertices[10];
	        _v3.z = vertices[11];
	        _d0 = _v0.subtract(_v1);
	        _d1 = _v0.subtract(_v3);
	        _mid = _d1.clone();
	        _mid.scaleBy(-rand(_triangleOffsetFactorRange.x, _triangleOffsetFactorRange.y));
	        _boxNorm = _d1.crossProduct(_d0);
	        _boxNorm.normalize();
	        _triNorm = _boxNorm.clone();
	        _sideLength = _d0.length;
	        _boxNorm.scaleBy((forceBaseToHeightFactor > 0 ? forceBaseToHeightFactor : _baseToHeightFactor)*_sideLength);
	        _triNorm.scaleBy(rand(_baseToTriangleHeightFactorRange.x, _baseToTriangleHeightFactorRange.y)*_sideLength);

			// Calculate radially outward pointing normals.
			var norm0:Vector3D = _v0.subtract(_v2);
			var norm1:Vector3D = _v1.subtract(_v3);
			var norm2:Vector3D = _v2.subtract(_v0);
			var norm3:Vector3D = _v3.subtract(_v1);
			norm0.normalize();
			norm1.normalize();
			norm2.normalize();
			norm3.normalize();
			var normFront:Vector3D = _d1.clone();
			normFront.normalize();
			var normBack:Vector3D = normFront.clone();
			normBack.negate();
			var normLeft:Vector3D = _d0.clone();
			normLeft.normalize();
			var normRight:Vector3D = normLeft.clone();
			normRight.negate();
			// Set tangents.
			var rotate:Matrix3D = new Matrix3D();
			var tangTop:Vector3D = normRight.crossProduct(normFront);
			tangTop.normalize();
			rotate.appendRotation(45, tangTop);
			var tang0 : Vector3D = rotate.transformVector(norm0);
			var tang1 : Vector3D = rotate.transformVector(norm1);
			var tang2 : Vector3D = rotate.transformVector(norm2);
			var tang3 : Vector3D = rotate.transformVector(norm3);
			var tangRight : Vector3D = rotate.transformVector(normRight);
			var tangLeft : Vector3D = rotate.transformVector(normLeft);

	        _rawData.push(_v0.x, _v0.y, _v0.z, norm0.x, norm0.y, norm0.z, tang0.x, tang0.y, tang0.z, 0, 1, 0, 1);	// flb (front left bottom)
			_rawData.push(_v1.x, _v1.y, _v1.z, norm1.x, norm1.y, norm1.z, tang1.x, tang1.y, tang1.z, 1, 1, 1, 1); // frb
			_rawData.push(_v2.x, _v2.y, _v2.z, norm2.x, norm2.y, norm2.z, tang2.x, tang2.y, tang2.z, 0, 1, 0, 1); // brb
			_rawData.push(_v3.x, _v3.y, _v3.z, norm3.x, norm3.y, norm3.z, tang3.x, tang3.y, tang3.z, 1, 1, 1, 1); // blb
			_rawData.push(_v0.x + _boxNorm.x, _v0.y + _boxNorm.y, _v0.z + _boxNorm.z, norm0.x, norm0.y, norm0.z, tang0.x, tang0.y, tang0.z, 0, 0, 0, 0); // flt
			_rawData.push(_v1.x + _boxNorm.x, _v1.y + _boxNorm.y, _v1.z + _boxNorm.z, norm1.x, norm1.y, norm1.z, tang1.x, tang1.y, tang1.z, 1, 0, 1, 0); // frt
			_rawData.push(_v2.x + _boxNorm.x, _v2.y + _boxNorm.y, _v2.z + _boxNorm.z, norm2.x, norm2.y, norm2.z, tang2.x, tang2.y, tang2.z, 0, 0, 0, 0); // brt
			_rawData.push(_v3.x + _boxNorm.x, _v3.y + _boxNorm.y, _v3.z + _boxNorm.z, norm3.x, norm3.y, norm3.z, tang3.x, tang3.y, tang3.z, 1, 0, 1, 0); // blt
			_rawData.push(_v1.x + _boxNorm.x + _mid.x + _triNorm.x, _v1.y + _boxNorm.y + _mid.y + _triNorm.y, _v1.z + _boxNorm.z + _mid.z + _triNorm.z, normRight.x, normRight.y, normRight.z, tangRight.x, tangRight.y, tangRight.z, 0.5, 0.5, 0.5, 0.5); // tri front
			_rawData.push(_v0.x + _boxNorm.x + _mid.x + _triNorm.x, _v0.y + _boxNorm.y + _mid.y + _triNorm.y, _v0.z + _boxNorm.z + _mid.z + _triNorm.z, normLeft.x, normLeft.y, normLeft.z, tangLeft.x, tangLeft.y, tangLeft.z, 0.5, 0.5, 0.5, 0.5); // tri back
	    }
	
	    override protected function buildUVs(target:CompactSubGeometry):void
	    {
			buildGeometry(target);
	    }
	
	    private function rand(min:Number, max:Number):Number
	    {
	        return (max - min)*Math.random() + min;
	    }
	
	    public function get leafPositions():Vector.<Number>
	    {
	        return _leafPositions;
	    }
	}
}