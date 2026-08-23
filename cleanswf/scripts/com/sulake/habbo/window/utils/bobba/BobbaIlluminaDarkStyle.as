package com.sulake.habbo.window.utils.bobba
{
   import com.sulake.core.assets.BitmapDataAsset;
   import com.sulake.habbo.window.HabboWindowManagerComponent;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.Loader;
   import flash.events.Event;
   import flash.geom.Point;
   import flash.net.URLRequest;
   
   public class BobbaIlluminaDarkStyle
   {
      
      public static const FRAME_STYLE:uint = 103;
      
      public static const BUTTON_STYLE:uint = 104;
      
      private static const FRAME_PATH:String = "illumina_dark.png";
      
      private static const BUTTON_PATH:String = "illumina_dark_bobba_green.png";
      
      private static const CLOSE_PATH:String = "bobba_illumina_dark_btn.png";
      
      private static const FRAME_ASSET:String = "illumina_purple_border_frame_png";
      
      private static const BUTTON_ASSET:String = "illumina_purple_button_default_png";
      
      private static const CLOSE_ASSET:String = "illumina_purple_button_frame_close_png";
      
      private static var _frameSrc:BitmapData;
      
      private static var _buttonSrc:BitmapData;
      
      private static var _closeSrc:BitmapData;
      
      private static var _loading:int = 0;
      
      private static var _readyCallbacks:Array = [];
      
      private static var _patched:Boolean = false;
      
      private static var _origFrame:BitmapData;
      
      private static var _origButton:BitmapData;
      
      private static var _origClose:BitmapData;
      
      public function BobbaIlluminaDarkStyle()
      {
         super();
      }
      
      public static function isReady() : Boolean
      {
         return _frameSrc != null && _buttonSrc != null && _closeSrc != null;
      }
      
      public static function preload() : void
      {
         if(isReady() || _loading > 0)
         {
            return;
         }
         loadOne(FRAME_PATH,"frame");
         loadOne(BUTTON_PATH,"button");
         loadOne(CLOSE_PATH,"close");
      }
      
      public static function whenReady(callback:Function) : void
      {
         preload();
         if(callback == null)
         {
            return;
         }
         if(isReady())
         {
            callback();
            return;
         }
         _readyCallbacks.push(callback);
      }
      
      public static function patchPurpleFrame(windowManager:HabboWindowManagerComponent) : Boolean
      {
         if(_patched)
         {
            return true;
         }
         if(!isReady() || windowManager == null || windowManager.assets == null)
         {
            return false;
         }
         _origFrame = replaceAsset(windowManager,FRAME_ASSET,_frameSrc);
         _origButton = replaceAsset(windowManager,BUTTON_ASSET,_buttonSrc);
         _origClose = replaceAsset(windowManager,CLOSE_ASSET,_closeSrc);
         _patched = true;
         return true;
      }
      
      public static function restorePurpleFrame(windowManager:HabboWindowManagerComponent) : void
      {
         if(!_patched)
         {
            disposeOrig(_origFrame);
            disposeOrig(_origButton);
            disposeOrig(_origClose);
            _origFrame = null;
            _origButton = null;
            _origClose = null;
            return;
         }
         restoreAsset(windowManager,FRAME_ASSET,_origFrame);
         restoreAsset(windowManager,BUTTON_ASSET,_origButton);
         restoreAsset(windowManager,CLOSE_ASSET,_origClose);
         _origFrame = null;
         _origButton = null;
         _origClose = null;
         _patched = false;
      }
      
      private static function loadOne(path:String, key:String) : void
      {
         var url:String = null;
         var loader:Loader = null;
         try
         {
            url = BobbaPack.resolveUrl(path);
            if(url == null || url.length == 0)
            {
               return;
            }
            loader = new Loader();
            loader.name = key;
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE,onLoaded);
            loader.contentLoaderInfo.addEventListener("ioError",onError);
            _loading = _loading + 1;
            loader.load(new URLRequest(url));
         }
         catch(loadErr:Error)
         {
         }
      }
      
      private static function onLoaded(e:Event) : void
      {
         var bmp:Bitmap = null;
         var loader:Loader = null;
         try
         {
            loader = e.target.loader as Loader;
            if(loader != null && loader.content is Bitmap)
            {
               bmp = loader.content as Bitmap;
               if(bmp != null && bmp.bitmapData != null)
               {
                  if(loader.name == "frame")
                  {
                     _frameSrc = bmp.bitmapData.clone();
                  }
                  else if(loader.name == "button")
                  {
                     _buttonSrc = bmp.bitmapData.clone();
                  }
                  else if(loader.name == "close")
                  {
                     _closeSrc = bmp.bitmapData.clone();
                  }
               }
            }
         }
         catch(readyErr:Error)
         {
         }
         _loading = _loading - 1;
         if(isReady())
         {
            flushCallbacks();
         }
      }
      
      private static function onError(e:Event) : void
      {
         _loading = _loading - 1;
      }
      
      private static function replaceAsset(windowManager:HabboWindowManagerComponent, assetName:String, src:BitmapData) : BitmapData
      {
         var asset:* = null;
         var bda:BitmapDataAsset = null;
         var current:BitmapData = null;
         var composed:BitmapData = null;
         var original:BitmapData = null;
         if(src == null)
         {
            return null;
         }
         try
         {
            asset = windowManager.assets.getAssetByName(assetName);
            bda = asset as BitmapDataAsset;
            if(bda == null)
            {
               return null;
            }
            current = bda.content as BitmapData;
            if(current != null)
            {
               original = current.clone();
               if(current.width >= src.width && current.height >= src.height)
               {
                  composed = current.clone();
                  composed.copyPixels(src,src.rect,new Point(0,0));
                  bda.setUnknownContent(composed);
               }
               else
               {
                  bda.setUnknownContent(src.clone());
               }
            }
            else
            {
               bda.setUnknownContent(src.clone());
            }
         }
         catch(patchErr:Error)
         {
            return original;
         }
         return original;
      }
      
      private static function restoreAsset(windowManager:HabboWindowManagerComponent, assetName:String, original:BitmapData) : void
      {
         var asset:* = null;
         var bda:BitmapDataAsset = null;
         if(original == null || windowManager == null || windowManager.assets == null)
         {
            disposeOrig(original);
            return;
         }
         try
         {
            asset = windowManager.assets.getAssetByName(assetName);
            bda = asset as BitmapDataAsset;
            if(bda != null)
            {
               bda.setUnknownContent(original);
            }
            else
            {
               disposeOrig(original);
            }
         }
         catch(restoreErr:Error)
         {
            disposeOrig(original);
         }
      }
      
      private static function disposeOrig(data:BitmapData) : void
      {
         if(data == null)
         {
            return;
         }
         try
         {
            data.dispose();
         }
         catch(disposeErr:Error)
         {
         }
      }
      
      private static function flushCallbacks() : void
      {
         var i:int = 0;
         var cb:Function = null;
         var list:Array = _readyCallbacks;
         _readyCallbacks = [];
         for(i = 0; i < list.length; i++)
         {
            cb = list[i] as Function;
            if(cb != null)
            {
               try
               {
                  cb();
               }
               catch(cbErr:Error)
               {
               }
            }
         }
      }
   }
}
