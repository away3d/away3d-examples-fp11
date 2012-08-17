package utils
{
    import away3d.textures.*;
	
    import flash.display.*;
    import flash.filters.*;

    
    public class BitmapFilterEffects extends Sprite
	{
        [Embed(source="/../pb/Sharpen.pbj",mimeType="application/octet-stream")]
        public static var SharpenClass:Class;
        [Embed(source="/../pb/NormalMap.pbj",mimeType="application/octet-stream")]
        public static var NormalMapClass:Class;
        [Embed(source="/../pb/Outline.pbj",mimeType="application/octet-stream")]
        public static var OutlineClass:Class;
        
		private static var _bitmap:Bitmap = new Bitmap();
		
		//sharpen vars
		private static var _sharpenShader:Shader = new Shader(new SharpenClass());
		private static var _sharpenFilters:Array = [new ShaderFilter(_sharpenShader)];
		
		//normal map vars
		private static var _normalMapShader:Shader = new Shader(new NormalMapClass());
		private static var _normalMapFilters:Array = [new ShaderFilter(_normalMapShader)];
		
		//outline vars
		private static var _outlineShader:Shader = new Shader(new OutlineClass());
		private static var _outlineFilters:Array = [new ShaderFilter(_outlineShader)];
        
		static public function sharpen(sourceBitmap:BitmapData, amount:Number = 20, radius:Number = 0.1):BitmapData
		{
			var returnBitmap:BitmapData = new BitmapData(sourceBitmap.width, sourceBitmap.height, sourceBitmap.transparent, 0x0);
			
            _sharpenShader.data.amount.value = [amount];
            _sharpenShader.data.radius.value = [radius];
			
			_bitmap.bitmapData = sourceBitmap;
            _bitmap.filters = _sharpenFilters;
			returnBitmap.draw(_bitmap);
			
			return returnBitmap;
		}
		
		static public function normalMap(sourceBitmap:BitmapData, amount:Number = 10, softSobel:Number = 1, redMultiplier:Number = -1, greeMultiplier:Number = -1):BitmapData
		{
			var returnBitmap:BitmapData = new BitmapData(sourceBitmap.width, sourceBitmap.height, sourceBitmap.transparent, 0x0);
			
            _normalMapShader.data.amount.value = [amount]; //0 to 5
            _normalMapShader.data.soft_sobel.value = [softSobel]; //int 0 or 1
            _normalMapShader.data.invert_red.value = [redMultiplier]; //-1 to 1
            _normalMapShader.data.invert_green.value = [greeMultiplier]; //-1 to 1
            
			_bitmap.bitmapData = sourceBitmap;
            _bitmap.filters = _normalMapFilters;
			returnBitmap.draw(_bitmap);
			
			return returnBitmap;
		}
		
		static public function outline(sourceBitmap:BitmapData, differenceMin:Number = 0.15, differenceMax:Number = 1, outputColor:uint = 0xFFFFFF, backgroundColor:uint = 0x000000):BitmapData
		{
			var returnBitmap:BitmapData = new BitmapData(sourceBitmap.width, sourceBitmap.height, sourceBitmap.transparent, 0x0);
			
            _outlineShader.data.difference.value = [1, 0.15];
            _outlineShader.data.color.value = [((outputColor & 0xFF0000) >> 16)/255, ((outputColor & 0x00FF00) >> 8)/255, (outputColor & 0x0000FF)/255, 1];
            _outlineShader.data.bgcolor.value = [((backgroundColor & 0xFF0000) >> 16)/255, ((backgroundColor & 0x00FF00) >> 8)/255, (backgroundColor & 0x0000FF)/255, 1];
            
			_bitmap.bitmapData = sourceBitmap;
            _bitmap.filters = _outlineFilters;
			returnBitmap.draw(_bitmap);
			
			return returnBitmap;
		}
	}
}