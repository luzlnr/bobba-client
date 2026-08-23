package com.sulake.habbo.window.utils.bobba
{
   import com.sulake.habbo.window.HabboWindowManagerComponent;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.utils.Dictionary;
   
   public class BobbaClothesCatalog
   {
      
      private static const CLOTHING_CATEGORY:int = 23;
      
      private static const SLOT_ORDER:Array = ["ha","he","ea","fa","hr","hd","ch","cc","ca","cp","lg","sh","wa"];
      
      private static var _namesBySetId:Dictionary;
      
      private static var _furniBySetId:Dictionary;
      
      private static var _classBySetId:Dictionary;
      
      private static var _loading:Boolean = false;
      
      private static var _readyCallbacks:Array = [];
      
      public function BobbaClothesCatalog()
      {
         super();
      }
      
      public static function parts(windowManager:HabboWindowManagerComponent, figure:String) : Array
      {
         var map:Dictionary = null;
         var raw:Array = null;
         var type:String = "";
         var seen:Dictionary = new Dictionary();
         var out:Array = [];
         var ordered:Array = [];
         var i:int = 0;
         var token:String = "";
         var bits:Array = null;
         var setId:int = 0;
         var furniId:int = 0;
         var className:String = "";
         var name:String = "";
         if(figure == null || figure.length == 0)
         {
            return out;
         }
         ensureIndex(windowManager,null);
         map = _namesBySetId != null ? _namesBySetId : new Dictionary();
         raw = figure.split(".");
         i = 0;
         while(i < raw.length)
         {
            token = String(raw[i]);
            bits = token.split("-");
            if(bits.length >= 2)
            {
               type = String(bits[0]);
               setId = int(parseInt(String(bits[1])));
               if(type.length > 0 && setId > 0 && seen[type] == null)
               {
                  seen[type] = true;
                  name = map[setId] != null ? String(map[setId]) : "";
                  furniId = _furniBySetId != null && _furniBySetId[setId] != null ? int(_furniBySetId[setId]) : 0;
                  className = _classBySetId != null && _classBySetId[setId] != null ? String(_classBySetId[setId]) : "";
                  out.push({
                     "type":type,
                     "token":token,
                     "setId":setId,
                     "name":name,
                     "catalog":name.length > 0,
                     "furniId":furniId,
                     "className":className
                  });
               }
            }
            i++;
         }
         i = 0;
         while(i < SLOT_ORDER.length)
         {
            appendType(out,ordered,String(SLOT_ORDER[i]));
            i++;
         }
         i = 0;
         while(i < out.length)
         {
            if(!containsType(ordered,String(out[i].type)))
            {
               ordered.push(out[i]);
            }
            i++;
         }
         return ordered;
      }
      
      public static function pieceFigure(full:String, token:String) : String
      {
         var hd:String = "";
         var type:String = "";
         var bits:Array = null;
         if(token == null || token.length == 0)
         {
            return full != null ? full : "";
         }
         bits = token.split("-");
         type = bits.length > 0 ? String(bits[0]) : "";
         hd = extractType(full,"hd");
         if(type == "hd" || hd.length == 0)
         {
            return token;
         }
         return hd + "." + token;
      }
      
      public static function slotLabel(type:String) : String
      {
         return BobbaI18n.t("clothes.slot." + type,type);
      }
      
      public static function ensureIndex(windowManager:HabboWindowManagerComponent, onReady:Function) : void
      {
         if(onReady != null)
         {
            _readyCallbacks.push(onReady);
         }
         if(_namesBySetId != null)
         {
            fireReady();
            return;
         }
         indexFromSession(windowManager);
         if(_namesBySetId != null)
         {
            fireReady();
            return;
         }
         loadFromGamedata(windowManager);
      }
      
      private static function fireReady() : void
      {
         var list:Array = _readyCallbacks;
         var i:int = 0;
         var cb:Function = null;
         _readyCallbacks = [];
         i = 0;
         while(i < list.length)
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
            i++;
         }
      }
      
      private static function extractType(figure:String, type:String) : String
      {
         var raw:Array = null;
         var i:int = 0;
         var token:String = "";
         if(figure == null || type == null)
         {
            return "";
         }
         raw = figure.split(".");
         i = 0;
         while(i < raw.length)
         {
            token = String(raw[i]);
            if(token.indexOf(type + "-") == 0)
            {
               return token;
            }
            i++;
         }
         return "";
      }
      
      private static function appendType(src:Array, dest:Array, type:String) : void
      {
         var i:int = 0;
         while(i < src.length)
         {
            if(String(src[i].type) == type)
            {
               dest.push(src[i]);
               return;
            }
            i++;
         }
      }
      
      private static function containsType(list:Array, type:String) : Boolean
      {
         var i:int = 0;
         while(i < list.length)
         {
            if(String(list[i].type) == type)
            {
               return true;
            }
            i++;
         }
         return false;
      }
      
      private static function indexFromSession(windowManager:HabboWindowManagerComponent) : void
      {
         var items:Array = null;
         var i:int = 0;
         var data:* = undefined;
         var raw:String = "";
         var label:String = "";
         var mapped:int = 0;
         items = collectFurniture(windowManager);
         if(items == null || items.length == 0)
         {
            return;
         }
         _namesBySetId = new Dictionary();
         _furniBySetId = new Dictionary();
         i = 0;
         while(i < items.length)
         {
            data = items[i];
            if(data != null && isClothing(data))
            {
               raw = customParamsOf(data);
               label = nameOf(data,windowManager);
               mapped += mapParams(raw,label,typeIdOf(data),classNameOf(data));
            }
            i++;
         }
         if(mapped == 0)
         {
            _namesBySetId = null;
            _furniBySetId = null;
         }
      }
      
      private static function mapParams(raw:String, label:String, typeId:int = 0, className:String = "") : int
      {
         var ids:Array = null;
         var n:int = 0;
         var setId:int = 0;
         var mapped:int = 0;
         if(raw == null || raw.length == 0 || label == null || label.length == 0)
         {
            return 0;
         }
         if(_namesBySetId == null)
         {
            _namesBySetId = new Dictionary();
         }
         if(_furniBySetId == null)
         {
            _furniBySetId = new Dictionary();
         }
         if(_classBySetId == null)
         {
            _classBySetId = new Dictionary();
         }
         ids = raw.split(",");
         n = 0;
         while(n < ids.length)
         {
            setId = int(parseInt(String(ids[n])));
            if(setId > 0)
            {
               if(_namesBySetId[setId] == null || String(_namesBySetId[setId]).length < label.length)
               {
                  _namesBySetId[setId] = label;
                  if(typeId > 0)
                  {
                     _furniBySetId[setId] = typeId;
                  }
                  if(className != null && className.length > 0)
                  {
                     _classBySetId[setId] = className;
                  }
                  mapped++;
               }
            }
            n++;
         }
         return mapped;
      }
      
      private static function classNameOf(data:*) : String
      {
         try
         {
            if(data.className != null)
            {
               return String(data.className);
            }
         }
         catch(cnErr:Error)
         {
         }
         return "";
      }
      
      private static function typeIdOf(data:*) : int
      {
         try
         {
            return int(data.id);
         }
         catch(idErr:Error)
         {
         }
         return 0;
      }
      
      private static function isClothing(data:*) : Boolean
      {
         var className:String = "";
         try
         {
            if(int(data.category) == CLOTHING_CATEGORY)
            {
               return true;
            }
         }
         catch(catErr:Error)
         {
         }
         try
         {
            className = String(data.className != null ? data.className : "");
         }
         catch(cnErr:Error)
         {
         }
         if(className.toLowerCase().indexOf("clothing") >= 0)
         {
            return true;
         }
         return looksLikeSetList(customParamsOf(data));
      }
      
      private static function looksLikeSetList(raw:String) : Boolean
      {
         var i:int = 0;
         var ch:String = "";
         if(raw == null || raw.length == 0)
         {
            return false;
         }
         i = 0;
         while(i < raw.length)
         {
            ch = raw.charAt(i);
            if(ch != "," && (ch < "0" || ch > "9"))
            {
               return false;
            }
            i++;
         }
         return int(parseInt(raw)) > 0;
      }
      
      private static function customParamsOf(data:*) : String
      {
         var raw:String = "";
         try
         {
            raw = String(data.customParams != null ? data.customParams : "");
         }
         catch(a:Error)
         {
         }
         if(raw.length == 0)
         {
            try
            {
               raw = String(data.customParam != null ? data.customParam : "");
            }
            catch(b:Error)
            {
            }
         }
         if(raw.length == 0)
         {
            try
            {
               raw = String(data.customparams != null ? data.customparams : "");
            }
            catch(c:Error)
            {
            }
         }
         return raw != null && raw != "null" ? raw : "";
      }
      
      private static function nameOf(data:*, windowManager:HabboWindowManagerComponent) : String
      {
         var label:String = "";
         var className:String = "";
         var product:* = undefined;
         try
         {
            label = String(data.name != null ? data.name : "");
         }
         catch(a:Error)
         {
         }
         if(label.length == 0)
         {
            try
            {
               label = String(data.localizedName != null ? data.localizedName : "");
            }
            catch(b:Error)
            {
            }
         }
         try
         {
            className = String(data.className != null ? data.className : "");
         }
         catch(c:Error)
         {
         }
         if((label.length == 0 || label == className) && windowManager != null && windowManager.sessionDataManager != null && className.length > 0)
         {
            try
            {
               product = windowManager.sessionDataManager.getProductData(className);
               if(product != null && product.name != null && String(product.name).length > 0)
               {
                  label = String(product.name);
               }
            }
            catch(pErr:Error)
            {
            }
         }
         if(label.length == 0)
         {
            label = className;
         }
         return label;
      }
      
      private static function collectFurniture(windowManager:HabboWindowManagerComponent) : Array
      {
         var session:* = undefined;
         var bag:* = undefined;
         var item:* = undefined;
         var out:Array = [];
         var i:int = 0;
         var data:* = undefined;
         var gap:int = 0;
         if(windowManager == null || windowManager.sessionDataManager == null)
         {
            return out;
         }
         session = windowManager.sessionDataManager;
         bag = tryCall1(session,"getAllFurnitureData",null);
         if(bag == null)
         {
            bag = tryCall(session,"getAllFurnitureData");
         }
         if(bag is Array && (bag as Array).length > 0)
         {
            return bag as Array;
         }
         if(bag != null && !(bag is Array))
         {
            for each(item in bag)
            {
               if(item != null)
               {
                  out.push(item);
               }
            }
            if(out.length > 0)
            {
               return out;
            }
         }
         i = 0;
         gap = 0;
         while(i < 180000 && (out.length == 0 && i < 80000 || out.length > 0 && gap < 25000))
         {
            i++;
            data = null;
            try
            {
               data = session.getFloorItemData(i);
            }
            catch(idErr:Error)
            {
            }
            if(data != null)
            {
               out.push(data);
               gap = 0;
            }
            else
            {
               gap++;
            }
         }
         return out;
      }
      
      private static function loadFromGamedata(windowManager:HabboWindowManagerComponent) : void
      {
         var loader:URLLoader = null;
         var url:String = "";
         if(_loading)
         {
            return;
         }
         url = gamedataUrl(windowManager,"furnidata_json");
         if(url.length == 0)
         {
            return;
         }
         _loading = true;
         loader = new URLLoader();
         loader.addEventListener(Event.COMPLETE,onFurniJson);
         loader.addEventListener(IOErrorEvent.IO_ERROR,onGamedataFail);
         try
         {
            loader.load(new URLRequest(url));
         }
         catch(loadErr:Error)
         {
            _loading = false;
         }
      }
      
      private static function onFurniJson(e:Event) : void
      {
         var loader:URLLoader = null;
         var text:String = "";
         var data:Object = null;
         var list:* = undefined;
         var i:int = 0;
         var row:Object = null;
         var mapped:int = 0;
         loader = e != null ? e.target as URLLoader : null;
         _loading = false;
         if(loader == null)
         {
            fireReady();
            return;
         }
         text = String(loader.data);
         try
         {
            data = JSON.parse(text);
         }
         catch(jsonErr:Error)
         {
            fireReady();
            return;
         }
         _namesBySetId = new Dictionary();
         if(data != null && data.roomitemtypes != null)
         {
            list = data.roomitemtypes.furnitype;
         }
         if(list != null)
         {
            i = 0;
            while(i < list.length)
            {
               row = list[i] as Object;
               if(row != null && isJsonClothing(row))
               {
                  mapped += mapParams(String(row.customparams != null ? row.customparams : ""),String(row.name != null ? row.name : ""),int(row.id),String(row.classname != null ? row.classname : ""));
               }
               i++;
            }
         }
         if(mapped == 0)
         {
            _namesBySetId = null;
            _furniBySetId = null;
         }
         fireReady();
         fireReady();
      }
      
      private static function isJsonClothing(row:Object) : Boolean
      {
         var className:String = "";
         var category:* = undefined;
         if(row == null)
         {
            return false;
         }
         className = String(row.classname != null ? row.classname : "");
         category = row.category;
         if(className.toLowerCase().indexOf("clothing") >= 0)
         {
            return true;
         }
         if(int(category) == CLOTHING_CATEGORY || String(category) == "23")
         {
            return true;
         }
         return looksLikeSetList(String(row.customparams != null ? row.customparams : ""));
      }
      
      private static function onGamedataFail(e:Event) : void
      {
         _loading = false;
         fireReady();
      }
      
      private static function gamedataUrl(windowManager:HabboWindowManagerComponent, kind:String) : String
      {
         var hotel:String = "";
         var host:String = "";
         hotel = BobbaI18n.hotelId;
         if(hotel == "hhbr")
         {
            host = "https://www.habbo.com.br";
         }
         else if(hotel == "hhes")
         {
            host = "https://www.habbo.es";
         }
         else if(hotel == "hhfr")
         {
            host = "https://www.habbo.fr";
         }
         else if(hotel == "hhde")
         {
            host = "https://www.habbo.de";
         }
         else if(hotel == "hhit")
         {
            host = "https://www.habbo.it";
         }
         else if(hotel == "hhnl")
         {
            host = "https://www.habbo.nl";
         }
         else if(hotel == "hhfi")
         {
            host = "https://www.habbo.fi";
         }
         else if(hotel == "hhtr")
         {
            host = "https://www.habbo.com.tr";
         }
         else
         {
            host = "https://www.habbo.com";
         }
         return host + "/gamedata/" + kind + "/1";
      }
      
      private static function tryCall(host:*, method:String) : *
      {
         var result:* = undefined;
         if(host == null || method == null)
         {
            return null;
         }
         try
         {
            if(host[method] is Function)
            {
               result = host[method]();
               return result;
            }
         }
         catch(err:Error)
         {
         }
         return null;
      }
      
      private static function tryCall1(host:*, method:String, arg:*) : *
      {
         var result:* = undefined;
         if(host == null || method == null)
         {
            return null;
         }
         try
         {
            if(host[method] is Function)
            {
               result = host[method](arg);
               return result;
            }
         }
         catch(err:Error)
         {
         }
         return null;
      }
   }
}
