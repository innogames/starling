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

import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import starling.core.RenderSupport;
import starling.utils.MatrixUtil;
import starling.utils.RectangleUtil;
import starling.utils.Max;

/** A Sprite is the most lightweight, non-abstract container class.
 *  <p>Use it as a simple means of grouping objects together in one coordinate system, or
 *  as the base class for custom display objects.</p>
 *
 *  <strong>Clipping Rectangle</strong>
 * 
 *  <p>The <code>clipRect</code> property allows you to clip the visible area of the sprite
 *  to a rectangular region. Only pixels inside the rectangle will be displayed. This is a very
 *  fast way to mask objects. However, there is one limitation: the <code>clipRect</code>
 *  only works with stage-aligned rectangles, i.e. you cannot rotate or skew the rectangle.
 *  This limitation is inherited from the underlying "scissoring" technique that is used
 *  internally.</p>
 *  
 *  @see DisplayObject
 *  @see DisplayObjectContainer
 */
class Sprite extends DisplayObjectContainer
{
    private var mClipRect:Rectangle;
    
    /** Helper objects. */
    private static var sHelperMatrix:Matrix = new Matrix();
    private static var sHelperPoint:Point = new Point();
    private static var sHelperRect:Rectangle = new Rectangle();
    
    /** Creates an empty sprite. */
    public function new()
    {
        super();
    }

    /**
    * @deprecated 
	**/
    public function flatten(ignoreChildOrder:Bool=false):Void
    {
    }
    
    /**
    * @deprecated 
	**/
    public function unflatten():Void
    {
    }
    
    /**
    * @deprecated 
	**/
    public var isFlattened(get, never):Bool;
    private function get_isFlattened():Bool 
    { 
        return false;
    }
    
    /** The object's clipping rectangle in its local coordinate system.
     * Only pixels within that rectangle will be drawn. 
     * <strong>Note:</strong> clipping rectangles are axis aligned with the screen, so they
     * will not be rotated or skewed if the Sprite is. */
    public var clipRect(get, set):Rectangle;
    private function get_clipRect():Rectangle { return mClipRect; }
    private function set_clipRect(value:Rectangle):Rectangle 
    {
        if (mClipRect != null && value != null) mClipRect.copyFrom(value);
        else mClipRect = (value != null ? value.clone() : null);
        return value;
    }

    /** Returns the bounds of the container's clipping rectangle in the given coordinate space,
     * or null if the sprite does not have one. */
    public function getClipRect(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
    {
        if (mClipRect == null) return null;
        if (resultRect == null) resultRect = new Rectangle();
        
        var x:Float = 0.0, y:Float = 0.0;
        var minX:Float =  Max.MAX_VALUE;
        var maxX:Float = -Max.MAX_VALUE;
        var minY:Float =  Max.MAX_VALUE;
        var maxY:Float = -Max.MAX_VALUE;
        var transMatrix:Matrix = getTransformationMatrix(targetSpace, sHelperMatrix);
        
        for (i in 0...4)
        {
            switch(i)
            {
                case 0: x = mClipRect.left;  y = mClipRect.top;
                case 1: x = mClipRect.left;  y = mClipRect.bottom;
                case 2: x = mClipRect.right; y = mClipRect.top;
                case 3: x = mClipRect.right; y = mClipRect.bottom;
            }
            var transformedPoint:Point = MatrixUtil.transformCoords(transMatrix, x, y, sHelperPoint);
            
            if (minX > transformedPoint.x) minX = transformedPoint.x;
            if (maxX < transformedPoint.x) maxX = transformedPoint.x;
            if (minY > transformedPoint.y) minY = transformedPoint.y;
            if (maxY < transformedPoint.y) maxY = transformedPoint.y;
        }
        
        resultRect.setTo(minX, minY, maxX-minX, maxY-minY);
        return resultRect;
    }
    
    /** @inheritDoc */ 
    public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
    {
        var bounds:Rectangle = super.getBounds(targetSpace, resultRect);
        
        // if we have a scissor rect, intersect it with our bounds
        if (mClipRect != null)
            RectangleUtil.intersect(bounds, getClipRect(targetSpace, sHelperRect), 
                                    bounds);
        
        return bounds;
    }
    
    /** @inheritDoc */
    public override function hitTest(localPoint:Point, forTouch:Bool=false):DisplayObject
    {
        if (mClipRect != null && !mClipRect.containsPoint(localPoint))
            return null;
        else
            return super.hitTest(localPoint, forTouch);
    }
    
    /** @inheritDoc */
    public override function render(support:RenderSupport, parentAlpha:Float):Void
    {
        if (mClipRect != null)
        {
            var clipRect:Rectangle = support.pushClipRect(getClipRect(stage, sHelperRect));
            if (clipRect.isEmpty())
            {
                // empty clipping bounds - no need to render children.
                support.popClipRect();
                return;
            }
        }
        
       super.render(support, parentAlpha);
        
        if (mClipRect != null)
            support.popClipRect();
    }
}