package com.sulake.habbo.window.utils.bobba
{
   import com.sulake.core.utils.FontEnum;
   import com.sulake.habbo.avatar.UnknownIHabboAvatar1;
   import com.sulake.habbo.window.HabboWindowManagerComponent;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.PixelSnapping;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.Dictionary;
   import flash.utils.Timer;
   
   public class BobbaClothesView extends Sprite implements com.sulake.habbo.avatar.UnknownIHabboAvatar1
   {
      
      public static var VIEW_W:int = 300;
      
      public static var VIEW_H:int = 230;
      
      private static const FONT_REGULAR:String = "Ubuntu";
      
      private static const FONT_BOLD:String = "Ubuntu bold";
      
      private static const ICON:int = 48;
      
      private static var _thumbByToken:Dictionary;
      
      private static const THUMB_DIRS:Array = [2,6,0,4,3,1];
      
      private static const DRAW_ORDER:Array = ["li","lh","ls","lc","mcl","ptl","bd","sh","lg","ch","ca","cc","cp","mc","pt","wa","rh","rs","rc","mcr","ptr","hd","fc","ey","hr","hrb","fa","ea","ha","he","ri"];
      
      private static const HEAD_TYPES:Array = ["hd","hr","hrb","ha","he","ea","fa","ey","fc"];
      
      private var _controller:BobbaClothesController;
      
      private var _windowManager:HabboWindowManagerComponent;
      
      private var _nameField:TextField;
      
      private var _mask:Sprite;
      
      private var _list:Sprite;
      
      private var _scroll:int = 0;
      
      private var _contentH:int = 0;
      
      private var _tip:Sprite;
      
      private var _tipField:TextField;
      
      private var _figureRetry:Timer;
      
      public function BobbaClothesView(controller:BobbaClothesController, windowManager:HabboWindowManagerComponent)
      {
         super();
         _controller = controller;
         _windowManager = windowManager;
         if(_thumbByToken == null)
         {
            _thumbByToken = new Dictionary();
         }
         _nameField = makeText("",14,16777215,true,VIEW_W - 8);
         _nameField.x = 4;
         _nameField.y = 4;
         addChild(_nameField);
         _mask = new Sprite();
         _mask.graphics.beginFill(16777215,1);
         _mask.graphics.drawRect(0,0,VIEW_W,VIEW_H - 22);
         _mask.graphics.endFill();
         _mask.y = 22;
         addChild(_mask);
         _list = new Sprite();
         _list.y = 22;
         _list.mask = _mask;
         addChild(_list);
         _tipField = makeText("",11,16777215,true,220);
         _tipField.x = 6;
         _tipField.y = 4;
         _tipField.width = 220;
         _tip = new Sprite();
         _tip.mouseEnabled = false;
         _tip.mouseChildren = false;
         _tip.visible = false;
         _tip.addChild(_tipField);
         addChild(_tip);
         addEventListener(MouseEvent.MOUSE_WHEEL,onWheel);
         rebuildMask();
         BobbaClothesCatalog.ensureIndex(_windowManager,refresh);
      }
      
      public function setSize(w:int, h:int) : void
      {
         if(w < 80)
         {
            w = 80;
         }
         if(h < 80)
         {
            h = 80;
         }
         VIEW_W = w;
         VIEW_H = h;
         _nameField.width = w - 8;
         rebuildMask();
         refresh();
      }
      
      private function rebuildMask() : void
      {
         if(_mask == null)
         {
            return;
         }
         _mask.graphics.clear();
         _mask.graphics.beginFill(16777215,1);
         _mask.graphics.drawRect(0,0,VIEW_W,VIEW_H - 22);
         _mask.graphics.endFill();
         _mask.y = 22;
         if(_list != null)
         {
            _list.y = 22;
         }
      }
      
      public function get disposed() : Boolean
      {
         return _controller == null;
      }
      
      public function avatarImageReady(figure:String) : void
      {
         if(_controller == null)
         {
            return;
         }
         refresh();
      }
      
      public function dispose() : void
      {
         removeEventListener(MouseEvent.MOUSE_WHEEL,onWheel);
         stopFigureRetry();
         clearRows();
         _controller = null;
         _windowManager = null;
      }
      
      public function refresh() : void
      {
         var parts:Array = null;
         var i:int = 0;
         var px:int = 0;
         var py:int = 0;
         if(_controller == null)
         {
            return;
         }
         _nameField.text = _controller.targetName != null && _controller.targetName.length > 0 ? _controller.targetName : BobbaI18n.t("clothes.nobody","Click a user");
         hideTip();
         clearRows();
         parts = _controller.parts;
         px = 0;
         py = 0;
         i = 0;
         while(i < parts.length)
         {
            if(px + ICON + 12 > VIEW_W)
            {
               px = 0;
               py += ICON + 12;
            }
            _list.addChild(makeRow(parts[i],px,py));
            px += ICON + 12;
            i++;
         }
         _contentH = py + ICON + 12;
         _list.y = 22 - _scroll;
      }
      
      private function clearRows() : void
      {
         while(_list != null && _list.numChildren > 0)
         {
            _list.removeChildAt(0);
         }
      }
      
      private function makeRow(part:Object, x:int, y:int) : Sprite
      {
         var row:Sprite = new Sprite();
         var well:Sprite = new Sprite();
         var bmp:BitmapData = null;
         var pic:Bitmap = null;
         var title:String = "";
         row.x = x;
         row.y = y;
         row.buttonMode = true;
         row.mouseChildren = false;
         well.graphics.lineStyle(1,13158600,1);
         well.graphics.beginFill(2700082,1);
         well.graphics.drawRoundRect(0,0,ICON + 8,ICON + 8,8,8);
         well.graphics.endFill();
         row.addChild(well);
         bmp = renderPiece(part);
         if(bmp != null)
         {
            pic = new Bitmap(bmp);
            pic.smoothing = false;
            pic.pixelSnapping = PixelSnapping.ALWAYS;
            pic.x = 4;
            pic.y = 4;
            row.addChild(pic);
         }
         title = Boolean(part.catalog) && String(part.name).length > 0 ? String(part.name) : BobbaClothesCatalog.slotLabel(String(part.type));
         if(Boolean(part.catalog) && String(part.name).length > 0)
         {
            title = String(part.name) + "\n" + BobbaClothesCatalog.slotLabel(String(part.type));
         }
         row.name = title;
         overlayBadges(row,part);
         row.addEventListener(MouseEvent.ROLL_OVER,onRowOver);
         row.addEventListener(MouseEvent.ROLL_OUT,onRowOut);
         row.addEventListener(MouseEvent.MOUSE_MOVE,onRowMove);
         return row;
      }
      
      private function renderPiece(part:Object) : BitmapData
      {
         var src:BitmapData = null;
         var out:BitmapData = null;
         var m:Matrix = null;
         var scale:Number = 1;
         var token:String = "";
         if(_windowManager == null || part == null)
         {
            return null;
         }
         token = String(part.token != null ? part.token : "");
         if(_thumbByToken != null && _thumbByToken[token] is BitmapData)
         {
            src = _thumbByToken[token] as BitmapData;
         }
         if(src == null)
         {
            src = renderEditorThumb(String(part.type != null ? part.type : ""),token);
            if(src != null)
            {
               _thumbByToken[token] = src;
            }
            else
            {
               startFigureRetry();
            }
         }
         if(src == null || src.width < 1 || src.height < 1)
         {
            return null;
         }
         scale = Math.min(ICON / src.width,ICON / src.height);
         if(scale > 1)
         {
            scale = 1;
         }
         out = new BitmapData(ICON,ICON,true,0);
         m = new Matrix();
         m.scale(scale,scale);
         m.translate(Math.round((ICON - src.width * scale) / 2),Math.round((ICON - src.height * scale) / 2));
         out.draw(src,m,null,null,null,false);
         return out;
      }
      
      private function renderEditorThumb(type:String, token:String) : BitmapData
      {
         var renderer:* = undefined;
         var bits:Array = null;
         var setId:int = 0;
         var container:* = undefined;
         var partSet:* = undefined;
         var parts:Array = null;
         var dir:int = 2;
         var ready:Boolean = false;
         var i:int = 0;
         var part:* = undefined;
         var assetName:String = "";
         var asset:* = undefined;
         var layer:BitmapData = null;
         var bounds:Rectangle = null;
         var canvas:BitmapData = null;
         var ox:int = 0;
         var oy:int = 0;
         var rect:Rectangle = null;
         var colors:Array = null;
         var tint:ColorTransform = null;
         var layerIndex:int = 0;
         var drawRect:Rectangle = null;
         if(type == null || type.length == 0 || token == null)
         {
            return null;
         }
         bits = token.split("-");
         if(bits.length < 2)
         {
            return null;
         }
         setId = int(parseInt(String(bits[1])));
         if(setId <= 0)
         {
            return null;
         }
         try
         {
            renderer = _windowManager.avatarRenderer;
            if(renderer == null)
            {
               return null;
            }
            container = renderer.createFigureContainer(type + "-" + setId);
            if(container != null && renderer.isFigureReady(container) != true)
            {
               renderer.downloadFigure(container,this);
               return null;
            }
            partSet = figurePartSet(renderer,type,setId);
            parts = [];
            if(partSet != null && partSet.parts != null)
            {
               for each(part in partSet.parts)
               {
                  parts.push(part);
               }
            }
            if(isHeadType(type) && parts.length > 0)
            {
               parts = filterHeadParts(parts);
            }
            if(parts.length == 0)
            {
               parts = [{
                  "type":type,
                  "id":setId
               }];
            }
            parts.sort(sortDrawOrder);
            colors = partColors(renderer,type,bits);
            dir = 2;
            i = 0;
            while(i < THUMB_DIRS.length)
            {
               if(partAsset(renderer,parts,int(THUMB_DIRS[i])) != null)
               {
                  dir = int(THUMB_DIRS[i]);
                  ready = true;
                  break;
               }
               i++;
            }
            if(!ready)
            {
               return null;
            }
            bounds = new Rectangle();
            i = 0;
            while(i < parts.length)
            {
               part = parts[i];
               asset = partAsset(renderer,[{"type":String(part.type),"id":int(part.id)}],dir);
               if(asset != null)
               {
                  rect = assetRectangle(asset);
                  if(rect != null)
                  {
                     if(bounds.width < 1)
                     {
                        bounds = rect.clone();
                     }
                     else
                     {
                        bounds = bounds.union(rect);
                     }
                  }
               }
               i++;
            }
            if(bounds.width < 1 || bounds.height < 1)
            {
               return null;
            }
            canvas = new BitmapData(int(bounds.width),int(bounds.height),true,0);
            i = 0;
            while(i < parts.length)
            {
               part = parts[i];
               asset = partAsset(renderer,[{"type":String(part.type),"id":int(part.id)}],dir);
               layer = assetBitmap(asset);
               if(asset != null && layer != null)
               {
                  ox = int(-1 * Number(asset.offset.x) - bounds.x);
                  oy = int(-1 * Number(asset.offset.y) - bounds.y);
                  tint = null;
                  layerIndex = 0;
                  try
                  {
                     layerIndex = int(part.colorLayerIndex);
                  }
                  catch(layerErr:Error)
                  {
                     layerIndex = 0;
                  }
                  if(layerIndex > 0 && colors != null && layerIndex - 1 < colors.length && colors[layerIndex - 1] != null)
                  {
                     tint = colors[layerIndex - 1] as ColorTransform;
                  }
                  if(tint != null)
                  {
                     drawRect = new Rectangle(ox,oy,asset.rectangle != null ? int(asset.rectangle.width) : layer.width,asset.rectangle != null ? int(asset.rectangle.height) : layer.height);
                     canvas.draw(layer,new Matrix(1,0,0,1,ox - (asset.rectangle != null ? Number(asset.rectangle.x) : 0),oy - (asset.rectangle != null ? Number(asset.rectangle.y) : 0)),tint,null,drawRect);
                  }
                  else
                  {
                     canvas.copyPixels(layer,asset.rectangle != null ? asset.rectangle as Rectangle : layer.rect,new Point(ox,oy),null,null,true);
                  }
               }
               i++;
            }
            return canvas;
         }
         catch(thumbErr:Error)
         {
         }
         return null;
      }
      
      private function sortDrawOrder(a:Object, b:Object) : int
      {
         var ia:int = DRAW_ORDER.indexOf(String(a.type));
         var ib:int = DRAW_ORDER.indexOf(String(b.type));
         if(ia < 0)
         {
            ia = 99;
         }
         if(ib < 0)
         {
            ib = 99;
         }
         if(ia < ib)
         {
            return -1;
         }
         if(ia > ib)
         {
            return 1;
         }
         return 0;
      }
      
      private function figurePartSet(renderer:*, type:String, setId:int) : *
      {
         var data:* = undefined;
         var setType:* = undefined;
         var partSet:* = undefined;
         try
         {
            data = renderer.getFigureData();
            if(data != null)
            {
               setType = data.getSetType(type);
               if(setType != null)
               {
                  return setType.getPartSet(setId);
               }
            }
         }
         catch(setErr:Error)
         {
         }
         return null;
      }
      
      private function partAsset(renderer:*, parts:Array, dir:int) : *
      {
         var i:int = 0;
         var part:* = undefined;
         var name:String = "";
         var asset:* = undefined;
         if(renderer == null || parts == null)
         {
            return null;
         }
         i = 0;
         while(i < parts.length)
         {
            part = parts[i];
            name = "h_std_" + String(part.type) + "_" + String(part.id) + "_" + dir + "_0";
            try
            {
               asset = renderer.getAssetByName(name);
            }
            catch(a:Error)
            {
               asset = null;
            }
            if(asset == null)
            {
               try
               {
                  if(renderer.assets != null)
                  {
                     asset = renderer.assets.getAssetByName(name);
                  }
               }
               catch(a2:Error)
               {
                  asset = null;
               }
            }
            if(asset != null && (asset.content != null || asset.bitmap != null))
            {
               return asset;
            }
            i++;
         }
         return null;
      }
      
      private function assetBitmap(asset:*) : BitmapData
      {
         try
         {
            if(asset != null && asset.content is BitmapData)
            {
               return asset.content as BitmapData;
            }
            if(asset != null && asset.bitmap is BitmapData)
            {
               return asset.bitmap as BitmapData;
            }
         }
         catch(b:Error)
         {
         }
         return null;
      }
      
      private function assetRectangle(asset:*) : Rectangle
      {
         var rect:Rectangle = null;
         try
         {
            rect = new Rectangle(-1 * Number(asset.offset.x),-1 * Number(asset.offset.y),asset.rectangle.width,asset.rectangle.height);
            return rect;
         }
         catch(rErr:Error)
         {
         }
         return null;
      }
      
      private function startFigureRetry() : void
      {
         if(_figureRetry != null)
         {
            return;
         }
         _figureRetry = new Timer(300,40);
         _figureRetry.addEventListener(TimerEvent.TIMER,onFigureRetry);
         _figureRetry.addEventListener(TimerEvent.TIMER_COMPLETE,onFigureRetryDone);
         _figureRetry.start();
      }
      
      private function stopFigureRetry() : void
      {
         if(_figureRetry == null)
         {
            return;
         }
         _figureRetry.stop();
         _figureRetry.removeEventListener(TimerEvent.TIMER,onFigureRetry);
         _figureRetry.removeEventListener(TimerEvent.TIMER_COMPLETE,onFigureRetryDone);
         _figureRetry = null;
      }
      
      private function onFigureRetry(e:TimerEvent) : void
      {
         refresh();
      }
      
      private function onFigureRetryDone(e:TimerEvent) : void
      {
         stopFigureRetry();
      }
      
      private function onWheel(e:MouseEvent) : void
      {
         var max:int = 0;
         var viewH:int = VIEW_H - 22;
         if(_contentH <= viewH)
         {
            return;
         }
         _scroll -= e.delta * 24;
         max = _contentH - viewH;
         if(_scroll < 0)
         {
            _scroll = 0;
         }
         if(_scroll > max)
         {
            _scroll = max;
         }
         _list.y = 22 - _scroll;
      }
      
      private function makeText(textValue:String, size:int, color:uint, bold:Boolean, width:int) : TextField
      {
         var field:TextField = new TextField();
         var fmt:TextFormat = new TextFormat();
         var fontName:String = bold ? FONT_BOLD : FONT_REGULAR;
         field.selectable = false;
         field.mouseEnabled = false;
         field.width = width;
         field.multiline = true;
         field.wordWrap = true;
         field.autoSize = TextFieldAutoSize.NONE;
         if(FontEnum.isEmbeddedFont(fontName))
         {
            fmt.font = fontName;
            fmt.bold = false;
            field.embedFonts = true;
            field.antiAliasType = "advanced";
            field.gridFitType = "pixel";
         }
         else
         {
            fmt.font = "Verdana";
            fmt.bold = bold;
         }
         fmt.size = size;
         fmt.color = color;
         field.defaultTextFormat = fmt;
         field.text = textValue != null ? textValue : "";
         field.height = field.textHeight + 6;
         return field;
      }
      
      private function onRowOver(e:MouseEvent) : void
      {
         var row:Sprite = e != null ? e.currentTarget as Sprite : null;
         if(row == null)
         {
            return;
         }
         showTip(String(row.name),e.localX + row.x,e.localY + row.y + 22);
      }
      
      private function onRowMove(e:MouseEvent) : void
      {
         var row:Sprite = e != null ? e.currentTarget as Sprite : null;
         if(row == null || _tip == null || !_tip.visible)
         {
            return;
         }
         placeTip(e.localX + row.x,e.localY + row.y + 22);
      }
      
      private function onRowOut(e:MouseEvent) : void
      {
         hideTip();
      }
      
      private function showTip(text:String, x:Number, y:Number) : void
      {
         if(_tip == null || _tipField == null)
         {
            return;
         }
         _tipField.text = text != null ? text : "";
         _tipField.height = _tipField.textHeight + 8;
         _tip.graphics.clear();
         _tip.graphics.beginFill(0,0.85);
         _tip.graphics.drawRoundRect(0,0,Math.min(228,_tipField.textWidth + 16),_tipField.height + 4,8,8);
         _tip.graphics.endFill();
         _tip.visible = true;
         placeTip(x,y);
      }
      
      private function placeTip(x:Number, y:Number) : void
      {
         if(_tip == null)
         {
            return;
         }
         _tip.x = Math.max(0,Math.min(x + 10,VIEW_W - _tip.width - 2));
         _tip.y = Math.max(0,Math.min(y + 12,VIEW_H - _tip.height - 2));
      }
      
      private function hideTip() : void
      {
         if(_tip != null)
         {
            _tip.visible = false;
         }
      }
      
      private function isHeadType(type:String) : Boolean
      {
         return HEAD_TYPES.indexOf(type) >= 0;
      }
      
      private function filterHeadParts(parts:Array) : Array
      {
         var out:Array = [];
         var i:int = 0;
         var part:* = undefined;
         i = 0;
         while(i < parts.length)
         {
            part = parts[i];
            if(isHeadType(String(part.type)))
            {
               out.push(part);
            }
            i++;
         }
         return out.length > 0 ? out : parts;
      }
      
      private function partColors(renderer:*, type:String, bits:Array) : Array
      {
         var colors:Array = [];
         var data:* = undefined;
         var setType:* = undefined;
         var palette:* = undefined;
         var i:int = 0;
         var colorId:int = 0;
         var partColor:* = undefined;
         try
         {
            data = renderer.getFigureData();
            setType = data != null ? data.getSetType(type) : null;
            palette = setType != null && data != null ? data.getPalette(int(setType.paletteID)) : null;
            if(palette == null)
            {
               return colors;
            }
            i = 2;
            while(i < bits.length)
            {
               colorId = int(parseInt(String(bits[i])));
               partColor = colorId > 0 ? palette.getColor(colorId) : null;
               colors.push(partColor != null ? partColor.colorTransform : null);
               i++;
            }
         }
         catch(colorErr:Error)
         {
         }
         return colors;
      }
      
      private function overlayBadges(row:Sprite, part:Object) : void
      {
         var renderer:* = undefined;
         var partSet:* = undefined;
         var club:int = 0;
         var sellable:Boolean = false;
         var catalog:Boolean = false;
         var nft:Boolean = false;
         var x:int = ICON;
         var mark:Sprite = null;
         var className:String = "";
         var label:String = "";
         if(row == null || part == null || _windowManager == null)
         {
            return;
         }
         catalog = Boolean(part.catalog);
         className = String(part.className != null ? part.className : "");
         label = String(part.name != null ? part.name : "");
         nft = className.toLowerCase().indexOf("nft") >= 0 || label.toLowerCase().indexOf("nft") >= 0;
         try
         {
            renderer = _windowManager.avatarRenderer;
            partSet = figurePartSet(renderer,String(part.type),int(part.setId));
            if(partSet != null)
            {
               club = int(partSet.clubLevel);
               sellable = Boolean(partSet.isSellable);
            }
         }
         catch(badgeErr:Error)
         {
         }
         if(club > 0)
         {
            mark = drawBadge(16766720,0);
            mark.x = x;
            mark.y = ICON - 2;
            row.addChild(mark);
            x -= 10;
         }
         if(sellable)
         {
            mark = drawBadge(14524637,1);
            mark.x = x;
            mark.y = ICON - 2;
            row.addChild(mark);
            x -= 10;
         }
         else if(nft)
         {
            mark = drawBadge(11141290,2);
            mark.x = x;
            mark.y = ICON - 2;
            row.addChild(mark);
         }
         else if(catalog)
         {
            mark = drawBadge(4761095,3);
            mark.x = x;
            mark.y = ICON - 2;
            row.addChild(mark);
         }
      }
      
      private function drawBadge(color:uint, kind:int) : Sprite
      {
         var badge:Sprite = new Sprite();
         badge.mouseEnabled = false;
         badge.graphics.beginFill(color,1);
         if(kind == 0)
         {
            badge.graphics.moveTo(4,0);
            badge.graphics.lineTo(8,4);
            badge.graphics.lineTo(4,8);
            badge.graphics.lineTo(0,4);
            badge.graphics.lineTo(4,0);
         }
         else
         {
            badge.graphics.drawRoundRect(0,0,8,8,2,2);
         }
         badge.graphics.endFill();
         return badge;
      }
   }
}
