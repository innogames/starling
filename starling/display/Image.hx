// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display;

import flash.display.Bitmap;
import flash.errors.ArgumentError;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import openfl._internal.renderer.opengl.batcher.Quad as BatcherQuad;
import openfl._internal.renderer.opengl.batcher.QuadTextureData as BatcherQuadTextureData;
import openfl._internal.renderer.opengl.batcher.BlendMode as BatcherBlendMode;

import starling.core.RenderSupport;
import starling.textures.Texture;
import starling.textures.TextureSmoothing;
import starling.utils.VertexData;
import starling.core.Starling;

/** An Image is a quad with a texture mapped onto it.
 *  
 *  <p>The Image class is the Starling equivalent of Flash's Bitmap class. Instead of 
 *  BitmapData, Starling uses textures to represent the pixels of an image. To display a 
 *  texture, you have to map it onto a quad - and that's what the Image class is for.</p>
 *  
 *  <p>As "Image" inherits from "Quad", you can give it a color. For each pixel, the resulting  
 *  color will be the result of the multiplication of the color of the texture with the color of 
 *  the quad. That way, you can easily tint textures with a certain color. Furthermore, images 
 *  allow the manipulation of texture coordinates. That way, you can move a texture inside an 
 *  image without changing any vertex coordinates of the quad. You can also use this feature
 *  as a very efficient way to create a rectangular mask.</p> 
 *  
 *  @see starling.textures.Texture
 *  @see Quad
 */ 
class Image extends Quad
{
    private var mTexture:Texture;
    private var mSmoothing:String;
    
    private var mVertexDataCache:VertexData;
    private var mVertexDataCacheInvalid:Bool;
    
    // TODO: this should really be part of the texture, but let's make it step by step
    private var mBatcherQuadTextureData:BatcherQuadTextureData;
    
    /** Creates a quad with a texture mapped onto it. */
    public function new(texture:Texture)
    {
        if (texture != null)
        {
            var frame:Rectangle = texture.frame;
            var width:Float  = frame != null ? frame.width  : texture.width;
            var height:Float = frame != null ? frame.height : texture.height;
            var pma:Bool = texture.premultipliedAlpha;
            
            super(width, height, 0xffffff, pma);
            
            mVertexData.setTexCoords(0, 0.0, 0.0);
            mVertexData.setTexCoords(1, 1.0, 0.0);
            mVertexData.setTexCoords(2, 0.0, 1.0);
            mVertexData.setTexCoords(3, 1.0, 1.0);
            
            mTexture = texture;
            mSmoothing = TextureSmoothing.BILINEAR;
            mVertexDataCache = new VertexData(4, pma);
            mVertexDataCacheInvalid = true;
        }
        else
        {
            throw new ArgumentError("Texture cannot be null");
        }
    }
    
    /** Creates an Image with a texture that is created from a bitmap object. */
    public static function fromBitmap(bitmap:Bitmap, generateMipMaps:Bool=true, 
                                      scale:Float=1):Image
    {
        return new Image(Texture.fromBitmap(bitmap, generateMipMaps, false, scale));
    }
    
    /** @inheritDoc */
    private override function onVertexDataChanged():Void
    {
        mVertexDataCacheInvalid = true;
    }
    
    /** Readjusts the dimensions of the image according to its current texture. Call this method 
     * to synchronize image and texture size after assigning a texture with a different size.*/
    public function readjustSize():Void
    {
        var frame:Rectangle = texture.frame;
        var width:Float  = frame != null ? frame.width  : texture.width;
        var height:Float = frame != null ? frame.height : texture.height;
        
        mVertexData.setPosition(0, 0.0, 0.0);
        mVertexData.setPosition(1, width, 0.0);
        mVertexData.setPosition(2, 0.0, height);
        mVertexData.setPosition(3, width, height); 
        
        onVertexDataChanged();
    }
    
    /** Gets the texture coordinates of a vertex. Coordinates are in the range [0, 1]. 
     * If you pass a 'resultPoint', the result will be stored in this point instead of 
     * creating a new object.*/
    public function getTexCoords(vertexID:Int, resultPoint:Point=null):Point
    {
        if (resultPoint == null) resultPoint = new Point();
        mVertexData.getTexCoords(vertexID, resultPoint);
        return resultPoint;
    }
    
    /** Copies the raw vertex data to a VertexData instance.
     * The texture coordinates are already in the format required for rendering. */ 
    public override function copyVertexDataTo(targetData:VertexData, targetVertexID:Int=0):Void
    {
        copyVertexDataTransformedTo(targetData, targetVertexID, null);
    }
    
    /** Transforms the vertex positions of the raw vertex data by a certain matrix
     * and copies the result to another VertexData instance.
     * The texture coordinates are already in the format required for rendering. */
    public override function copyVertexDataTransformedTo(targetData:VertexData,
                                                         targetVertexID:Int=0,
                                                         matrix:Matrix=null):Void
    {
        if (mVertexDataCacheInvalid)
        {
            mVertexDataCacheInvalid = false;
            mVertexData.copyTo(mVertexDataCache);
            mTexture.adjustVertexData(mVertexDataCache, 0, 4);
            
            var point = tempPoint;
            var data = mVertexDataCache;
           
            data.getTexCoords(0, point);
            var u0 = point.x, v0 = point.y;
            
            data.getTexCoords(1, point);
            var u1 = point.x, v1 = point.y;
            
            data.getTexCoords(3, point);
            var u2 = point.x, v2 = point.y;
            
            data.getTexCoords(2, point);
            var u3 = point.x, v3 = point.y;

            var tex = @:privateAccess mTexture.base.__getTexture();
            mBatcherQuadTextureData = BatcherQuadTextureData.createRegion(tex,
                u0, v0,
                u1, v1,
                u2, v2,
                u3, v3
            );
        }
        
        mVertexDataCache.copyTransformedTo(targetData, targetVertexID, matrix, 0, 4);
    }
    
    /** The texture that is displayed on the quad. */
    public var texture(get, set):Texture;
    private function get_texture():Texture { return mTexture; }
    private function set_texture(value:Texture):Texture 
    { 
        if (value == null)
        {
            throw new ArgumentError("Texture cannot be null");
        }
        else if (value != mTexture)
        {
            mTexture = value;
            mVertexData.setPremultipliedAlpha(mTexture.premultipliedAlpha);
            mVertexDataCache.setPremultipliedAlpha(mTexture.premultipliedAlpha, false);
            onVertexDataChanged();
        }
        return value;
    }
    
    /** The smoothing filter that is used for the texture. 
    * @default bilinear
    * @see starling.textures.TextureSmoothing */ 
    public var smoothing(get, set):String;
    private function get_smoothing():String { return mSmoothing; }
    private function set_smoothing(value:String):String 
    {
        if (TextureSmoothing.isValid(value))
            mSmoothing = value;
        else
            throw new ArgumentError("Invalid smoothing mode: " + value);
        return value;
    }
    
    var batcherQuad = new BatcherQuad();
    static var tempVertexData = new VertexData(4);
    static var tempPoint = new Point();
    
    /** @inheritDoc */
    public override function render(support:RenderSupport, parentAlpha:Float):Void
    {
        var quad = batcherQuad;
        var data = tempVertexData;
        var point = tempPoint;

        copyVertexDataTransformedTo(data, 0, support.modelViewMatrix);
        
        var vertexData = quad.vertexData;

        data.getPosition(0, point);
        vertexData[0] = point.x;
        vertexData[1] = point.y;
        
        data.getPosition(1, point);
        vertexData[2] = point.x;
        vertexData[3] = point.y;
        
        data.getPosition(3, point);
        vertexData[4] = point.x;
        vertexData[5] = point.y;
        
        data.getPosition(2, point);
        vertexData[6] = point.x;
        vertexData[7] = point.y;

        quad.blendMode = toBatcherBlendMode(mBlendMode, mTexture.premultipliedAlpha);
        quad.smoothing = mSmoothing != TextureSmoothing.NONE;
        quad.texture = mBatcherQuadTextureData;
        quad.alpha = parentAlpha * mAlpha;
        
        support.batcher.render(quad);
        // support.batchQuad(this, parentAlpha, mTexture, mSmoothing);
    }

    static function toBatcherBlendMode(blendMode:String, premultipliedAlpha:Bool):BatcherBlendMode {
        return switch [premultipliedAlpha, blendMode] {
            case [true, BlendMode.NONE]: BatcherBlendMode.NONE;
            case [true, BlendMode.NORMAL]: BatcherBlendMode.NORMAL;
            case [true, BlendMode.ADD]: BatcherBlendMode.ADD;
            case [true, BlendMode.MULTIPLY]: BatcherBlendMode.MULTIPLY;
            case [true, BlendMode.SCREEN]: BatcherBlendMode.SCREEN;
            case [true, BlendMode.ERASE]: BatcherBlendMode.ERASE;
            case [true, BlendMode.MASK]: BatcherBlendMode.MASK;
            case [true, BlendMode.BELOW]: BatcherBlendMode.BELOW;
            case [true, _]: BatcherBlendMode.NORMAL;
            case [false, BlendMode.NONE]: BatcherBlendMode.NOPREMULT_NONE;
            case [false, BlendMode.NORMAL]: BatcherBlendMode.NOPREMULT_NORMAL;
            case [false, BlendMode.ADD]: BatcherBlendMode.NOPREMULT_ADD;
            case [false, BlendMode.MULTIPLY]: BatcherBlendMode.NOPREMULT_MULTIPLY;
            case [false, BlendMode.SCREEN]: BatcherBlendMode.NOPREMULT_SCREEN;
            case [false, BlendMode.ERASE]: BatcherBlendMode.NOPREMULT_ERASE;
            case [false, BlendMode.MASK]: BatcherBlendMode.NOPREMULT_MASK;
            case [false, BlendMode.BELOW]: BatcherBlendMode.NOPREMULT_BELOW;
            case [false, _]: BatcherBlendMode.NOPREMULT_NORMAL;
        }
    }
}