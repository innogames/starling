// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.core;

import lime.utils.Float32Array;
import flash.display.Shape;
import flash.display.Sprite;
import flash.display.Stage3D;
import flash.display.Stage in FlashStage;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.display3D.Context3D;
import flash.display3D.Context3DCompareMode;
import flash.display3D.Context3DProfile;
import flash.display3D.Context3DRenderMode;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Program3D;
import flash.errors.ArgumentError;
import flash.errors.Error;
import flash.errors.IllegalOperationError;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.geom.Rectangle;
import flash.system.Capabilities;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.ui.KeyLocation;
import flash.ui.Mouse;
import flash.ui.Multitouch;
import flash.ui.MultitouchInputMode;
import flash.utils.ByteArray;
import flash.Lib;

import haxe.Timer;

import openfl.Vector;

import starling.animation.Juggler;
import starling.display.DisplayObject;
import starling.display.Stage;
import starling.events.EventDispatcher;
import starling.events.ResizeEvent;
import starling.events.TouchPhase;
import starling.events.TouchProcessor;
import starling.text.BitmapFont;
import starling.utils.Execute;
import starling.utils.HAlign;
import starling.utils.SystemUtil;
import starling.utils.VAlign;

/** Dispatched when a new render context is created. The 'data' property references the context. */
@:meta(Event(name="context3DCreate", type="starling.events.Event"))

/** Dispatched when the root class has been created. The 'data' property references that object. */
@:meta(Event(name="rootCreated", type="starling.events.Event"))

/** Dispatched when a fatal error is encountered. The 'data' property contains an error string. */
@:meta(Event(name="fatalError", type="starling.events.Event"))

/** Dispatched when the display list is about to be rendered. This event provides the last
 *  opportunity to make changes before the display list is rendered. */
@:meta(Event(name="render", type="starling.events.Event"))

/** The Starling class represents the core of the Starling framework.
 *
 *  <p>The Starling framework makes it possible to create 2D applications and games that make
 *  use of the Stage3D architecture introduced in Flash Player 11. It implements a display tree
 *  system that is very similar to that of conventional Flash, while leveraging modern GPUs
 *  to speed up rendering.</p>
 *  
 *  <p>The Starling class represents the link between the conventional Flash display tree and
 *  the Starling display tree. To create a Starling-powered application, you have to create
 *  an instance of the Starling class:</p>
 *  
 *  <pre>var starling:Starling = new Starling(Game, stage);</pre>
 *  
 *  <p>The first parameter has to be a Starling display object class, e.g. a subclass of 
 *  <code>starling.display.Sprite</code>. In the sample above, the class "Game" is the
 *  application root. An instance of "Game" will be created as soon as Starling is initialized.
 *  The second parameter is the conventional (Flash) stage object. Per default, Starling will
 *  display its contents directly below the stage.</p>
 *  
 *  <p>It is recommended to store the Starling instance as a member variable, to make sure
 *  that the Garbage Collector does not destroy it. After creating the Starling object, you 
 *  have to start it up like this:</p>
 * 
 *  <pre>starling.start();</pre>
 * 
 *  <p>It will now render the contents of the "Game" class in the frame rate that is set up for
 *  the application (as defined in the Flash stage).</p> 
 * 
 *  <strong>Context3D Profiles</strong>
 * 
 *  <p>Stage3D supports different rendering profiles, and Starling works with all of them. The
 *  last parameter of the Starling constructor allows you to choose which profile you want.
 *  The following profiles are available:</p>
 * 
 *  <ul>
 *    <li>BASELINE_CONSTRAINED: provides the broadest hardware reach. If you develop for the
 *        browser, this is the profile you should test with.</li>
 *    <li>BASELINE: recommend for any mobile application, as it allows Starling to use a more
 *        memory efficient texture type (RectangleTextures). It also supports more complex
 *        AGAL code.</li>
 *    <li>BASELINE_EXTENDED: adds support for textures up to 4096x4096 pixels. This is
 *        especially useful on mobile devices with very high resolutions.</li>
 *  </ul>
 *  
 *  <p>The recommendation is to deploy your app with the profile "auto" (which makes Starling
 *  pick the best available of those three), but test it in all available profiles.</p>
 *  
 *  <strong>Accessing the Starling object</strong>
 * 
 *  <p>From within your application, you can access the current Starling object anytime
 *  through the static method <code>Starling.current</code>. It will return the active Starling
 *  instance (most applications will only have one Starling object, anyway).</p> 
 * 
 *  <strong>Viewport</strong>
 * 
 *  <p>The area the Starling content is rendered into is, per default, the complete size of the 
 *  stage. You can, however, use the "viewPort" property to change it. This can be  useful 
 *  when you want to render only into a part of the screen, or if the player size changes. For
 *  the latter, you can listen to the RESIZE-event dispatched by the Starling
 *  stage.</p>
 * 
 *  <strong>Native overlay</strong>
 *  
 *  <p>Sometimes you will want to display native Flash content on top of Starling. That's what the
 *  <code>nativeOverlay</code> property is for. It returns a Flash Sprite lying directly
 *  on top of the Starling content. You can add conventional Flash objects to that overlay.</p>
 *  
 *  <p>Beware, though, that conventional Flash content on top of 3D content can lead to
 *  performance penalties on some (mobile) platforms. For that reason, always remove all child
 *  objects from the overlay when you don't need them any longer. Starling will remove the 
 *  overlay from the display list when it's empty.</p>
 *  
 *  <strong>Multitouch</strong>
 *  
 *  <p>Starling supports multitouch input on devices that provide it. During development, 
 *  where most of us are working with a conventional mouse and keyboard, Starling can simulate 
 *  multitouch events with the help of the "Shift" and "Ctrl" (Mac: "Cmd") keys. Activate
 *  this feature by enabling the <code>simulateMultitouch</code> property.</p>
 *  
 *  <strong>Handling a lost render context</strong>
 *  
 *  <p>On some operating systems and under certain conditions (e.g. returning from system
 *  sleep), Starling's stage3D render context may be lost. Starling can recover from a lost
 *  context if the class property "handleLostContext" is set to "true". Keep in mind, however, 
 *  that this comes at the price of increased memory consumption; Starling will cache textures 
 *  in RAM to be able to restore them when the context is lost. (Except if you use the
 *  'AssetManager' for your textures. It is smart enough to recreate a texture directly
 *  from its origin.)</p> 
 *  
 *  <p>In case you want to react to a context loss, Starling dispatches an event with
 *  the type "Event.CONTEXT3D_CREATE" when the context is restored. You can recreate any 
 *  invalid resources in a corresponding event listener.</p>
 * 
 *  <strong>Sharing a 3D Context</strong>
 * 
 *  <p>Per default, Starling handles the Stage3D context itself. If you want to combine
 *  Starling with another Stage3D engine, however, this may not be what you want. In this case,
 *  you can make use of the <code>shareContext</code> property:</p> 
 *  
 *  <ol>
 *    <li>Manually create and configure a context3D object that both frameworks can work with
 *        (through <code>stage3D.requestContext3D</code> and
 *        <code>context.configureBackBuffer</code>).</li>
 *    <li>Initialize Starling with the stage3D instance that contains that configured context.
 *        This will automatically enable <code>shareContext</code>.</li>
 *    <li>Call <code>start()</code> on your Starling instance (as usual). This will make  
 *        Starling queue input events (keyboard/mouse/touch).</li>
 *    <li>Create a game loop (e.g. using the native <code>ENTER_FRAME</code> event) and let it  
 *        call Starling's <code>nextFrame</code> as well as the equivalent method of the other 
 *        Stage3D engine. Surround those calls with <code>context.clear()</code> and 
 *        <code>context.present()</code>.</li>
 *  </ol>
 *  
 *  <p>The Starling wiki contains a <a href="http://goo.gl/BsXzw">tutorial</a> with more 
 *  information about this topic.</p>
 * 
 */ 
class Starling extends EventDispatcher
{
    /** The version of the Starling framework. */
    public static inline var VERSION:String = "1.8";
    
    /** The key for the shader programs stored in 'contextData' */
    private static inline var PROGRAM_DATA_NAME:String = "Starling.programs"; 
    
    // members
    
    private var mStage3D:Stage3D;
    private var mStage:Stage; // starling.display.stage!
    private var mRootClass:Class<Dynamic>;
    private var mRoot:DisplayObject;
    private var mJuggler:Juggler;
    private var mSupport:RenderSupport;
    private var mTouchProcessor:TouchProcessor;
    private var mAntiAliasing:Int;
    private var mSimulateMultitouch:Bool;
    private var mEnableErrorChecking:Bool;
    private var mLastFrameTimestamp:Float;
    private var mLeftMouseDown:Bool;
    private var mStatsDisplay:StatsDisplay;
    private var mShareContext:Bool;
    private var mProfile:Context3DProfile;
    private var mContext:Context3D;
    private var mStarted:Bool;
    private var mRendering:Bool;
    private var mSupportHighResolutions:Bool;
    private var mBroadcastKeyboardEvents:Bool;
    
    private var mViewPort:Rectangle;
    private var mPreviousViewPort:Rectangle;
    private var mClippedViewPort:Rectangle;

    private var mNativeStage:flash.display.Stage;
    private var mNativeOverlay:flash.display.Sprite;
    private var mNativeStageContentScaleFactor:Float;

    private static var sCurrent:Starling;
    private static var sHandleLostContext:Bool = true;
    private static var sContextData:Map<Stage3D, Map<String, Dynamic>> = new Map<Stage3D, Map<String, Dynamic>>();
    private static var sAll:Vector<Starling> = new Vector<Starling>();
    
    // construction
    
    /** Creates a new Starling instance. 
     * @param rootClass  A subclass of 'starling.display.DisplayObject'. It will be created
     *                   as soon as initialization is finished and will become the first child
     *                   of the Starling stage. Pass <code>null</code> if you don't want to
     *                   create a root object right away. (You can use the
     *                   <code>rootClass</code> property later to make that happen.)
     * @param stage      The Flash (2D) stage.
     * @param viewPort   A rectangle describing the area into which the content will be 
     *                   rendered. Default: stage size
     * @param stage3D    The Stage3D object into which the content will be rendered. If it 
     *                   already contains a context, <code>sharedContext</code> will be set
     *                   to <code>true</code>. Default: the first available Stage3D.
     * @param renderMode The Context3D render mode that should be requested.
     *                   Use this parameter if you want to force "software" rendering.
     * @param profile    The Context3D profile that should be requested.
     *
     *                   <ul>
     *                   <li>If you pass a profile String, this profile is enforced.</li>
     *                   <li>Pass an Array of profiles to make Starling pick the first
     *                       one that works (starting with the first array element).</li>
     *                   <li>Pass the String "auto" to make Starling pick the best available
     *                       profile automatically.</li>
     *                   </ul>
     */
    @:access(starling.display.Stage.new)
    public function new(rootClass:Class<Dynamic>, stage:flash.display.Stage,
                             viewPort:Rectangle=null, stage3D:Stage3D=null,
                             renderMode:Context3DRenderMode=AUTO, profile:Dynamic="auto")
    {
        super();
        if (stage == null) throw new ArgumentError("Stage must not be null");
        if (viewPort == null) viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
        if (stage3D == null) stage3D = stage.stage3Ds[0];

        SystemUtil.initialize();
        sAll.push(this);
		
        if (sCurrent == null) makeCurrent();
		
        mRootClass = rootClass;
        mViewPort = viewPort;
        mPreviousViewPort = new Rectangle();
        mStage3D = stage3D;
        mStage = new Stage(Std.int(viewPort.width), Std.int(viewPort.height), stage.color);
        mNativeOverlay = new Sprite();
        mNativeStage = stage;
        mNativeStage.addChild(mNativeOverlay);
        mNativeStageContentScaleFactor = 1.0;
        mTouchProcessor = new TouchProcessor(mStage);
        mJuggler = new Juggler();
        mAntiAliasing = 0;
        mSimulateMultitouch = false;
        mEnableErrorChecking = false;
        mSupportHighResolutions = false;
        mBroadcastKeyboardEvents = true;
        mLastFrameTimestamp = Lib.getTimer() / 1000.0;
        mSupport  = new RenderSupport();
        
        // for context data, we actually reference by stage3D, since it survives a context loss
        sContextData[stage3D] = new Map<String, Dynamic>();
        sContextData[stage3D][PROGRAM_DATA_NAME] = new Map<String, Program3D>();

        // all other modes are problematic in Starling, so we force those here
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        
        // register touch/mouse event handlers            
        for (touchEventType in touchEventTypes)
            stage.addEventListener(touchEventType, onTouch, false, 0, true);
        
        // register other event handlers
        stage.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey, false, 0, true);
        stage.addEventListener(KeyboardEvent.KEY_UP, onKey, false, 0, true);
        stage.addEventListener(Event.RESIZE, onResize, false, 0, true);
        stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeave, false, 0, true);
        
        mStage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated, false, 10, true);
        mStage3D.addEventListener(ErrorEvent.ERROR, onStage3DError, false, 10, true);
        
        if (mStage3D.context3D != null && mStage3D.context3D.driverInfo != "Disposed")
        {
            #if flash
            if (profile == "auto" || Std.is(profile, Array))
                throw new ArgumentError("When sharing the context3D, " +
                    "the actual profile has to be supplied");
            else
                mProfile = cast(profile, Context3DProfile);
            mShareContext = true;
            #else
            mProfile = mStage3D.context3D.profile;
            //mShareContext = true;
            #end
            if (stage3D.context3D != null) Timer.delay(initialize, 1);
        }
        else
        {
            if (!SystemUtil.supportsDepthAndStencil)
                trace("[Starling] Mask support requires 'depthAndStencil' to be enabled" +
                      " in the application descriptor.");

            mShareContext = false;
            requestContext3D(stage3D, renderMode, profile);
        }
    }
    
    /** Disposes all children of the stage and the render context; removes all registered
     * event listeners. */
    public function dispose():Void
    {
        stop(true);

        mNativeStage.removeEventListener(Event.ENTER_FRAME, onEnterFrame, false);
        mNativeStage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey, false);
        mNativeStage.removeEventListener(KeyboardEvent.KEY_UP, onKey, false);
        mNativeStage.removeEventListener(Event.RESIZE, onResize, false);
        mNativeStage.removeEventListener(Event.MOUSE_LEAVE, onMouseLeave, false);
        mNativeStage.removeChild(mNativeOverlay);
        
        mStage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated, false);
        mStage3D.removeEventListener(ErrorEvent.ERROR, onStage3DError, false);
        
        for (touchEventType in touchEventTypes)
            mNativeStage.removeEventListener(touchEventType, onTouch, false);
        
        if (mStage != null) mStage.dispose();
        if (mSupport != null) mSupport.dispose();
        if (mTouchProcessor != null) mTouchProcessor.dispose();
        if (sCurrent == this) sCurrent = null;
        if (mContext != null && !mShareContext) 
        {
            // Per default, the context is recreated as long as there are listeners on it.
            // Beginning with AIR 3.6, we can avoid that with an additional parameter.
            mContext.dispose();
        }

        var index:Int =  sAll.indexOf(this);
        if (index != -1) sAll.splice(index, 1);
    }
    
    // functions
    
    private function requestContext3D(stage3D:Stage3D, renderMode:Context3DRenderMode, profile:Dynamic):Void
    {
        var profiles:Array<Context3DProfile> = new Array();
        var currentProfile:Context3DProfile;
        
        if (profile == "auto")
            profiles = [ /*Context3DProfile.STANDARD_EXTENDED, Context3DProfile.STANDARD,*/ Context3DProfile.BASELINE_EXTENDED, Context3DProfile.BASELINE, Context3DProfile.BASELINE_CONSTRAINED];
        else if (Std.is(profile, #if flash String #else Int #end))
            profiles = [cast profile];
        else if (Std.is(profile, Array))
            profiles = cast profile;
        else
            throw new ArgumentError("Profile must be of type 'Context3DProfile' or 'Array'");

        var onFinished:Void->Void = null;
        var onError:Event->Void = null;
        function requestNextProfile():Void
        {
            currentProfile = profiles.shift();

            try { Execute.execute(mStage3D.requestContext3D, [renderMode, currentProfile]); }
            catch (error:Error)
            {
                if (profiles.length != 0) Timer.delay(requestNextProfile, 1);
                else throw error;
            }
        }
        
        function onCreated(event:Event):Void
        {
            var context:Context3D = stage3D.context3D;

            if (renderMode == Context3DRenderMode.AUTO && profiles.length != 0 &&
                (context.driverInfo != null && context.driverInfo.indexOf("Software") != -1))
            {
                onError(event);
            }
            else
            {
                mProfile = currentProfile;
                onFinished();
            }
        }
        
        onError = function(event:Event):Void
        {
            if (profiles.length != 0)
            {
                event.stopImmediatePropagation();
                Timer.delay(requestNextProfile, 1);
            }
            else onFinished();
        }
        
        onFinished = function():Void
        {
            mStage3D.removeEventListener(Event.CONTEXT3D_CREATE, onCreated);
            mStage3D.removeEventListener(ErrorEvent.ERROR, onError);
        }
        
        mStage3D.addEventListener(Event.CONTEXT3D_CREATE, onCreated, false, 100);
        mStage3D.addEventListener(ErrorEvent.ERROR, onError, false, 100);
        
        requestNextProfile();
    }
    
    private function initialize():Void
    {
        makeCurrent();
        
        initializeGraphicsAPI();
        initializeRoot();
        
        mTouchProcessor.simulateMultitouch = mSimulateMultitouch;
        mLastFrameTimestamp = Lib.getTimer() / 1000.0;
    }
    
    private function initializeGraphicsAPI():Void
    {
        mContext = mStage3D.context3D;
        mContext.enableErrorChecking = mEnableErrorChecking;
        contextData[PROGRAM_DATA_NAME] = new Map<String, Program3D>();
        
        trace("[Starling] Initialization complete.");
        trace("[Starling] Display Driver: " + mContext.driverInfo);

        updateViewPort(true);
        dispatchEventWith(Event.CONTEXT3D_CREATE, false, mContext);
    }
    
    private function initializeRoot():Void
    {
        if (mRoot == null && mRootClass != null)
        {
            mRoot = Type.createInstance(mRootClass, []);
            if (mRoot == null) throw new Error("Invalid root class: " + mRootClass);
            mStage.addChildAt(mRoot, 0);

            dispatchEventWith(starling.events.Event.ROOT_CREATED, false, mRoot);
        }
    }
    
    /** Calls <code>advanceTime()</code> (with the time that has passed since the last frame)
     * and <code>render()</code>. */
    public function nextFrame():Void
    {
        var now:Float = Lib.getTimer() / 1000.0;
        var passedTime:Float = now - mLastFrameTimestamp;
        mLastFrameTimestamp = now;
        
        // to avoid overloading time-based animations, the maximum delta is truncated.
        if (passedTime > 1.0) passedTime = 1.0;

        // after about 25 days, 'getTimer()' will roll over. A rare event, but still ...
        if (passedTime < 0.0) passedTime = 1.0 / mNativeStage.frameRate;

        advanceTime(passedTime);
        render();
    }
    
    /** Dispatches ENTER_FRAME events on the display list, advances the Juggler 
     * and processes touches. */
    public function advanceTime(passedTime:Float):Void
    {
        if (!contextValid)
            return;
        
        makeCurrent();
        
        mTouchProcessor.advanceTime(passedTime);
        mStage.advanceTime(passedTime);
        mJuggler.advanceTime(passedTime);
    }
    
    /** Renders the complete display list. Before rendering, the context is cleared; afterwards,
     * it is presented (to avoid this, enable <code>shareContext</code>).
     *
     * <p>This method also dispatches an <code>Event.RENDER</code>-event on the Starling
     * instance. That's the last opportunity to make changes before the display list is
     * rendered.</p> */
    public function render():Void
    {
        if (!contextValid)
            return;
        
        makeCurrent();
        updateViewPort();
        dispatchEventWith(starling.events.Event.RENDER);

        var scaleX:Float = mViewPort.width  / mStage.stageWidth;
        var scaleY:Float = mViewPort.height / mStage.stageHeight;
        
        mContext.setDepthTest(false, Context3DCompareMode.ALWAYS);
        mContext.setCulling(Context3DTriangleFace.NONE);

        mSupport.nextFrame();
        mSupport.stencilReferenceValue = 0;
        mSupport.renderTarget = null; // back buffer
        mSupport.setProjectionMatrix(
            mViewPort.x < 0 ? -mViewPort.x / scaleX : 0.0,
            mViewPort.y < 0 ? -mViewPort.y / scaleY : 0.0,
            mClippedViewPort.width  / scaleX,
            mClippedViewPort.height / scaleY,
            mStage.stageWidth, mStage.stageHeight, mStage.cameraPosition);
        
        mSupport.batcher.setViewport(mViewPort.x, mViewPort.y, mViewPort.width, mViewPort.height);

        if (!mShareContext)
            RenderSupport._clear(mStage.color, 1.0);
        
        mStage.render(mSupport, 1.0);
        mSupport.finishQuadBatch();
        
        if (mStatsDisplay != null)
            mStatsDisplay.drawCount = mSupport.drawCount;
        
        if (!mShareContext)
            mContext.present();
    }
    
    private function updateViewPort(forceUpdate:Bool=false):Void
    {
        // the last set viewport is stored in a variable; that way, people can modify the
        // viewPort directly (without a copy) and we still know if it has changed.
        
        if (forceUpdate || mPreviousViewPort.width != mViewPort.width || 
            mPreviousViewPort.height != mViewPort.height ||
            mPreviousViewPort.x != mViewPort.x || mPreviousViewPort.y != mViewPort.y)
        {
            mPreviousViewPort.setTo(mViewPort.x, mViewPort.y, mViewPort.width, mViewPort.height);
            
            // Constrained mode requires that the viewport is within the native stage bounds;
            // thus, we use a clipped viewport when configuring the back buffer. (In baseline
            // mode, that's not necessary, but it does not hurt either.)
            
            mClippedViewPort = mViewPort.intersection(
                new Rectangle(0, 0, mNativeStage.stageWidth, mNativeStage.stageHeight));
            
            if (!mShareContext)
            {
                // setting x and y might move the context to invalid bounds (since changing
                // the size happens in a separate operation) -- so we have no choice but to
                // set the backbuffer to a very small size first, to be on the safe side.
                
                if (mProfile == Context3DProfile.BASELINE_CONSTRAINED)
                    configureBackBuffer(32, 32, mAntiAliasing, true);
                
                mStage3D.x = mClippedViewPort.x;
                mStage3D.y = mClippedViewPort.y;
                
                configureBackBuffer(Std.int(mClippedViewPort.width), Std.int(mClippedViewPort.height),
                    mAntiAliasing, true, mSupportHighResolutions);
                
                if (mSupportHighResolutions && Reflect.getProperty(mNativeStage, "contentsScaleFactor") != null)
                    mNativeStageContentScaleFactor = Reflect.getProperty(mNativeStage, "contentsScaleFactor");
                else
                    mNativeStageContentScaleFactor = 1.0;
            }
        }
    }
    
    /** Configures the back buffer while automatically keeping backwards compatibility with
     * AIR versions that do not support the "wantsBestResolution" argument. */
    private function configureBackBuffer(width:Int, height:Int, antiAlias:Int, 
                                         enableDepthAndStencil:Bool,
                                         wantsBestResolution:Bool=false):Void
    {
        enableDepthAndStencil = enableDepthAndStencil && SystemUtil.supportsDepthAndStencil;
        width = (width < 32) ? 32 : width;
        height = (height < 32) ? 32 : height;
        mContext.configureBackBuffer(width, height, antiAlias, enableDepthAndStencil, wantsBestResolution);
    }

    private function updateNativeOverlay():Void
    {
        mNativeOverlay.x = mViewPort.x;
        mNativeOverlay.y = mViewPort.y;
        mNativeOverlay.scaleX = mViewPort.width / mStage.stageWidth;
        mNativeOverlay.scaleY = mViewPort.height / mStage.stageHeight;
    }
    
    /** Stops Starling right away and displays an error message on the native overlay.
     * This method will also cause Starling to dispatch a FATAL_ERROR event. */
    public function stopWithFatalError(message:String):Void
    {
        var background:Shape = new Shape();
        background.graphics.beginFill(0x0, 0.8);
        background.graphics.drawRect(0, 0, mStage.stageWidth, mStage.stageHeight);
        background.graphics.endFill();

        var textField:TextField = new TextField();
        var textFormat:TextFormat = new TextFormat("_sans", 14, 0xFFFFFF);
        textFormat.align = TextFormatAlign.CENTER;
        textField.defaultTextFormat = textFormat;
        textField.wordWrap = true;
        textField.width = mStage.stageWidth * 0.75;
        textField.autoSize = TextFieldAutoSize.CENTER;
        textField.text = message;
        textField.x = (mStage.stageWidth  - textField.width)  / 2;
        textField.y = (mStage.stageHeight - textField.height) / 2;
        textField.background = true;
        textField.backgroundColor = 0x550000;

        updateNativeOverlay();
        nativeOverlay.addChild(background);
        nativeOverlay.addChild(textField);
        stop(true);

        trace("[Starling]", message);
        dispatchEventWith(starling.events.Event.FATAL_ERROR, false, message);
    }
    
    /** Make this Starling instance the <code>current</code> one. */
    public function makeCurrent():Void
    {
        sCurrent = this;
    }
    
    /** As soon as Starling is started, it will queue input events (keyboard/mouse/touch);   
     * furthermore, the method <code>nextFrame</code> will be called once per Flash Player
     * frame. (Except when <code>shareContext</code> is enabled: in that case, you have to
     * call that method manually.) */
    public function start():Void 
    { 
        mStarted = mRendering = true;
        mLastFrameTimestamp = Lib.getTimer() / 1000.0;
    }
    
    /** Stops all logic and input processing, effectively freezing the app in its current state.
     * Per default, rendering will continue: that's because the classic display list
     * is only updated when stage3D is. (If Starling stopped rendering, conventional Flash
     * contents would freeze, as well.)
     * 
     * <p>However, if you don't need classic Flash contents, you can stop rendering, too.
     * On some mobile systems (e.g. iOS), you are even required to do so if you have
     * activated background code execution.</p>
     */
    public function stop(suspendRendering:Bool=false):Void
    { 
        mStarted = false;
        mRendering = !suspendRendering;
    }
    
    // event handlers
    
    private function onStage3DError(event:ErrorEvent):Void
    {
        if (event.errorID == 3702)
        {
            var mode:String = Capabilities.playerType == "Desktop" ? "renderMode" : "wmode";
            stopWithFatalError("Context3D not available! Possible reasons: wrong " + mode +
                               " or missing device support.");
        }
        else
            stopWithFatalError("Stage3D error: " + event.text);
    }
    
    private function onContextCreated(event:Event):Void
    {
        if (!Starling.handleLostContext && mContext != null)
        {
            event.stopImmediatePropagation();
            stopWithFatalError("The application lost the device context!");
            trace("[Starling] Enable 'Starling.handleLostContext' to avoid this error.");
        }
        else
        {
            initialize();
        }
    }
    
    private function onEnterFrame(event:Event):Void
    {
        // On mobile, the native display list is only updated on stage3D draw calls.
        // Thus, we render even when Starling is paused.
        
        if (!mShareContext)
        {
            if (mStarted) nextFrame();
            else if (mRendering) render();
        }

        updateNativeOverlay();
    }
    
    private function onKey(event:KeyboardEvent):Void
    {
        if (!mStarted) return;
        
        var keyEvent:starling.events.KeyboardEvent = new starling.events.KeyboardEvent(
            event.type, event.charCode, event.keyCode, event.keyLocation, 
            event.ctrlKey, event.altKey, event.shiftKey);
        
        makeCurrent();

        if (mBroadcastKeyboardEvents) mStage.broadcastEvent(keyEvent);
        else mStage.dispatchEvent(keyEvent);
        
        if (keyEvent.isDefaultPrevented())
            event.preventDefault();
    }
    
    private function onResize(event:Event):Void
    {
        var stageWidth:Int  = cast (event.target, FlashStage).stageWidth;
        var stageHeight:Int = cast (event.target, FlashStage).stageHeight;

        function dispatchResizeEvent():Void
        {
            // on Android, the context is not valid while we're resizing. To avoid problems
            // with user code, we delay the event dispatching until it becomes valid again.

            makeCurrent();
            removeEventListener(Event.CONTEXT3D_CREATE, dispatchResizeEvent);
            mStage.dispatchEvent(new ResizeEvent(Event.RESIZE, stageWidth, stageHeight));
        }

        if (contextValid)
            dispatchResizeEvent();
        else
            addEventListener(Event.CONTEXT3D_CREATE, dispatchResizeEvent);
    }

    private function onMouseLeave(event:Event):Void
    {
        mTouchProcessor.enqueueMouseLeftStage();
    }
    
    private function onTouch(event:Event):Void
    {
        if (!mStarted) return;
        
        var globalX:Float;
        var globalY:Float;
        var touchID:Int;
        var phase:String = null;
        var pressure:Float = 1.0;
        var width:Float = 1.0;
        var height:Float = 1.0;
        
        // figure out general touch properties
        if (Std.is(event, MouseEvent))
        {
            var mouseEvent:MouseEvent = cast event;
            globalX = mouseEvent.stageX;
            globalY = mouseEvent.stageY;
            touchID = 0;
            
            // MouseEvent.buttonDown returns true for both left and right button (AIR supports
            // the right mouse button). We only want to react on the left button for now,
            // so we have to save the state for the left button manually.
            if (event.type == MouseEvent.MOUSE_DOWN)    mLeftMouseDown = true;
            else if (event.type == MouseEvent.MOUSE_UP) mLeftMouseDown = false;
        }
        else
        {
            var touchEvent:TouchEvent = cast(event, TouchEvent);
        
            // On a system that supports both mouse and touch input, the primary touch point
            // is dispatched as mouse event as well. Since we don't want to listen to that
            // event twice, we ignore the primary touch in that case.
            
            if (Mouse.supportsCursor && touchEvent.isPrimaryTouchPoint) return;
            else
            {
                globalX  = touchEvent.stageX;
                globalY  = touchEvent.stageY;
                touchID  = touchEvent.touchPointID;
                pressure = touchEvent.pressure;
                width    = touchEvent.sizeX;
                height   = touchEvent.sizeY;
            }
        }
        
        // figure out touch phase
        switch (event.type)
        {
            case TouchEvent.TOUCH_BEGIN: phase = TouchPhase.BEGAN;
            case TouchEvent.TOUCH_MOVE:  phase = TouchPhase.MOVED;
            case TouchEvent.TOUCH_END:   phase = TouchPhase.ENDED;
            case MouseEvent.MOUSE_DOWN:  phase = TouchPhase.BEGAN;
            case MouseEvent.MOUSE_UP:    phase = TouchPhase.ENDED;
            case MouseEvent.MOUSE_MOVE: 
                phase = (mLeftMouseDown ? TouchPhase.MOVED : TouchPhase.HOVER);
        }
        
        // move position into viewport bounds
        globalX = mStage.stageWidth  * (globalX - mViewPort.x) / mViewPort.width;
        globalY = mStage.stageHeight * (globalY - mViewPort.y) / mViewPort.height;
        
        // enqueue touch in touch processor
        mTouchProcessor.enqueue(touchID, phase, globalX, globalY, pressure, width, height);
        
        // allow objects that depend on mouse-over state to be updated immediately
        if (event.type == MouseEvent.MOUSE_UP && Mouse.supportsCursor)
            mTouchProcessor.enqueue(touchID, TouchPhase.HOVER, globalX, globalY);
    }
    
    private var touchEventTypes(get, never):Array<String>;
    private function get_touchEventTypes():Array<String>
    {
        var types = new Array<String>();
        
        if (multitouchEnabled)
        {
            types.push(TouchEvent.TOUCH_BEGIN);
            types.push(TouchEvent.TOUCH_MOVE);
            types.push(TouchEvent.TOUCH_END);
        }
        
        if (!multitouchEnabled || Mouse.supportsCursor)
        {
			types.push(MouseEvent.MOUSE_DOWN);
            types.push(MouseEvent.MOUSE_MOVE);
            types.push(MouseEvent.MOUSE_UP);
        }
        
        return types;
    }
    
    // program management
    
    /** Registers a compiled shader-program under a certain name.
     * If the name was already used, the previous program is overwritten. */
    public function registerProgram(name:String, vertexShader:Dynamic,
                                    fragmentShader:Dynamic):Program3D
    {
        deleteProgram(name);
        
        var program:Program3D = mContext.createProgram();
        program.upload(vertexShader, fragmentShader);
        programs[name] = program;
        
        return program;
    }
    
    /** Compiles a shader-program and registers it under a certain name.
     * If the name was already used, the previous program is overwritten. */
    public function registerProgramFromSource(name:String, vertexShader:String,
                                              fragmentShader:String):Program3D
    {
        deleteProgram(name);
        
        var program:Program3D = RenderSupport.assembleAgal(vertexShader, fragmentShader);
        programs[name] = program;
        
        return program;
    }
    
    /** Deletes the vertex- and fragment-programs of a certain name. */
    public function deleteProgram(name:String):Void
    {
        var program:Program3D = getProgram(name);            
        if (program != null)
        {                
            program.dispose();
            programs.remove(name);
        }
    }
    
    public function removeCurrentProgram():Void {
        // Context's __program needs to be cleared as BatchRenderer uses different program. If not cleared, Starling will
        // try to set its program's parameters to BatchRenderer's program which results with WebGL warnings
        if (mContext != null) {
            @:privateAccess mContext.__program = null;
        }
    }
    
    /** Returns the vertex- and fragment-programs registered under a certain name. */
    public function getProgram(name:String):Program3D
    {
        return programs[name];
    }
    
    /** Indicates if a set of vertex- and fragment-programs is registered under a certain name. */
    public function hasProgram(name:String):Bool
    {
        return programs.exists(name);
    }
    
    private var programs(get, never):Map<String, Program3D>;
    private function get_programs():Map<String, Program3D> { return contextData[PROGRAM_DATA_NAME]; }
    
    // properties
    
    /** Indicates if this Starling instance is started. */
    public var isStarted(get, never):Bool;
    private function get_isStarted():Bool { return mStarted; }

    /** Indicates if this instance is currently rendering its display list each frame.
     *  Even when Starling was stopped, it might continue rendering; that's because the
     *  classic display list is only updated when stage3D is. (If Starling stopped rendering,
     *  conventional Flash contents would freeze, as well.) */
    public var isRendering(get, never):Bool;
    private function get_isRendering():Bool { return mRendering; }
    
    /** The default juggler of this instance. Will be advanced once per frame. */
    public var juggler(get, never):Juggler;
    private function get_juggler():Juggler { return mJuggler; }
    
    /** The render context of this instance. */
    public var context(get, never):Context3D;
    private function get_context():Context3D { return mContext; }
    
    /** A dictionary that can be used to save custom data related to the current context. 
     * If you need to share data that is bound to a specific stage3D instance
     * (e.g. textures), use this dictionary instead of creating a static class variable.
     * The Dictionary is actually bound to the stage3D instance, thus it survives a 
     * context loss. */
    public var contextData(get, never):Map<String, Dynamic>;
    private function get_contextData():Map<String, Dynamic>
    {
        return sContextData[mStage3D];
    }
    
    /** Returns the current width of the back buffer. In most cases, this value is in pixels;
     * however, if the app is running on an HiDPI display with an activated
     * 'supportHighResolutions' setting, you have to multiply with 'backBufferPixelsPerPoint'
     * for the actual pixel count. */
    public var backBufferWidth(get, never):Int;
    private function get_backBufferWidth():Int { return Std.int(mClippedViewPort.width); }

    /** Returns the current height of the back buffer. In most cases, this value is in pixels;
     * however, if the app is running on an HiDPI display with an activated
     * 'supportHighResolutions' setting, you have to multiply with 'backBufferPixelsPerPoint'
     * for the actual pixel count.  */
    public var backBufferHeight(get, never):Int;
    private function get_backBufferHeight():Int { return Std.int(mClippedViewPort.height); }

    /** The number of pixel per point returned by the 'backBufferWidth/Height' properties.
     * Except for desktop HiDPI displays with an activated 'supportHighResolutions' setting,
     * this will always return '1'. */
    public var backBufferPixelsPerPoint(get, never):Int;
    private function get_backBufferPixelsPerPoint():Int
    {
        return Std.int(mNativeStageContentScaleFactor);
    }

    /** Indicates if multitouch simulation with "Shift" and "Ctrl"/"Cmd"-keys is enabled.
     * @default false */
    public var simulateMultitouch(get, set):Bool;
    private function get_simulateMultitouch():Bool { return mSimulateMultitouch; }
    private function set_simulateMultitouch(value:Bool):Bool
    {
        mSimulateMultitouch = value;
        if (mContext != null) mTouchProcessor.simulateMultitouch = value;
        return value;
    }

    /** Indicates if Stage3D render methods will report errors. It's recommended to activate
     * this when writing custom rendering code (shaders, etc.), since you'll get more detailed
     * error messages. However, it has a very negative impact on performance, and it prevents
     * ATF textures from being restored on a context loss. Never activate for release builds!
     *
     * @default false */
    public var enableErrorChecking(get, set):Bool;
    private function get_enableErrorChecking():Bool { return mEnableErrorChecking; }
    private function set_enableErrorChecking(value:Bool):Bool 
    { 
        mEnableErrorChecking = value;
        if (mContext != null) mContext.enableErrorChecking = value;
        return value;
    }
    
    /** The antialiasing level. 0 - no antialasing, 16 - maximum antialiasing. @default 0 */
    public var antiAliasing(get, set):Int;
    private function get_antiAliasing():Int { return mAntiAliasing; }
    private function set_antiAliasing(value:Int):Int
    {
        if (mAntiAliasing != value)
        {
            mAntiAliasing = value;
            if (contextValid) updateViewPort(true);
        }
        return value;
    }
    
    /** The viewport into which Starling contents will be rendered. */
    public var viewPort(get, set):Rectangle;
    private function get_viewPort():Rectangle { return mViewPort; }
    private function set_viewPort(value:Rectangle):Rectangle { return mViewPort = value.clone(); }
    
    /** The ratio between viewPort width and stage width. Useful for choosing a different
     * set of textures depending on the display resolution. */
    public var contentScaleFactor(get, never):Float;
    private function get_contentScaleFactor():Float
    {
        return (mViewPort.width * mNativeStageContentScaleFactor) / mStage.stageWidth;
    }
    
    /** A Flash Sprite placed directly on top of the Starling content. Use it to display native
     * Flash components. */ 
    public var nativeOverlay(get, never):Sprite;
    private function get_nativeOverlay():Sprite { return mNativeOverlay; }
    
    /** Indicates if a small statistics box (with FPS, memory usage and draw count) is
     * displayed.
     *
     * <p>Beware that the memory usage should be taken with a grain of salt. The value is
     * determined via <code>System.totalMemory</code> and does not take texture memory
     * into account. It is recommended to use Adobe Scout for reliable and comprehensive
     * memory analysis.</p>
     */
    public var showStats(get, set):Bool;
    private function get_showStats():Bool { return mStatsDisplay != null && mStatsDisplay.parent != null; }
    private function set_showStats(value:Bool):Bool
    {
        if (value == showStats) return mStatsDisplay != null && mStatsDisplay.parent != null;
        
        if (value)
        {
            if (mStatsDisplay != null) mStage.addChild(mStatsDisplay);
            else               showStatsAt();
        }
        else mStatsDisplay.removeFromParent();
        return value;
    }
    
    /** Displays the statistics box at a certain position. */
    public function showStatsAt(hAlign:String="left", vAlign:String="top", scale:Float=1):Void
    {
        function onRootCreated():Void
		{
			showStatsAt(hAlign, vAlign, scale);
			removeEventListener(starling.events.Event.ROOT_CREATED, onRootCreated);
		}
		
        if (mContext == null)
        {
            // Starling is not yet ready - we postpone this until it's initialized.
            addEventListener(starling.events.Event.ROOT_CREATED, onRootCreated);
        }
        else
        {
            var stageWidth:Int  = mStage.stageWidth;
            var stageHeight:Int = mStage.stageHeight;

            if (mStatsDisplay == null)
            {
                mStatsDisplay = new StatsDisplay();
                mStatsDisplay.touchable = false;
            }

            mStage.addChild(mStatsDisplay);
            mStatsDisplay.scaleX = mStatsDisplay.scaleY = scale;

            if (hAlign == HAlign.LEFT) mStatsDisplay.x = 0;
            else if (hAlign == HAlign.RIGHT) mStatsDisplay.x = stageWidth - mStatsDisplay.width; 
            else mStatsDisplay.x = Std.int((stageWidth - mStatsDisplay.width) / 2);
            
            if (vAlign == VAlign.TOP) mStatsDisplay.y = 0;
            else if (vAlign == VAlign.BOTTOM) mStatsDisplay.y = stageHeight - mStatsDisplay.height;
            else mStatsDisplay.y = Std.int((stageHeight - mStatsDisplay.height) / 2);
        }
    }
    
    /** The Starling stage object, which is the root of the display tree that is rendered. */
    public var stage(get, never):Stage;
    private function get_stage():Stage { return mStage; }

    /** The Flash Stage3D object Starling renders into. */
    public var stage3D(get, never):Stage3D;
    private function get_stage3D():Stage3D { return mStage3D; }
    
    /** The Flash (2D) stage object Starling renders beneath. */
    public var nativeStage(get, never):flash.display.Stage;
    private function get_nativeStage():flash.display.Stage { return mNativeStage; }
    
    /** The instance of the root class provided in the constructor. Available as soon as 
     * the event 'ROOT_CREATED' has been dispatched. */
    public var root(get, never):DisplayObject;
    private function get_root():DisplayObject { return mRoot; }

    /** The class that will be instantiated by Starling as the 'root' display object.
     * Must be a subclass of 'starling.display.DisplayObject'.
     *
     * <p>If you passed <code>null</code> as first parameter to the Starling constructor,
     * you can use this property to set the root class at a later time. As soon as the class
     * is instantiated, Starling will dispatch a <code>ROOT_CREATED</code> event.</p>
     *
     * <p>Beware: you cannot change the root class once the root object has been
     * instantiated.</p>
     */
    public var rootClass(get, set):Class<Dynamic>;
    private function get_rootClass():Class<Dynamic> { return mRootClass; }
    private function set_rootClass(value:Class<Dynamic>):Class<Dynamic>
    {
        if (mRootClass != null && mRoot != null)
            throw new Error("Root class may not change after root has been instantiated");
        else if (mRootClass == null)
        {
            mRootClass = value;
            if (mContext != null) initializeRoot();
        }
        return value;
    }

    /** Indicates if the Context3D render calls are managed externally to Starling, 
     * to allow other frameworks to share the Stage3D instance. @default false */
    public var shareContext(get, set):Bool;
    private function get_shareContext() : Bool { return mShareContext; }
    private function set_shareContext(value : Bool) : Bool { return mShareContext = value; }
    
    /** The Context3D profile used for rendering. Beware that if you are using a shared
     * context in AIR 3.9 / Flash Player 11 or below, this is simply what you passed to
     * the Starling constructor. */
    public var profile(get, never):Context3DProfile;
    private function get_profile():Context3DProfile { return mProfile; }
    
    /** Indicates that if the device supports HiDPI screens Starling will attempt to allocate
     * a larger back buffer than indicated via the viewPort size. Note that this is used
     * on Desktop only; mobile AIR apps still use the "requestedDisplayResolution" parameter
     * the application descriptor XML. @default false */
    public var supportHighResolutions(get, set):Bool;
    private function get_supportHighResolutions():Bool { return mSupportHighResolutions; }
    private function set_supportHighResolutions(value:Bool):Bool 
    {
        if (mSupportHighResolutions != value)
        {
            mSupportHighResolutions = value;
            if (contextValid) updateViewPort(true);
        }
        return value;
    }

    /** Indicates if keyboard events are broadcast to all display objects, or dispatched
     * to the stage only. In some situations, it makes sense to deactivate this setting
     * for performance reasons. @default true */
    private function get_broadcastKeyboardEvents():Bool { return mBroadcastKeyboardEvents; }
    private function set_broadcastKeyboardEvents(value:Bool):Bool
    {
        return mBroadcastKeyboardEvents = value;
    }
    
    /** The TouchProcessor is passed all mouse and touch input and is responsible for
     * dispatching TouchEvents to the Starling display tree. If you want to handle these
     * types of input manually, pass your own custom subclass to this property. */
    public var touchProcessor(get, set):TouchProcessor;
    private function get_touchProcessor():TouchProcessor { return mTouchProcessor; }
    private function set_touchProcessor(value:TouchProcessor):TouchProcessor
    {
        if (value != mTouchProcessor)
        {
            mTouchProcessor.dispose();
            mTouchProcessor = value;
        }
        return value;
    }
    
    /** Indicates if the Context3D object is currently valid (i.e. it hasn't been lost or
     * disposed). */
    public var contextValid(get, never):Bool;
    private function get_contextValid():Bool
    {
        if (mContext != null)
        {
            var driverInfo:String = mContext.driverInfo;
            return driverInfo != null && driverInfo != "" && driverInfo != "Disposed";
        }
        else return false;
    }

    // static properties
    
    /** The currently active Starling instance. */
    public static var current(get, never):Starling;
    private static function get_current():Starling { return sCurrent; }

    /** All Starling instances. <p>CAUTION: not a copy, but the actual object! Do not modify!</p> */
    public static var all(get, never):Vector<Starling>;
    private static function get_all():Vector<Starling> { return sAll; }
    
    /** The render context of the currently active Starling instance. */
    /*
    public static var context(get, never):Context3D;
    private static function get_context():Context3D { return sCurrent != null ? sCurrent.context : null; }
    */
    
    /** The default juggler of the currently active Starling instance. */
    /*
    public static var juggler(get, never):Juggler;
    private static function get_juggler():Juggler { return sCurrent != null ? sCurrent.juggler : null; }
    */
    
    /** The contentScaleFactor of the currently active Starling instance. */
    /*
    public static var contentScaleFactor(get, never):Float;
    private static function get_contentScaleFactor():Float 
    {
        return sCurrent != null ? sCurrent.contentScaleFactor : 1.0;
    }
    */
    
    /** Indicates if multitouch input should be supported. */
    public static var multitouchEnabled(get, set):Bool;
    private static function get_multitouchEnabled():Bool 
    { 
        return Multitouch.inputMode == MultitouchInputMode.TOUCH_POINT;
    }
    
    private static function set_multitouchEnabled(value:Bool):Bool
    {
        if (sCurrent != null) throw new IllegalOperationError(
            "'multitouchEnabled' must be set before Starling instance is created");
        else 
            Multitouch.inputMode = value ? MultitouchInputMode.TOUCH_POINT :
                                           MultitouchInputMode.NONE;
        return value;
    }
    
    /** Indicates if Starling should automatically recover from a lost device context.
     * On some systems, an upcoming screensaver or entering sleep mode may 
     * invalidate the render context. This setting indicates if Starling should recover from 
     * such incidents.
     *
     * <p>Beware: if used carelessly, this property may have a huge impact on memory
     * consumption. That's because, by default, it will make Starling keep a copy of each
     * texture in memory.</p>
     *
     * <p>However, this downside can be avoided by using the "AssetManager" to load textures.
     * The AssetManager is smart enough to restore them directly from their sources. You can
     * also do this by setting up "root.onRestore" on your manually loaded textures.</p>
     *
     * <p>A context loss can happen on almost every platform. It's very common on Windows
     * and Android, but rare on OS X and iOS (e.g. it may occur when opening up the camera
     * roll). It's recommended to always enable this property, while using the AssetManager
     * for texture loading.</p>
     * 
     * @default true
     * @see starling.utils.AssetManager
     */
    public static var handleLostContext(get, set):Bool;
    private static function get_handleLostContext():Bool { return sHandleLostContext; }
    private static function set_handleLostContext(value:Bool):Bool 
    {
        if (sCurrent != null) throw new IllegalOperationError(
            "'handleLostContext' must be set before Starling instance is created");
        else
            sHandleLostContext = value;
        return value;
    }
}