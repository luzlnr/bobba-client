package com.sulake.habbo.window.utils.bobba
{
   import com.sulake.core.window.IWindowController_1;
   import com.sulake.core.window.IWindowModel;
   import com.sulake.core.window.components.IDesktopController;
   import com.sulake.core.window.events.WindowEvent;
   import com.sulake.habbo.window.HabboWindowManagerComponent;
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   
   public class BobbaClothesController
   {
      
      private static var _instance:BobbaClothesController;
      
      private var _windowManager:HabboWindowManagerComponent;
      
      private var _editor:BobbaClothesEditor;
      
      private var _menuTick:Timer;
      
      private var _clothesBtn:IWindowModel;
      
      private var _targetName:String = "";
      
      public function BobbaClothesController(windowManager:HabboWindowManagerComponent)
      {
         super();
         _windowManager = windowManager;
         _instance = this;
         BobbaIlluminaDarkStyle.preload();
      }
      
      public static function install(windowManager:HabboWindowManagerComponent) : BobbaClothesController
      {
         if(_instance != null)
         {
            return _instance;
         }
         if(windowManager == null)
         {
            return null;
         }
         return new BobbaClothesController(windowManager);
      }
      
      public static function get instance() : BobbaClothesController
      {
         return _instance;
      }
      
      public function get windowManager() : HabboWindowManagerComponent
      {
         return _windowManager;
      }
      
      public function get targetName() : String
      {
         return _targetName;
      }
      
      public function get targetFigure() : String
      {
         var data:* = targetUserData();
         if(data != null && data.figure != null)
         {
            return String(data.figure);
         }
         return "";
      }
      
      public function get targetGender() : String
      {
         var data:* = targetUserData();
         var sex:String = "M";
         try
         {
            if(data != null && data.sex != null)
            {
               sex = String(data.sex);
            }
         }
         catch(a:Error)
         {
         }
         if(sex == "F" || sex == "f" || sex == "female")
         {
            return "F";
         }
         return "M";
      }
      
      public function get parts() : Array
      {
         return BobbaClothesCatalog.parts(_windowManager,targetFigure);
      }
      
      public function openForName(name:String) : void
      {
         if(name == null || name.length == 0)
         {
            alert(BobbaI18n.t("clothes.alert.nouser","Click a user first."));
            return;
         }
         _targetName = name;
         if(_editor == null)
         {
            _editor = new BobbaClothesEditor(_windowManager,this);
         }
         _editor.visible = true;
         _editor.refresh();
      }
      
      public function onWindowHidden() : void
      {
      }
      
      public function dispose() : void
      {
         if(_menuTick != null)
         {
            _menuTick.stop();
            _menuTick.removeEventListener(TimerEvent.TIMER,onMenuTick);
            _menuTick = null;
         }
         if(_editor != null)
         {
            _editor.dispose();
            _editor = null;
         }
         if(_instance == this)
         {
            _instance = null;
         }
         _windowManager = null;
      }
      
      private function onMenuTick(e:TimerEvent) : void
      {
         var whisper:IWindowModel = null;
         var mimicBtn:IWindowModel = null;
         var parent:IWindowController_1 = null;
         var clone:IWindowModel = null;
         var after:IWindowModel = null;
         if(_windowManager == null)
         {
            return;
         }
         if(_clothesBtn != null && _clothesBtn.parent != null)
         {
            return;
         }
         whisper = findAvatarMenuWhisper();
         if(whisper == null)
         {
            return;
         }
         mimicBtn = findNamed("bobba_mimic");
         after = mimicBtn != null ? mimicBtn : whisper;
         parent = whisper.parent as IWindowController_1;
         if(parent == null)
         {
            return;
         }
         try
         {
            clone = (whisper as IWindowController_1).clone();
            if(clone == null)
            {
               return;
            }
            clone.name = "bobba_clothes";
            clone.caption = BobbaI18n.t("avatar.menu.clothes","Clothes");
            clone.y = after.y + after.height + 2;
            clone.procedure = onClothesMenuClick;
            parent.addChild(clone as IWindowController_1);
            parent.height = Math.max(parent.height,clone.y + clone.height + 4);
            _clothesBtn = clone;
         }
         catch(menuErr:Error)
         {
         }
      }
      
      private function onClothesMenuClick(event:WindowEvent, target:IWindowModel) : void
      {
         var name:String = null;
         if(event == null || event.type != "WME_CLICK")
         {
            return;
         }
         name = nameNear(target);
         if(name == null || name.length == 0)
         {
            name = lastClickedFromCustoms();
         }
         openForName(name);
      }
      
      private function findAvatarMenuWhisper() : IWindowModel
      {
         var whisper:IWindowModel = findNamed("whisper");
         var parent:IWindowController_1 = null;
         if(whisper == null)
         {
            whisper = findNamed("WHISPER");
         }
         if(whisper == null)
         {
            return null;
         }
         parent = whisper.parent as IWindowController_1;
         if(parent == null)
         {
            return null;
         }
         if(parent.findChildByName("friend") != null || parent.findChildByName("ignore") != null || parent.findChildByName("report") != null || parent.findChildByName("trade") != null)
         {
            return whisper;
         }
         return null;
      }
      
      private function findNamed(name:String) : IWindowModel
      {
         var i:int = 0;
         var desk:IDesktopController = null;
         var found:IWindowModel = null;
         i = 0;
         while(i < 4)
         {
            desk = _windowManager.getDesktop(i);
            if(desk != null)
            {
               found = desk.findChildByName(name);
               if(found != null)
               {
                  return found;
               }
            }
            i++;
         }
         return null;
      }
      
      private function nameNear(start:IWindowModel) : String
      {
         var node:IWindowModel = start;
         var child:IWindowModel = null;
         var names:Array = ["name","user_name","avatar_name","name_text"];
         var i:int = 0;
         var n:String = null;
         var low:String = "";
         while(node != null)
         {
            i = 0;
            while(i < names.length)
            {
               child = node.findChildByName(names[i]);
               if(child != null && child.caption != null && String(child.caption).length > 0)
               {
                  n = String(child.caption);
                  low = n.toLowerCase();
                  if(low != "whisper" && low != "mimic" && low != "clothes" && low != "roupas")
                  {
                     return n;
                  }
               }
               i++;
            }
            node = node.parent;
         }
         return "";
      }
      
      private function lastClickedFromCustoms() : String
      {
         var customs:* = null;
         try
         {
            customs = _windowManager.LilithCustomsInstance;
            if(customs == null)
            {
               return "";
            }
            if(customs.LastClickedUsername != null)
            {
               return String(customs.LastClickedUsername);
            }
            if(customs.ClickedUserName != null)
            {
               return String(customs.ClickedUserName);
            }
            if(customs.TargetUserName != null)
            {
               return String(customs.TargetUserName);
            }
         }
         catch(cErr:Error)
         {
         }
         return "";
      }
      
      private function targetUserData() : *
      {
         var session:* = null;
         try
         {
            session = roomSession();
            if(session == null || session.userDataManager == null)
            {
               return null;
            }
            return session.userDataManager.getUserDataByName(_targetName);
         }
         catch(udErr:Error)
         {
         }
         return null;
      }
      
      private function roomSession() : *
      {
         try
         {
            if(_windowManager != null && _windowManager.LilithCustomsInstance != null && _windowManager.LilithCustomsInstance.IsRoomSessionAvailable)
            {
               return _windowManager.LilithCustomsInstance.RoomSession;
            }
         }
         catch(rsErr:Error)
         {
         }
         return null;
      }
      
      private function alert(message:String) : void
      {
         try
         {
            if(_windowManager != null && _windowManager.LilithCustomsInstance != null)
            {
               _windowManager.LilithCustomsInstance.ShowWhisperAlert(message);
            }
         }
         catch(aErr:Error)
         {
         }
      }
   }
}
