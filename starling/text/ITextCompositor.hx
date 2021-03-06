// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.text;

import starling.display.MeshBatch;

/** A text compositor arranges letters for Starling's TextField. */
interface ITextCompositor
{
    /** Draws the given text into a MeshBatch, using the supplied format and options. */
    public function fillMeshBatch(meshBatch:MeshBatch, width:Float, height:Float, text:String,
                           format:TextFormat, options:TextOptions=null):Void;

    /** Clears the MeshBatch (filled by the same class) and disposes any resources that
     *  are no longer needed. */
    public function clearMeshBatch(meshBatch:MeshBatch):Void;

    /** Frees all resources allocated by the compositor. */
    public function dispose():Void;
}
