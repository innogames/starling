package starling.utils;

#if gl_stats
import openfl._internal.renderer.opengl.stats.DrawCallContext;
import openfl._internal.renderer.opengl.stats.GLStats;
#end

import openfl._internal.stage3D.opengl.GLContext3D;
import openfl._internal.stage3D.GLUtils;
import openfl.display.OpenGLRenderer;
import flash.display3D.IndexBuffer3D;
import starling.display.QuadBatch;
import flash.display3D.Context3D;
import lime.graphics.opengl.GLVertexArrayObject;


@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.IndexBuffer3D)
@:access(openfl.display3D.VertexBuffer3D)
@:access(openfl.display.OpenGLRenderer)
@:access(starling.display.QuadBatch)
@:access(openfl._internal.stage3D.opengl.GLContext3D)
@:access(openfl.display3D.Program3D)


class QuadBatchVAOHelper {
	
	
	public static function createVAO (context:Context3D):GLVertexArrayObject {
		
		#if vertex_array_object 
		var renderer:OpenGLRenderer = cast context.__renderer;
		var vaoContext = renderer.__vaoContext;
		
		if (vaoContext != null) {
		
			return vaoContext.createVertexArray ();
			
		}
		#end
		
		return null;
		
	}
	
	
	public static function disposeVAO (quadBatch:QuadBatch, context:Context3D):Void {
		
		#if vertex_array_object
		var renderer:OpenGLRenderer = cast context.__renderer;
		var vaoContext = renderer.__vaoContext;
		
		if (vaoContext != null && quadBatch.mVao != null) {
		
			vaoContext.deleteVertexArray (quadBatch.mVao);
			
		}
		#end
		
	}
	
	
	#if vertex_array_object
	private static inline function __drawTriangles (context:Context3D, indexBuffer:IndexBuffer3D, firstIndex:Int = 0, numTriangles:Int = -1):Void {
		
		if (context.__program == null) {
			
			return;
			
		}
		
		var renderer:OpenGLRenderer = cast context.__renderer;
		
		var gl = renderer.gl;
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
	#end
	
	
	public static inline function renderQuadBatch (quadBatch:QuadBatch, context:Context3D):Bool {
		
		#if vertex_array_object
		var renderer:OpenGLRenderer = cast context.__renderer;
		var gl = renderer.gl;
		var vaoContext = renderer.__vaoContext;
		
		if (vaoContext != null) {
			
			if (!quadBatch.mSyncRequired) vaoContext.bindVertexArray (quadBatch.mVao);
			 
			if (quadBatch.mTexture != null) {
				
				context.setTextureAt (0, quadBatch.mTexture.base);
				
			}
			
			__drawTriangles (context, quadBatch.mIndexBuffer, 0, quadBatch.mNumQuads * 2);
			
			vaoContext.bindVertexArray (null);
			
			return true;
			
		}
		#end
		
		return false;
		
	}
	
	
	public static inline function syncVAO (quadBatch:QuadBatch, context:Context3D):Void {
		
		#if vertex_array_object
		var renderer:OpenGLRenderer = cast context.__renderer;
		var gl = renderer.gl;
		var vaoContext = renderer.__vaoContext;
		
		if (vaoContext != null) {
			
			vaoContext.bindVertexArray (quadBatch.mVao);
			
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
		#end
		
	}
	
	
}
