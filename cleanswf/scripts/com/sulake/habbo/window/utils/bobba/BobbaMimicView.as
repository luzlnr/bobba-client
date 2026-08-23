package com.sulake.habbo.window.utils.bobba
{
   import com.sulake.core.utils.FontEnum;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.Loader;
   import flash.display.PixelSnapping;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.net.URLRequest;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.Dictionary;
   
   public class BobbaMimicView extends Sprite
   {
      
      public static const VIEW_W:int = 280;
      
      public static const VIEW_H:int = 153;
      
      private static const CHECKBOX_PATH:String = "checkbox.png";
      
      private static const FONT_REGULAR:String = "Ubuntu";
      
      private static const FONT_BOLD:String = "Ubuntu bold";
      
      private static const CHECK_SCALE:int = 1;
      
      private static const CHECK_SIZE:Number = 18;
      
      private static const CHECK_LABEL_GAP:Number = 4;
      
      private static const NAME_X:Number = 8;
      
      private static const NAME_Y:Number = 6;
      
      private static const NAME_W:int = 256;
      
      private static const NAME_SIZE:int = 14;
      
      private static const NAME_COLOR:uint = 0xffffff;
      
      private static const HINT_X:Number = 12;
      
      private static const HINT_Y:Number = 26;
      
      private static const HINT_W:int = 256;
      
      private static const HINT_SIZE:int = 10;
      
      private static const HINT_COLOR:uint = 0xffffff;
      
      private static const BAR_X:Number = 8;
      
      private static const BAR_Y:Number = 48;
      
      private static const BAR_W:int = 264;
      
      private static const BAR_COLOR:uint = 0x3a3b3a;
      
      private static const COL_LEFT_X:Number = 6;
      
      private static const COL_RIGHT_X:Number = 144;
      
      private static const COL_WIDTH:Number = 130;
      
      private static const ROW0_Y:int = 55;
      
      private static const ROW_SPACING:int = 24;
      
      private static const OPTION_SIZE:int = 11;
      
      private static const OPTION_COLOR:uint = 0xffffff;
      
      private var _controller:BobbaMimicController;
      
      private var _checkOff:BitmapData;
      
      private var _checkOn:BitmapData;
      
      private var _boxByRow:Dictionary;
      
      private var _keyByRow:Dictionary;
      
      private var _nameField:TextField;
      
      private var _hintField:TextField;
      
      public function BobbaMimicView(controller:BobbaMimicController)
      {
         super();
         _controller = controller;
         _boxByRow = new Dictionary();
         _keyByRow = new Dictionary();
         graphics.lineStyle(1,BAR_COLOR,1);
         graphics.moveTo(BAR_X,BAR_Y);
         graphics.lineTo(BAR_X + BAR_W,BAR_Y);
         _nameField = createText("",NAME_SIZE,NAME_COLOR,true,NAME_W);
         _nameField.x = NAME_X;
         _nameField.y = NAME_Y;
         addChild(_nameField);
         _hintField = createText("",HINT_SIZE,HINT_COLOR,false,HINT_W);
         _hintField.x = HINT_X;
         _hintField.y = HINT_Y;
         addChild(_hintField);
         loadCheckbox();
      }
      
      public function dispose() : void
      {
         _controller = null;
         _boxByRow = null;
         _keyByRow = null;
         _checkOff = null;
         _checkOn = null;
      }
      
      public function refresh() : void
      {
         var rowKey:Object = null;
         var box:Bitmap = null;
         var key:String = null;
         var selected:Boolean = false;
         if(_nameField != null && _controller != null)
         {
            _nameField.text = _controller.targetName != null && _controller.targetName.length > 0 ? _controller.targetName : BobbaI18n.t("mimic.nobody","Click a user");
            _nameField.height = Math.max(18,_nameField.textHeight + 6);
         }
         if(_hintField != null && _controller != null)
         {
            _hintField.text = _controller.targetMotto;
            _hintField.height = Math.max(14,_hintField.textHeight + 4);
         }
         if(_keyByRow == null || _controller == null || _checkOff == null)
         {
            return;
         }
         for(rowKey in _keyByRow)
         {
            key = _keyByRow[rowKey] as String;
            box = _boxByRow[rowKey] as Bitmap;
            if(box != null)
            {
               selected = _controller.getOption(key);
               box.bitmapData = selected ? _checkOn : _checkOff;
            }
         }
      }
      
      private function loadCheckbox() : void
      {
         var loader:Loader = new Loader();
         loader.contentLoaderInfo.addEventListener("complete",onCheckboxLoaded);
         loader.contentLoaderInfo.addEventListener("ioError",onAssetError);
         try
         {
            loader.load(new URLRequest(BobbaPack.resolveUrl(CHECKBOX_PATH)));
         }
         catch(errLoad:Error)
         {
         }
      }
      
      private function onAssetError(evt:Event) : void
      {
      }
      
      private function onCheckboxLoaded(evt:Event) : void
      {
         var bmp:Bitmap = null;
         var full:BitmapData = null;
         var half:int = 0;
         var loader:Loader = null;
         try
         {
            loader = evt.target.loader as Loader;
            bmp = loader.content as Bitmap;
            if(bmp == null || bmp.bitmapData == null)
            {
               return;
            }
            full = bmp.bitmapData;
            half = int(full.width / 2);
            _checkOff = new BitmapData(half,full.height,true,0);
            _checkOff.copyPixels(full,new Rectangle(0,0,half,full.height),new Point(0,0));
            _checkOn = new BitmapData(half,full.height,true,0);
            _checkOn.copyPixels(full,new Rectangle(half,0,half,full.height),new Point(0,0));
            buildRows();
            refresh();
         }
         catch(errCheck:Error)
         {
         }
      }
      
      private function buildRows() : void
      {
         var y:int = ROW0_Y;
         addToggleRow("look",BobbaI18n.t("mimic.opt.look","Copy look"),COL_LEFT_X,y);
         addToggleRow("sit",BobbaI18n.t("mimic.opt.sit","Copy sit"),COL_RIGHT_X,y);
         y = y + ROW_SPACING;
         addToggleRow("motto",BobbaI18n.t("mimic.opt.motto","Copy motto"),COL_LEFT_X,y);
         addToggleRow("dance",BobbaI18n.t("mimic.opt.dance","Copy dances"),COL_RIGHT_X,y);
         y = y + ROW_SPACING;
         addToggleRow("speech",BobbaI18n.t("mimic.opt.speech","Copy speech"),COL_LEFT_X,y);
         addToggleRow("action",BobbaI18n.t("mimic.opt.action","Copy actions"),COL_RIGHT_X,y);
         y = y + ROW_SPACING;
         addToggleRow("walk",BobbaI18n.t("mimic.opt.walk","Follow walk"),COL_LEFT_X,y);
         addToggleRow("typing",BobbaI18n.t("mimic.opt.typing","Copy typing"),COL_RIGHT_X,y);
      }
      
      private function addToggleRow(key:String, labelText:String, x:Number, y:Number) : void
      {
         var on:Boolean = _controller != null && _controller.getOption(key);
         var row:Sprite = new Sprite();
         var box:Bitmap = new Bitmap(on ? _checkOn : _checkOff);
         box.smoothing = false;
         box.pixelSnapping = PixelSnapping.ALWAYS;
         box.scaleX = CHECK_SCALE;
         box.scaleY = CHECK_SCALE;
         row.addChild(box);
         var label:TextField = createText(labelText,OPTION_SIZE,OPTION_COLOR,false,COL_WIDTH - CHECK_SIZE - CHECK_LABEL_GAP);
         label.x = CHECK_SIZE + CHECK_LABEL_GAP;
         label.y = Math.round((CHECK_SIZE - label.height) / 2);
         row.addChild(label);
         row.x = x;
         row.y = y;
         row.buttonMode = true;
         row.useHandCursor = true;
         row.mouseChildren = false;
         row.addEventListener(MouseEvent.CLICK,onRowClick);
         _boxByRow[row] = box;
         _keyByRow[row] = key;
         addChild(row);
      }
      
      private function onRowClick(e:MouseEvent) : void
      {
         var row:Sprite = e.currentTarget as Sprite;
         var key:String = null;
         if(row == null || _controller == null || _keyByRow == null)
         {
            return;
         }
         key = _keyByRow[row] as String;
         if(key == null)
         {
            return;
         }
         _controller.setOption(key,!_controller.getOption(key));
         refresh();
      }
      
      private function createText(textValue:String, size:int, color:uint, bold:Boolean, width:int) : TextField
      {
         var field:TextField = new TextField();
         field.selectable = false;
         field.multiline = false;
         field.wordWrap = false;
         field.mouseEnabled = false;
         field.width = width;
         field.autoSize = TextFieldAutoSize.NONE;
         var fmt:TextFormat = new TextFormat();
         var fontName:String = bold ? FONT_BOLD : FONT_REGULAR;
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
   }
}
