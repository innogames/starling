package starling.utils;

#if gl_stats
import openfl._internal.renderer.opengl.stats.DrawCallContext;
import openfl._internal.renderer.opengl.stats.GLStats;
#end

import openfl._internal.stage3D.opengl.GLContext3D;
import openfl._internal.stage3D.GLUtils;
import flash.display3D.IndexBuffer3D;
import starling.display.QuadBatch;
import flash.display3D.Context3D;
import openfl._internal.renderer.opengl.VertexArrayObjectUtils;
import lime.graphics.opengl.GLVertexArrayObject;


@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.IndexBuffer3D)
@:access(openfl.display3D.VertexBuffer3D)
@:access(starling.display.QuadBatch)
@:access(openfl._internal.stage3D.opengl.GLContext3D)
@:access(openfl.display3D.Program3D)


class QuadBatchVAOHelper {
	
	
	public static inline function createVAO (context:Context3D):GLVertexArrayObject {
		
		return VertexArrayObjectUtils.createVAO (context.__renderSession.gl);
		
	}
	
	
	public static inline function disposeVAO (quadBatch:QuadBatch, context:Context3D):Void {
		
		VertexArrayObjectUtils.deleteVAO (context.__renderSession.gl, quadBatch.mVao);
		
	}
	
	
	private static inline function __drawTriangles (context:Context3D, indexBuffer:IndexBuffer3D, firstIndex:Int = 0, numTriangles:Int = -1):Void {
		
		if (context.__program == null) {
			
			return;
			
		}
		
		var gl = context.__renderSession.gl;
		GLContext3D.context = context;
		GLContext3D.gl = gl;
		
		GLContext3D.__flushSamplerState ();
		context.__program.__flush ();
		
		var count = (numTriangles == -1) ? indexBuffer.__numIndices : (numTriangles * 3);
		
		gl.drawElements (gl.TRIANGLES, count, indexBuffer.__elementType, firstIndex);
		GLUtils.CheckGLError ();
		
		#if gl_stats
			GLStats.incrementDrawCall (DrawCallContext.STAGE3D);
		#end
		
	}
	
	
	public static function renderQuadBatch (quadBatch:QuadBatch, context:Context3D):Void {
		
		var gl = context.__renderSession.gl;
		
		if (VertexArrayObjectUtils.isVertexArrayObjectsSupported (gl)) {
			
			if (!quadBatch.mSyncRequired) VertexArrayObjectUtils.bindVAO (gl, quadBatch.mVao);
			 
			if (quadBatch.mTexture != null) {
				
				context.setTextureAt (0, quadBatch.mTexture.base);
				
			}
			
			__drawTriangles (context, quadBatch.mIndexBuffer, 0, quadBatch.mNumQuads * 2);
			
			VertexArrayObjectUtils.bindVAO (gl, null);
			
		}
		
	}
	
	
	public static inline function syncVAO (quadBatch:QuadBatch, context:Context3D):Void {
		
		var gl = context.__renderSession.gl;
		if (VertexArrayObjectUtils.isVertexArrayObjectsSupported (gl)) {
			
			VertexArrayObjectUtils.bindVAO (gl, quadBatch.mVao);
			
			gl.enableVertexAttribArray (0);
			gl.enableVertexAttribArray (1);
			gl.enableVertexAttribArray (2);
			
			gl.bindBuffer (gl.ARRAY_BUFFER, quadBatch.mVertexBuffer.__id);
			var stride = quadBatch.mVertexBuffer.__stride;
			gl.vertexAttribPointer (0, 2, gl.FLOAT, false, stride, VertexData.POSITION_OFFSET * 4);
			gl.vertexAttribPointer (1, 4, gl.FLOAT, false, stride, VertexData.COLOR_OFFSET * 4);
			gl.vertexAttribPointer (2, 2, gl.FLOAT, false, stride, VertexData.TEXCOORD_OFFSET * 4);
			gl.bindBuffer (gl.ELEMENT_ARRAY_BUFFER, quadBatch.mIndexBuffer.__id);
			
		}
		
	}
	
	
}
