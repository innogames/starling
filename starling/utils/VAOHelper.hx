package starling.utils;

import lime.graphics.opengl.GLVertexArrayObject;
import lime.graphics.opengl.GLContextType;
import lime.graphics.GLRenderContext;

class VAOHelper {
	
	private static var __vertexArrayObjectsSupported:Bool = false;
	private static var __vertexArrayObjectsExtension:Dynamic;
	
	
	public static inline function bindVAO (gl:GLRenderContext, vao:GLVertexArrayObject):Void {		
		if (__vertexArrayObjectsExtension != null) {
			__vertexArrayObjectsExtension.bindVertexArrayOES(vao);
		} else {
			gl.bindVertexArray(vao);
		}
	}
	
	
	public static inline function clear (gl:GLRenderContext):Void {
		if (!__vertexArrayObjectsSupported) return;
		bindVAO(gl, null);
	}
	
	public static inline function deleteVAO (gl:GLRenderContext, vao:GLVertexArrayObject):Void {
		if (!__vertexArrayObjectsSupported || vao == null) return;
		if (__vertexArrayObjectsExtension != null) {
			__vertexArrayObjectsExtension.deleteVertexArrayOES(vao);
		} else {
			gl.deleteVertexArray(vao);
		}
	}
	
	
	public static inline function createVAO (gl:GLRenderContext): GLVertexArrayObject {
		if (!__vertexArrayObjectsSupported) return null;
		if (__vertexArrayObjectsExtension != null) {
			return __vertexArrayObjectsExtension.createVertexArrayOES();
		} else {
			return gl.createVertexArray();
		}
	}
	
	public static function init (gl:GLRenderContext): Void {
		if (gl.type == GLContextType.WEBGL) { 
			if (gl.version == 2) {
				__vertexArrayObjectsSupported = true;
			} else if (gl.version == 1) {
				__vertexArrayObjectsExtension = gl.getExtension ("OES_vertex_array_object");
				__vertexArrayObjectsSupported = __vertexArrayObjectsExtension != null;
			}
		}
		
	}
	
	
}
