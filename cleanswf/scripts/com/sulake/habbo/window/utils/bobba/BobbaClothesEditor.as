package com.sulake.habbo.window.utils.bobba
{
   import com.sulake.core.window.IWindowModel;
   import com.sulake.core.window.components.IBitmapWrapperController;
   import com.sulake.core.window.components.IDisplayObjectWrapperController;
   import com.sulake.core.window.components.IFrameController;
   import com.sulake.core.window.components.IWidgetWindowController;
   import com.sulake.core.window.events.WindowEvent;
   import com.sulake.habbo.window.HabboWindowManagerComponent;
   import com.sulake.habbo.window.widgets.IAvatarImageWidget;
   import flash.display.BitmapData;
   import flash.display.Sprite;
   import flash.geom.Rectangle;
   
   public class BobbaClothesEditor
   {
      
      private static const MOUSE_BLOCK_KEY:String = "bobba_clothes";
      
      private static const FRAME_W:int = 430;
      
      private static const FRAME_H:int = 268;
      
      private static const AVATAR_X:int = 314;
      
      private static const AVATAR_Y:int = 8;
      
      private static const AVATAR_W:int = 100;
      
      private static const AVATAR_H:int = 160;
      
      private static const AVATAR_FILL:uint = 2700082;
      
      private static const AVATAR_STROKE:uint = 2236962;
      
      private static const CANVAS_X:int = 6;
      
      private static const CANVAS_Y:int = 0;
      
      private var _windowManager:HabboWindowManagerComponent;
      
      private var _controller:BobbaClothesController;
      
      private var _window:IFrameController;
      
      private var _canvas:IDisplayObjectWrapperController;
      
      private var _avatarWell:IBitmapWrapperController;
      
      private var _view:BobbaClothesView;
      
      private var _openWhenReady:Boolean = false;
      
      public function BobbaClothesEditor(windowManager:HabboWindowManagerComponent, controller:BobbaClothesController)
      {
         super();
         _windowManager = windowManager;
         _controller = controller;
         BobbaIlluminaDarkStyle.preload();
      }
      
      public function get visible() : Boolean
      {
         return _window != null && Boolean(_window.visible);
      }
      
      public function set visible(value:Boolean) : void
      {
         if(value)
         {
            _openWhenReady = true;
            if(_window == null)
            {
               createWindow();
            }
            else
            {
               _window.visible = true;
               _window.activate();
               refresh();
               updateRoomMouseBlockRect();
            }
         }
         else if(_window != null)
         {
            _openWhenReady = false;
            _window.visible = false;
            removeRoomMouseBlockRect();
            if(_controller != null)
            {
               _controller.onWindowHidden();
            }
         }
      }
      
      public function refresh() : void
      {
         if(_view != null)
         {
            _view.refresh();
         }
         applyAvatar();
         if(_window != null)
         {
            _window.caption = BobbaI18n.t("clothes.panel.title","Clothes");
         }
      }
      
      public function dispose() : void
      {
         removeRoomMouseBlockRect();
         if(_view != null)
         {
            _view.dispose();
            _view = null;
         }
         if(_window != null)
         {
            _window.dispose();
            _window = null;
         }
         _canvas = null;
         _avatarWell = null;
         _controller = null;
         _windowManager = null;
      }
      
      private function applyAvatarWell() : void
      {
         var well:Sprite = null;
         var bd:BitmapData = null;
         if(_window == null)
         {
            return;
         }
         _avatarWell = _window.findChildByName("clothes_avatar_well") as IBitmapWrapperController;
         if(_avatarWell == null)
         {
            return;
         }
         _avatarWell.x = AVATAR_X;
         _avatarWell.y = AVATAR_Y;
         _avatarWell.width = AVATAR_W;
         _avatarWell.height = AVATAR_H;
         _avatarWell.setParamFlag(257,false);
         _avatarWell.ignoreMouseEvents = true;
         _avatarWell.disposesBitmap = true;
         well = new Sprite();
         well.graphics.lineStyle(1,AVATAR_STROKE,1);
         well.graphics.beginFill(AVATAR_FILL,1);
         well.graphics.drawRoundRect(0.5,0.5,AVATAR_W - 1,AVATAR_H - 1,18,18);
         well.graphics.endFill();
         bd = new BitmapData(AVATAR_W,AVATAR_H,true,0);
         bd.draw(well);
         _avatarWell.bitmap = bd;
      }
      
      private function applyAvatar() : void
      {
         var widgetWin:IWidgetWindowController = null;
         var avatar:IAvatarImageWidget = null;
         var figure:String = "";
         if(_window == null || _controller == null)
         {
            return;
         }
         try
         {
            widgetWin = _window.findChildByName("clothes_avatar") as IWidgetWindowController;
            if(widgetWin == null)
            {
               return;
            }
            avatar = IAvatarImageWidget(widgetWin.widget);
            if(avatar == null)
            {
               return;
            }
            figure = _controller.targetFigure;
            if(figure != null && figure.length > 0)
            {
               avatar.figure = figure;
            }
         }
         catch(figErr:Error)
         {
         }
      }
      
      private function createWindow() : void
      {
         if(!BobbaIlluminaDarkStyle.isReady())
         {
            BobbaIlluminaDarkStyle.whenReady(onStyleReady);
            return;
         }
         buildWindow();
      }
      
      private function onStyleReady() : void
      {
         if(_windowManager == null || !_openWhenReady)
         {
            return;
         }
         if(_window == null)
         {
            buildWindow();
            return;
         }
         _window.visible = true;
         _window.activate();
         refresh();
         updateRoomMouseBlockRect();
      }
      
      private function buildWindow() : void
      {
         var layout:XML = null;
         var built:IWindowModel = null;
         var hdr:IWindowModel = null;
         try
         {
            BobbaIlluminaDarkStyle.patchPurpleFrame(_windowManager);
            layout = <layout name="bobba_clothes" width="430" height="268" version="0.1">
					<window>
						<frame x="0" y="0" width="430" height="268" params="33025" style="103" name="bobba_clothes_frame" caption="Clothes">
							<children>
								<display_object_wrapper x="6" y="0" width="300" height="230" params="16" style="0" name="bobba_clothes_canvas"/>
								<bitmap x="314" y="8" width="100" height="160" params="16" style="0" name="clothes_avatar_well"/>
								<widget x="319" y="22" width="90" height="130" params="16" style="100" name="clothes_avatar">
									<variables>
										<var key="widget_type" value="avatar_image" type="String"/>
										<var key="avatar_image:scale" value="h" type="String"/>
										<var key="avatar_image:only_head" value="false" type="Boolean"/>
										<var key="avatar_image:cropped" value="false" type="Boolean"/>
										<var key="avatar_image:direction" value="south" type="String"/>
									</variables>
								</widget>
							</children>
							<variables>
								<var key="margin_left" value="6" type="int"/>
								<var key="margin_top" value="30" type="int"/>
								<var key="margin_right" value="6" type="int"/>
								<var key="margin_bottom" value="6" type="int"/>
							</variables>
						</frame>
					</window>
				</layout>;
            built = _windowManager.buildFromXML(layout,1);
            _window = built as IFrameController;
            if(_window == null)
            {
               return;
            }
            _window.caption = BobbaI18n.t("clothes.panel.title","Clothes");
            _window.margins.left = 6;
            _window.margins.top = 30;
            _window.margins.right = _window.width - 6;
            _window.margins.bottom = _window.height - 6;
            _window.procedure = windowProcedure;
            _window.center();
            _window.setParamFlag(257,false);
            _window.setParamFlag(32768,true);
            _window.setParamFlag(65536,false);
            try
            {
               _window.limits.minWidth = FRAME_W;
               _window.limits.minHeight = FRAME_H;
               _window.limits.maxWidth = FRAME_W;
               _window.limits.maxHeight = FRAME_H;
            }
            catch(limErr:Error)
            {
            }
            hdr = _window.header as IWindowModel;
            if(hdr != null)
            {
               hdr.setParamFlag(257,true);
            }
            _canvas = _window.findChildByName("bobba_clothes_canvas") as IDisplayObjectWrapperController;
            if(_canvas == null)
            {
               return;
            }
            _canvas.x = CANVAS_X;
            _canvas.y = CANVAS_Y;
            _canvas.width = BobbaClothesView.VIEW_W;
            _canvas.height = BobbaClothesView.VIEW_H;
            _canvas.setParamFlag(257,false);
            _canvas.setParamFlag(32768,false);
            applyAvatarWell();
            _view = new BobbaClothesView(_controller,_windowManager);
            _canvas.setDisplayObject(_view);
            layoutContent();
            applyAvatar();
            if(_view != null)
            {
               _view.refresh();
            }
            _window.visible = true;
            _window.activate();
            updateRoomMouseBlockRect();
         }
         catch(e:Error)
         {
         }
      }
      
      private function updateRoomMouseBlockRect() : void
      {
         var rect:Rectangle = null;
         try
         {
            if(_window == null || !_window.visible || _windowManager == null || _windowManager.roomEngine == null)
            {
               removeRoomMouseBlockRect();
               return;
            }
            rect = new Rectangle();
            _window.getGlobalRectangle(rect);
            if(rect.isEmpty())
            {
               removeRoomMouseBlockRect();
               return;
            }
            _windowManager.roomEngine.setMouseEventsDisabledRect(MOUSE_BLOCK_KEY,rect);
         }
         catch(errBlock:Error)
         {
         }
      }
      
      private function removeRoomMouseBlockRect() : void
      {
         try
         {
            if(_windowManager != null && _windowManager.roomEngine != null)
            {
               _windowManager.roomEngine.removeMouseEventsDisabledRect(MOUSE_BLOCK_KEY);
            }
         }
         catch(errRemove:Error)
         {
         }
      }
      
      private function windowProcedure(event:WindowEvent, target:IWindowModel) : void
      {
         if(event == null || target == null)
         {
            return;
         }
         if(event.type == "WME_CLICK" && target.name == "header_button_close")
         {
            visible = false;
            return;
         }
         if(event.type == "WE_RELOCATED" || event.type == "WME_UP")
         {
            updateRoomMouseBlockRect();
         }
      }
      
      private function layoutContent() : void
      {
         var innerW:int = 0;
         var innerH:int = 0;
         var canvasW:int = 0;
         var widget:IWindowModel = null;
         if(_window == null || _canvas == null)
         {
            return;
         }
         innerW = _window.width - 12;
         innerH = _window.height - 36;
         if(innerW < 180)
         {
            innerW = 180;
         }
         if(innerH < 140)
         {
            innerH = 140;
         }
         canvasW = innerW - AVATAR_W - 16;
         if(canvasW < 120)
         {
            canvasW = 120;
         }
         _canvas.x = CANVAS_X;
         _canvas.y = CANVAS_Y;
         _canvas.width = canvasW;
         _canvas.height = innerH;
         if(_view != null)
         {
            _view.setSize(canvasW,innerH);
         }
         if(_avatarWell != null)
         {
            _avatarWell.x = CANVAS_X + canvasW + 8;
            _avatarWell.y = AVATAR_Y;
         }
         try
         {
            widget = _window.findChildByName("clothes_avatar");
            if(widget != null)
            {
               widget.x = CANVAS_X + canvasW + 13;
               widget.y = 22;
            }
         }
         catch(wErr:Error)
         {
         }
      }
   }
}
