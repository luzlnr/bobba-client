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
   
   public class BobbaMimicEditor
   {
      
      private static const MOUSE_BLOCK_KEY:String = "bobba_mimic";
      
      private static const FRAME_W:int = 404;
      
      private static const FRAME_H:int = 236;
      
      private static const AVATAR_X:int = 6;
      
      private static const AVATAR_Y:int = 8;
      
      private static const AVATAR_W:int = 100;
      
      private static const AVATAR_H:int = 160;
      
      private static const AVATAR_FILL:uint = 0x292929;
      
      private static const AVATAR_STROKE:uint = 0x222222;
      
      private static const CANVAS_X:int = 110;
      
      private static const CANVAS_Y:int = 0;
      
      private static const BTN_ALL_X:int = 114;
      
      private static const BTN_ALL_Y:int = 153;
      
      private static const BTN_ALL_W:int = 132;
      
      private static const BTN_ALL_H:int = 24;
      
      private static const BTN_NONE_X:int = 252;
      
      private static const BTN_NONE_Y:int = 153;
      
      private static const BTN_NONE_W:int = 132;
      
      private static const BTN_NONE_H:int = 24;
      
      private var _windowManager:HabboWindowManagerComponent;
      
      private var _controller:BobbaMimicController;
      
      private var _window:IFrameController;
      
      private var _canvas:IDisplayObjectWrapperController;
      
      private var _avatarWell:IBitmapWrapperController;
      
      private var _view:BobbaMimicView;
      
      public function BobbaMimicEditor(windowManager:HabboWindowManagerComponent, controller:BobbaMimicController)
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
            _window.caption = BobbaI18n.t("mimic.panel.title","Mimic");
            applyButtonCaptions();
         }
      }
      
      public function dispose() : void
      {
         removeRoomMouseBlockRect();
         BobbaIlluminaDarkStyle.restorePurpleFrame(_windowManager);
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
      
      private function applyButtonCaptions() : void
      {
         var allBtn:IWindowModel = null;
         var noneBtn:IWindowModel = null;
         if(_window == null)
         {
            return;
         }
         allBtn = _window.findChildByName("mimic_btn_all");
         if(allBtn != null)
         {
            allBtn.caption = BobbaI18n.t("mimic.btn.all","Enable all");
         }
         noneBtn = _window.findChildByName("mimic_btn_none");
         if(noneBtn != null)
         {
            noneBtn.caption = BobbaI18n.t("mimic.btn.none","Disable all");
         }
      }
      
      private function applyAvatarWell() : void
      {
         var well:Sprite = null;
         var bd:BitmapData = null;
         if(_window == null)
         {
            return;
         }
         _avatarWell = _window.findChildByName("mimic_avatar_well") as IBitmapWrapperController;
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
            widgetWin = _window.findChildByName("mimic_avatar") as IWidgetWindowController;
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
         if(_windowManager == null || _window != null)
         {
            return;
         }
         buildWindow();
      }
      
      private function buildWindow() : void
      {
         var layout:XML = null;
         var built:IWindowModel = null;
         var hdr:IWindowModel = null;
         try
         {
            BobbaIlluminaDarkStyle.patchPurpleFrame(_windowManager);
            layout = <layout name="bobba_mimic" width="404" height="236" version="0.1">
					<window>
						<frame x="0" y="0" width="404" height="236" params="33025" style="103" name="bobba_mimic_frame" caption="Mimic">
							<children>
								<bitmap x="6" y="8" width="100" height="160" params="16" style="0" name="mimic_avatar_well"/>
								<widget x="11" y="22" width="90" height="130" params="16" style="100" name="mimic_avatar">
									<variables>
										<var key="widget_type" value="avatar_image" type="String"/>
										<var key="avatar_image:scale" value="h" type="String"/>
										<var key="avatar_image:only_head" value="false" type="Boolean"/>
										<var key="avatar_image:cropped" value="false" type="Boolean"/>
										<var key="avatar_image:direction" value="south" type="String"/>
									</variables>
								</widget>
								<display_object_wrapper x="110" y="0" width="280" height="153" params="16" style="0" name="bobba_mimic_canvas"/>
								<button x="114" y="153" width="132" height="24" params="17" style="104" name="mimic_btn_all" caption="Enable all"/>
								<button x="252" y="153" width="132" height="24" params="17" style="104" name="mimic_btn_none" caption="Disable all"/>
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
            _window.caption = BobbaI18n.t("mimic.panel.title","Mimic");
            applyButtonCaptions();
            _window.margins.left = 6;
            _window.margins.top = 30;
            _window.margins.right = _window.width - 6;
            _window.margins.bottom = _window.height - 6;
            _window.procedure = windowProcedure;
            _window.center();
            _window.setParamFlag(257,false);
            _window.setParamFlag(32768,true);
            hdr = _window.header as IWindowModel;
            if(hdr != null)
            {
               hdr.setParamFlag(257,true);
            }
            _canvas = _window.findChildByName("bobba_mimic_canvas") as IDisplayObjectWrapperController;
            if(_canvas == null)
            {
               return;
            }
            _canvas.x = CANVAS_X;
            _canvas.y = CANVAS_Y;
            _canvas.width = BobbaMimicView.VIEW_W;
            _canvas.height = BobbaMimicView.VIEW_H;
            _canvas.setParamFlag(257,false);
            _canvas.setParamFlag(32768,false);
            applyAvatarWell();
            _view = new BobbaMimicView(_controller);
            _canvas.setDisplayObject(_view);
            applyAvatar();
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
         if(event.type == "WME_CLICK" && target.name == "mimic_btn_all")
         {
            if(_controller != null)
            {
               _controller.setAllOptions(true);
               refresh();
            }
            return;
         }
         if(event.type == "WME_CLICK" && target.name == "mimic_btn_none")
         {
            if(_controller != null)
            {
               _controller.setAllOptions(false);
               refresh();
            }
            return;
         }
         if(event.type == "WE_RELOCATED" || event.type == "WE_RESIZED" || event.type == "WME_UP")
         {
            updateRoomMouseBlockRect();
         }
      }
   }
}
