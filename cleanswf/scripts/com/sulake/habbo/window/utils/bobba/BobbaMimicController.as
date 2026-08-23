package com.sulake.habbo.window.utils.bobba
{
   import com.sulake.core.communication.messages.IMessageComposer;
   import com.sulake.core.window.IWindowController_1;
   import com.sulake.core.window.IWindowModel;
   import com.sulake.core.window.components.IDesktopController;
   import com.sulake.core.window.events.WindowEvent;
   import com.sulake.habbo.communication.messages.outgoing.register.UpdateFigureDataMessageComposer;
   import com.sulake.habbo.communication.messages.outgoing.room.avatar.LookToMessageComposer;
   import com.sulake.habbo.communication.messages.outgoing.room.engine.MoveAvatarMessageComposer;
   import com.sulake.habbo.session.events.RoomSessionChatEvent;
   import com.sulake.habbo.window.HabboWindowManagerComponent;
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import flash.utils.getTimer;
   
   public class BobbaMimicController
   {
      
      private static var _instance:BobbaMimicController;
      
      private var _windowManager:HabboWindowManagerComponent;
      
      private var _editor:BobbaMimicEditor;
      
      private var _tick:Timer;
      
      private var _menuTick:Timer;
      
      private var _targetName:String = "";
      
      private var _targetIndex:int = -1;
      
      private var _targetWebId:int = -1;
      
      private var _optLook:Boolean = false;
      
      private var _optMotto:Boolean = false;
      
      private var _optSpeech:Boolean = false;
      
      private var _optWalk:Boolean = false;
      
      private var _optSit:Boolean = false;
      
      private var _optDance:Boolean = false;
      
      private var _optTyping:Boolean = false;
      
      private var _optAction:Boolean = false;
      
      private var _optUnfollow:Boolean = false;
      
      private var _lastFigure:String = "";
      
      private var _lastMotto:String = "";
      
      private var _lastDance:int = -1;
      
      private var _lastSit:Boolean = false;
      
      private var _lastTyping:Boolean = false;
      
      private var _lastSign:int = -1;
      
      private var _lastExpr:int = -1;
      
      private var _sentWalkX:int = -999;
      
      private var _sentWalkY:int = -999;
      
      private var _walkX:int = 0;
      
      private var _walkY:int = 0;
      
      private var _followPausedUntil:int = 0;
      
      private var _chatHooked:Boolean = false;
      
      private var _ownMoveHooked:Boolean = false;
      
      private var _mimicBtn:IWindowModel;
      
      private var _echoGuard:int = 0;
      
      public function BobbaMimicController(windowManager:HabboWindowManagerComponent)
      {
         super();
         _windowManager = windowManager;
         _instance = this;
         _tick = new Timer(80);
         _tick.addEventListener(TimerEvent.TIMER,onTick);
         _tick.start();
         _menuTick = new Timer(400);
         _menuTick.addEventListener(TimerEvent.TIMER,onMenuTick);
         _menuTick.start();
         hookChat();
      }
      
      public static function install(windowManager:HabboWindowManagerComponent) : BobbaMimicController
      {
         if(_instance != null)
         {
            return _instance;
         }
         if(windowManager == null)
         {
            return null;
         }
         return new BobbaMimicController(windowManager);
      }
      
      public static function get instance() : BobbaMimicController
      {
         return _instance;
      }
      
      public function get targetName() : String
      {
         return _targetName;
      }
      
      public function get targetMotto() : String
      {
         var data:* = null;
         var motto:String = "";
         data = targetUserData();
         if(data != null)
         {
            try
            {
               motto = String(data.custom != null ? data.custom : "");
               if(motto.length == 0 && data.motto != null)
               {
                  motto = String(data.motto);
               }
            }
            catch(mottoReadErr:Error)
            {
            }
         }
         if(motto.length == 0)
         {
            motto = _lastMotto != null ? _lastMotto : "";
         }
         return motto;
      }
      
      public function get targetFigure() : String
      {
         var data:* = targetUserData();
         if(data != null && data.figure != null)
         {
            return String(data.figure);
         }
         return _lastFigure;
      }
      
      public function getOption(key:String) : Boolean
      {
         if(key == "look")
         {
            return _optLook;
         }
         if(key == "motto")
         {
            return _optMotto;
         }
         if(key == "speech")
         {
            return _optSpeech;
         }
         if(key == "walk")
         {
            return _optWalk;
         }
         if(key == "sit")
         {
            return _optSit;
         }
         if(key == "dance")
         {
            return _optDance;
         }
         if(key == "typing")
         {
            return _optTyping;
         }
         if(key == "action")
         {
            return _optAction;
         }
         if(key == "unfollow")
         {
            return _optUnfollow;
         }
         return false;
      }
      
      public function setOption(key:String, value:Boolean) : void
      {
         if(key == "look")
         {
            _optLook = value;
            if(value)
            {
               copyLook();
            }
         }
         else if(key == "motto")
         {
            _optMotto = value;
            if(value)
            {
               copyMotto();
            }
         }
         else if(key == "speech")
         {
            _optSpeech = value;
         }
         else if(key == "walk")
         {
            _optWalk = value;
         }
         else if(key == "sit")
         {
            _optSit = value;
         }
         else if(key == "dance")
         {
            _optDance = value;
         }
         else if(key == "typing")
         {
            _optTyping = value;
         }
         else if(key == "action")
         {
            _optAction = value;
         }
         else if(key == "unfollow")
         {
            _optUnfollow = value;
         }
      }
      
      public function setAllOptions(value:Boolean) : void
      {
         setOption("look",value);
         setOption("motto",value);
         setOption("speech",value);
         setOption("walk",value);
         setOption("sit",value);
         setOption("dance",value);
         setOption("action",value);
         setOption("typing",value);
      }
      
      public function openForName(name:String) : void
      {
         var own:String = ownName();
         if(name == null || name.length == 0)
         {
            alert(BobbaI18n.t("mimic.alert.nouser","Click a user first."));
            return;
         }
         if(own.length > 0 && name.toLowerCase() == own.toLowerCase())
         {
            alert(BobbaI18n.t("mimic.alert.self","You cannot mimic yourself."));
            return;
         }
         _targetName = name;
         cacheTargetIds();
         _lastFigure = "";
         _lastMotto = "";
         _lastDance = -1;
         _lastSit = false;
         _lastSign = -1;
         _lastExpr = -1;
         _sentWalkX = -999;
         _sentWalkY = -999;
         hookChat();
         if(_editor == null)
         {
            _editor = new BobbaMimicEditor(_windowManager,this);
         }
         _editor.visible = true;
         _editor.refresh();
      }
      
      public function onWindowHidden() : void
      {
      }
      
      public function dispose() : void
      {
         if(_tick != null)
         {
            _tick.stop();
            _tick.removeEventListener(TimerEvent.TIMER,onTick);
            _tick = null;
         }
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
      
      private function onTick(e:TimerEvent) : void
      {
         var data:* = null;
         var obj:* = null;
         var loc:* = null;
         var model:* = null;
         var figure:String = "";
         var motto:String = "";
         var dance:int = 0;
         var sitting:Boolean = false;
         var typing:Boolean = false;
         var moving:Boolean = false;
         var actions:String = "";
         var sign:int = -1;
         var expr:int = -1;
         var mv:String = null;
         var parts:Array = null;
         var session:* = null;
         if(_windowManager == null || _targetName == null || _targetName.length == 0)
         {
            return;
         }
         if(_editor == null || !_editor.visible)
         {
            return;
         }
         cacheTargetIds();
         data = targetUserData();
         if(data == null)
         {
            return;
         }
         try
         {
            figure = String(data.figure != null ? data.figure : "");
            motto = String(data.custom != null ? data.custom : "");
            if(motto.length == 0 && data.motto != null)
            {
               motto = String(data.motto);
            }
         }
         catch(dataErr:Error)
         {
         }
         obj = roomObjectFor(data);
         session = roomSession();
         if(obj != null)
         {
            try
            {
               loc = obj.getLocation();
               if(loc != null)
               {
                  _walkX = int(loc.x);
                  _walkY = int(loc.y);
               }
               model = obj.getModel();
               if(model != null)
               {
                  mv = String(model.getString("mv"));
                  actions = String(model.getString("figure_posture") != null ? model.getString("figure_posture") : "");
                  if(mv != null && mv.length > 0 && mv != "null")
                  {
                     parts = mv.split(",");
                     if(parts.length >= 2)
                     {
                        _walkX = int(parts[0]);
                        _walkY = int(parts[1]);
                        moving = true;
                     }
                  }
                  dance = int(model.getNumber("figure_dance"));
                  sitting = actions == "sit" || int(model.getNumber("figure_posture")) == 1;
                  typing = int(model.getNumber("figure_is_typing")) == 1 || int(model.getNumber("figure_typing")) == 1;
                  sign = int(model.getNumber("figure_sign"));
                  expr = int(model.getNumber("figure_expression"));
               }
            }
            catch(objErr:Error)
            {
            }
         }
         if(_optLook && figure.length > 0 && figure != _lastFigure)
         {
            copyLook();
            _lastFigure = figure;
         }
         else if(figure.length > 0)
         {
            _lastFigure = figure;
         }
         if(_optMotto && motto != _lastMotto)
         {
            copyMotto();
            _lastMotto = motto;
         }
         else if(motto.length > 0)
         {
            _lastMotto = motto;
         }
         if(_optWalk && getTimer() >= _followPausedUntil)
         {
            BobbaHotelSend.send(_windowManager,new LookToMessageComposer(_walkX,_walkY));
            if(moving || _walkX != _sentWalkX || _walkY != _sentWalkY)
            {
               BobbaHotelSend.send(_windowManager,new MoveAvatarMessageComposer(_walkX,_walkY));
               _sentWalkX = _walkX;
               _sentWalkY = _walkY;
            }
         }
         if(_optSit && sitting != _lastSit)
         {
            _lastSit = sitting;
            try
            {
               session.sendChangePostureMessage(sitting ? 1 : 0);
            }
            catch(sitErr:Error)
            {
            }
         }
         if(_optDance && dance != _lastDance)
         {
            _lastDance = dance;
            try
            {
               session.sendDanceMessage(dance);
            }
            catch(danceErr:Error)
            {
            }
         }
         if(_optAction && expr > 0 && expr != _lastExpr)
         {
            _lastExpr = expr;
            try
            {
               session.sendAvatarExpressionMessage(expr);
            }
            catch(exprErr:Error)
            {
            }
         }
         if(_optAction && sign > 0 && sign != _lastSign)
         {
            _lastSign = sign;
            sendChatLine(":sign " + String(sign));
         }
         if(_optTyping && typing != _lastTyping)
         {
            _lastTyping = typing;
            try
            {
               session.sendChatTypingMessage(typing);
            }
            catch(typeErr:Error)
            {
            }
         }
      }
      
      private function hookChat() : void
      {
         var events:* = null;
         var session:* = null;
         if(_chatHooked || _windowManager == null)
         {
            return;
         }
         try
         {
            if(_windowManager.roomEngine != null && _windowManager.roomEngine.roomSessionManager != null)
            {
               events = _windowManager.roomEngine.roomSessionManager.events;
               if(events != null)
               {
                  events.addEventListener("RSCE_CHAT_EVENT",onRoomChat);
                  _chatHooked = true;
               }
            }
            session = roomSession();
            if(session != null && session.events != null)
            {
               session.events.addEventListener("RSCE_CHAT_EVENT",onRoomChat);
            }
         }
         catch(hookErr:Error)
         {
         }
      }
      
      private function onRoomChat(evt:RoomSessionChatEvent) : void
      {
         var speaker:* = null;
         var text:String = "";
         var chatType:int = 0;
         var session:* = null;
         var bubble:int = 0;
         if(!_optSpeech || _editor == null || !_editor.visible)
         {
            return;
         }
         if(evt == null || getTimer() < _echoGuard)
         {
            return;
         }
         session = roomSession();
         if(session == null || session.userDataManager == null)
         {
            return;
         }
         try
         {
            text = String(evt.text);
            chatType = int(evt.chatType);
            speaker = session.userDataManager.getUserData(evt.userId);
            if(speaker == null)
            {
               speaker = session.userDataManager.getUserDataByIndex(evt.userId);
            }
         }
         catch(readErr:Error)
         {
            return;
         }
         if(speaker == null || speaker.name == null)
         {
            return;
         }
         if(String(speaker.name).toLowerCase() != _targetName.toLowerCase())
         {
            return;
         }
         if(text == null || text.length == 0)
         {
            return;
         }
         bubble = chatBubble();
         _echoGuard = getTimer() + 80;
         try
         {
            if(chatType == 1)
            {
               session.sendWhisperMessage(_targetName,text,bubble);
            }
            else if(chatType == 2)
            {
               session.sendShoutMessage(text,bubble);
            }
            else
            {
               session.sendChatMessage(text,bubble);
            }
         }
         catch(chatErr:Error)
         {
         }
      }
      
      private function onMenuTick(e:TimerEvent) : void
      {
         var whisper:IWindowModel = null;
         var parent:IWindowController_1 = null;
         var clone:IWindowModel = null;
         var name:String = null;
         hookChat();
         if(_windowManager == null)
         {
            return;
         }
         if(_mimicBtn != null && _mimicBtn.parent != null)
         {
            return;
         }
         whisper = findAvatarMenuWhisper();
         if(whisper == null)
         {
            return;
         }
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
            clone.name = "bobba_mimic";
            clone.caption = BobbaI18n.t("avatar.menu.mimic","Mimic");
            clone.y = whisper.y + whisper.height + 2;
            clone.procedure = onMimicMenuClick;
            parent.addChild(clone as IWindowController_1);
            parent.height = Math.max(parent.height,clone.y + clone.height + 4);
            _mimicBtn = clone;
         }
         catch(menuErr:Error)
         {
         }
      }
      
      private function onMimicMenuClick(event:WindowEvent, target:IWindowModel) : void
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
         while(node != null)
         {
            i = 0;
            while(i < names.length)
            {
               child = node.findChildByName(names[i]);
               if(child != null && child.caption != null && String(child.caption).length > 0)
               {
                  n = String(child.caption);
                  if(n.toLowerCase() != "whisper" && n.toLowerCase() != "mimic" && n.toLowerCase() != "clothes" && n.toLowerCase() != "roupas")
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
         var v:* = null;
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
      
      private function copyLook() : void
      {
         var data:* = targetUserData();
         var figure:String = "";
         var sex:String = "M";
         if(data == null || _windowManager == null || _windowManager.sessionDataManager == null)
         {
            return;
         }
         try
         {
            figure = String(data.figure);
            sex = String(data.sex != null ? data.sex : "M");
         }
         catch(lookErr:Error)
         {
            return;
         }
         if(figure == null || figure.length == 0)
         {
            return;
         }
         try
         {
            _windowManager.sessionDataManager.send(new UpdateFigureDataMessageComposer(figure,sex));
         }
         catch(sendLookErr:Error)
         {
         }
      }
      
      private function copyMotto() : void
      {
         var data:* = targetUserData();
         var motto:String = "";
         if(data == null)
         {
            return;
         }
         try
         {
            motto = String(data.custom != null ? data.custom : "");
            if(motto.length == 0 && data.motto != null)
            {
               motto = String(data.motto);
            }
         }
         catch(mottoErr:Error)
         {
            return;
         }
         sendNamed("com.sulake.habbo.communication.messages.outgoing.room.avatar.ChangeMottoMessageComposer",[motto]);
         sendNamed("com.sulake.habbo.communication.messages.outgoing.users.ChangeMottoMessageComposer",[motto]);
      }
      
      private function sendChatLine(text:String) : void
      {
         var session:* = roomSession();
         if(session == null || text == null || text.length == 0)
         {
            return;
         }
         try
         {
            session.sendChatMessage(text,chatBubble());
         }
         catch(lineErr:Error)
         {
         }
      }
      
      private function chatBubble() : int
      {
         try
         {
            if(_windowManager != null && _windowManager.roomEngine != null)
            {
               return int(_windowManager.roomEngine.toolbar.freeFlowChat.preferedChatStyle);
            }
         }
         catch(bubErr:Error)
         {
         }
         return 0;
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
      
      private function sendNamed(className:String, args:Array) : void
      {
         var cls:Class = null;
         var composer:* = null;
         try
         {
            cls = getDefinitionByName(className) as Class;
            if(cls == null)
            {
               return;
            }
            if(args == null || args.length == 0)
            {
               composer = new cls() as IMessageComposer;
            }
            else if(args.length == 1)
            {
               composer = new cls(args[0]) as IMessageComposer;
            }
            else if(args.length == 2)
            {
               composer = new cls(args[0],args[1]) as IMessageComposer;
            }
            else
            {
               composer = new cls(args[0],args[1],args[2]) as IMessageComposer;
            }
            BobbaHotelSend.send(_windowManager,composer as IMessageComposer);
         }
         catch(sendErr:Error)
         {
         }
      }
      
      private function cacheTargetIds() : void
      {
         var data:* = targetUserData();
         if(data == null)
         {
            return;
         }
         try
         {
            _targetWebId = int(data.webID);
         }
         catch(idErr:Error)
         {
         }
         try
         {
            _targetIndex = int(data.roomObjectId);
         }
         catch(idxErr:Error)
         {
         }
      }
      
      private function targetUserData() : *
      {
         var session:* = null;
         var data:* = null;
         var selectedId:int = -1;
         try
         {
            session = roomSession();
            if(session == null || session.userDataManager == null)
            {
               return null;
            }
            data = session.userDataManager.getUserDataByName(_targetName);
            if(data != null)
            {
               return data;
            }
            if(_windowManager != null && _windowManager.roomEngine != null)
            {
               selectedId = int(_windowManager.roomEngine.getSelectedAvatarId());
               if(selectedId > -1)
               {
                  data = session.userDataManager.getUserDataByIndex(selectedId);
                  if(data != null && data.name != null && String(data.name).toLowerCase() == _targetName.toLowerCase())
                  {
                     return data;
                  }
               }
            }
         }
         catch(udErr:Error)
         {
         }
         return null;
      }
      
      private function roomObjectFor(data:*) : *
      {
         var session:* = null;
         try
         {
            session = roomSession();
            return _windowManager.roomEngine.getRoomObject(int(session.roomId),int(data.roomObjectId),100);
         }
         catch(roErr:Error)
         {
         }
         return null;
      }
      
      private function ownName() : String
      {
         try
         {
            if(_windowManager != null && _windowManager.sessionDataManager != null)
            {
               return String(_windowManager.sessionDataManager.userName);
            }
         }
         catch(ownErr:Error)
         {
         }
         return "";
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
