package
{
	import com.adobe.viewsource.ViewSource;
	import com.bit101.components.*;
	
	import embeds.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.text.TextFormat;
	import flash.utils.*;
	
	import org.tinytlf.*;
	import org.tinytlf.lambdas.*;
	
	[SWF(width = "600", height = "500")]
	public class TinyTLFDemo extends Sprite
	{
		private var helvetica:Helvetica;
		private var tf:TextField;
		private var loadedCSS:String = '';
		private const mainVbox:VBox = new VBox(null, 0, 10);
		
		public function TinyTLFDemo()
		{
			super();
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			const g:Graphics = graphics;
			g.clear();
			g.beginFill(0xFFFFFF, 1);
			g.lineStyle(1, 0xCCCCCC);
			g.drawRect(1, 1, stage.stageWidth - 2, stage.stageHeight - 2);
			
			addChild(mainVbox);
			mainVbox.width = 160;
			mainVbox.alignment = VBox.RIGHT;
			
			addTextField(org.tinytlf.TextField);
//			createShapeCombobox();
			createHTMLCombobox();
			createCSSComponents();
			
			ViewSource.addMenuItem(this, 'http://guyinthechair.com/flash/tinytlf/2.0/explorer/srcview/index.html');
		}
		
		private function addTextField(textFieldClass:Class):void
		{
			const newTF:TextField = new textFieldClass();
			
			if(tf)
			{
				newTF.html = tf.html;
				newTF.css = tf.css;
				removeChild(tf);
			}
			
			addChild(tf = newTF);
			
			tf.width = stage.stageWidth - 166;
			tf.height = 499;
			tf.x = 165;
		}
		
		private function createHTMLCombobox():void
		{
			const window:Window = new Window(mainVbox, 0, 0, 'HTML Source');
			window.draggable = false;
			window.width = 160;
			window.height = 140;
			
			const list:List = new List(window, 0, 0,
									   [
									   'Single',
									   'Small',
									   'Large',
									   'Long',
									   'Japanese',
									   'Idle Words',
									   'Farmer One By Christian Cantrell'
									   ]);
			
			list.autoHideScrollBar = true;
			list.height = 120;
			list.width = 160;
			list.selectedIndex = 0;
			
			list.addEventListener('select', function(e:Event):void {
				const propName:String = String(list.selectedItem).split(' ').join('');
				const panel:Panel = new Panel(stage, (stage.stageWidth - 100) * 0.5, (stage.stageHeight - 40) * 0.5);
				panel.width = 120;
				panel.height = 40;
				
				const label:Label = new Label(panel, 0, 10, 'Parsing XML');
				const format:TextFormat = label.textField.defaultTextFormat;
				format.size = 14;
				format.font = 'Helvetica';
				
				label.textField.defaultTextFormat = format;
				label.draw();
				label.x = (panel.width - label.width) * 0.5;
				
				list.enabled = false;
				
				setTimeout(function():void {
					const time:Number = getTimer();
					const xml:XML = toXML(new (HTMLSource[propName] as Class)().toString());
					label.text = (getTimer() - time) + 'ms';
					label.draw();
					label.x = (panel.width - label.width) * 0.5;
					
					tf.html = xml;
					
					setTimeout(function():void {
						stage.removeChild(panel);
						list.enabled = true;
					}, 750);
				}, 250);
			});
			tf.html = new HTMLSource.Single().toString();
		}
		
		private function createCSSComponents():void
		{
			const window:Window = new Window(mainVbox);
			window.draggable = false;
			window.title = 'CSS';
			window.width = 160;
			window.height = 100;
			
			const vbox:VBox = new VBox(window, 0, 0);
			vbox.spacing = 0;
			vbox.width = 160;
			vbox.alignment = VBox.RIGHT;
			
			const list:List = new List(vbox, 0, 0,
									   [
									   'Default',
									   'Helvetica',
									   'Idle Words'
									   ]);
			list.autoHideScrollBar = true;
			list.selectedIndex = 1;
			list.height = 60;
			list.width = 160;
			list.addEventListener('select', function(e:Event):void {
				if(!list.selectedItem)
					return;
				
				const propName:String = String(list.selectedItem).split(' ').join('');
				tf.css = loadedCSS = new (CSSSource[propName] as Class)().toString();
			});
			tf.css = loadedCSS = new CSSSource.Helvetica().toString();
			
			const editWindow:Window = new Window(null,
												 (stage.stageWidth - 400) * 0.5,
												 (stage.stageHeight - 400) * 0.5,
												 'Edit CSS');
			editWindow.width = 400;
			editWindow.height = 400;
			editWindow.hasCloseButton = true;
			
			editWindow.addEventListener('close', function(e:Event):void {
				if(editArea.text != 'Load some CSS!')
					tf.css = loadedCSS = editArea.text;
				stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStagePress);
				stage.removeChild(editWindow);
			});
			
			const editArea:FormattedTextArea = new FormattedTextArea(editWindow);
			editArea.width = 400;
			editArea.height = 380;
			editArea.draw();
			
			const format:TextFormat = editArea.textField.defaultTextFormat;
			format.size = 14;
			format.font = 'Helvetica';
			editArea.format = format;
			
			const onStagePress:Function = function(e:MouseEvent):void {
				const r:Rectangle = editWindow.getBounds(stage);
				if(r.contains(e.stageX, e.stageY) == false)
					editWindow.dispatchEvent(new Event(Event.CLOSE));
			};
			
			const editButton:PushButton = new PushButton(vbox, 0, 0, 'Edit CSS', function(e:Event):void {
				editArea.text = loadedCSS || 'Load some CSS!';
				stage.addChild(editWindow);
				stage.addEventListener(MouseEvent.MOUSE_DOWN, onStagePress);
			});
			editButton.width = 50;
		}
		
//		private function createShapeCombobox():void
//		{
//			const window:Window = new Window(mainVbox, 0, 0, 'Rendering Shape');
//			window.draggable = false;
//			window.height = 60;
//			
//			const list:List = new List(window, 0, 0, ['Block', 'Circle']);
//			list.selectedIndex = 0;
//			list.height = 40;
//			list.width = 160;
//			list.autoHideScrollBar = true;
//			list.addEventListener('select', function(e:Event):void {
//				addTextField(list.selectedItem == 'Circle' ? CircleTextField : TextField);
//			});
//			window.width = 160;
//		}
	}
}

import com.bit101.components.*;

import flash.display.*;
import flash.geom.*;
import flash.text.*;
//import flash.text.engine.*;
//
//import org.tinytlf.box.*;
//import org.tinytlf.box.alignment.*;
//import org.tinytlf.box.paragraph.*;
//import org.tinytlf.box.progression.*;
//import org.tinytlf.box.region.*;
//import org.tinytlf.components.*;
//import org.tinytlf.html.*;
//import org.tinytlf.layout.*;
//
//internal class CircleTextField extends org.tinytlf.components.TextField
//{
//	public function CircleTextField()
//	{
//		super();
//		
//		const boxes:Array = injector.getInstance(Array, '<Box>');
//		boxes[0] = injector.instantiateUnmapped(CircleRegion);
//	}
//	
////	override protected function createBoxes(root:IDOMNode):Array
////	{
////		const panes:Array = injector.getInstance(Array, '<Box>');
////		const region:Region = panes[0];
////		
////		pane.progression = pane.blockProgression == TextBlockProgression.TTB ?
////			new CircleTTBProgression() :
////			pane.blockProgression == TextBlockProgression.LTR ?
////			new CircleLTRProgression() : new CircleRTLProgression();
////		
////		return super.createBoxes(root).map(function(box:Box, ... args):Box {
////			if(box is Paragraph)
////				Paragraph(box).layout = new CircleLayout();
////			return box;
////		});
////	}
//}
//
//internal class CircleRegion extends Region
//{
//	override public function set blockProgression(value:String):void
//	{
//		super.blockProgression = value;
//		
//		progression = value == TextBlockProgression.TTB ?
//			new CircleTTBProgression() :
//			value == TextBlockProgression.LTR ?
//				new CircleLTRProgression() :
//				new CircleRTLProgression();
//	}
//}
//
//internal class CircleTTBProgression extends TTBProgression
//{
//	public function CircleTTBProgression()
//	{
//		super();
//		defaultAlignment = getAlignmentForProgression(TextAlign.CENTER, TextBlockProgression.TTB);
//	}
//	
//	override public function getLineSize(box:Box, previousLine:TextLine):Number
//	{
//		if(!previousLine)
//			return box.width * .2;
//		
//		const d:Number = box.width - box.paddingTop - box.paddingBottom;
//		const r:Number = d * 0.5;
//		position(box, previousLine);
//		var y:Number = previousLine.y + previousLine.descent + box.leading;
//		
//		if(y > d)
//			y %= d;
//		
//		const indent:Number = (box is Paragraph) ? Paragraph(box).textIndent : 0;
//		const point:Point = xAtY(y, new Point(r, r), r);
//		
//		return Math.floor(point.y - point.x - indent);
//	}
//}
//
//internal class CircleLTRProgression extends LTRProgression
//{
//	public function CircleLTRProgression()
//	{
//		super();
//		defaultAlignment = getAlignmentForProgression(TextAlign.CENTER, TextBlockProgression.LTR);
//	}
//	
//	override public function getLineSize(box:Box, previousLine:TextLine):Number
//	{
//		if(!previousLine)
//			return box.height * .2;
//		
//		const d:Number = box.height - box.paddingLeft - box.paddingRight;
//		const r:Number = d * 0.5;
//		position(box, previousLine);
//		var x:Number = previousLine.x + previousLine.width + box.leading;
//		
//		if(x > d)
//			x %= d;
//		
//		const indent:Number = (box is Paragraph) ? Paragraph(box).textIndent : 0;
//		const point:Point = xAtY(x, new Point(r, r), r);
//		
//		return Math.floor(point.y - point.x - indent);
//	}
//}
//
//internal class CircleRTLProgression extends RTLProgression
//{
//	public function CircleRTLProgression()
//	{
//		super();
//		defaultAlignment = getAlignmentForProgression(TextAlign.CENTER, TextBlockProgression.RTL);
//	}
//	
//	override public function getLineSize(box:Box, previousLine:TextLine):Number
//	{
//		if(!previousLine)
//			return Math.floor(box.height * .2);
//		
//		const d:Number = box.height - box.paddingLeft - box.paddingRight;
//		const r:Number = d * 0.5;
//		position(box, previousLine);
//		var x:Number = Math.floor(previousLine.x - previousLine.width - box.leading);
//		
//		if(x < 0)
//			x = Math.abs(x % d);
//		
//		const indent:Number = (box is Paragraph) ? Paragraph(box).textIndent : 0;
//		const point:Point = xAtY(x, new Point(r, r), r);
//		
//		return Math.floor(point.y - point.x - indent);
//	}
//}
//
//internal function xAtY(yValue:Number, center:Point, radius:Number):Point
//{
//	// equation of circle is (x-h)^2 + (y-k)^2 = r^2 -> x^2 - 2hx + h^2 + (value-k)^2 = r^2 
//	
//	// use the textbook notation
//	const a:Number = 1;
//	const b:Number = -2 * center.x;
//	const c:Number = center.x * center.x + (yValue - center.y) * (yValue - center.y) - radius * radius;
//	
//	var d:Number = b * b - 4 * a * c;
//	if(d < 0)
//		return null;
//	
//	d = Math.sqrt(d);
//	
//	// note that 2*a = 2 since a = 1 and 1/2a = 1/2, so I'm adjusting the quadratic formula appropriately
//	return new Point(0.5 * (-b - d), 0.5 * (-b + d));
//}
//
//internal function yAtX(xValue:Number, center:Point, radius:Number):Point
//{
//	// equation of circle is (x-h)^2 + (y-k)^2 = r^2 -> x^2 - 2hx + h^2 + (value-k)^2 = r^2 
//	
//	// use the textbook notation
//	const a:Number = 1;
//	const b:Number = -2 * center.x;
//	const c:Number = center.y * center.y + (xValue - center.x) * (xValue - center.x) - radius * radius;
//	
//	var d:Number = (b * b) - (4 * a * c);
//	if(d < 0)
//		return null;
//	
//	d = Math.sqrt(d);
//	
//	// note that 2*a = 2 since a = 1 and 1/2a = 1/2, so I'm adjusting the quadratic formula appropriately
//	return new Point(0.5 * (-b - d), 0.5 * (-b + d));
//}
//
//internal class CircleLayout extends StandardParagraphLayout
//{
//	override public function layout(lines:Array, paragraph:Paragraph):Array
//	{
//		return lines;
//	}
//}
//
internal class FormattedTextArea extends TextArea
{
	public function FormattedTextArea(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, text:String = "")
	{
		super(parent, xpos, ypos, text);
	}
	
	public function set format(value:TextFormat):void
	{
		_format = value;
	}
}

//			const hbox2:HBox = new HBox(vbox);
//			hbox2.alignment = HBox.MIDDLE;
//			
//			const label2:Label = new Label(hbox2);
//			label2.text = 'URL:';
//			
//			const input:Text = new Text(hbox2);
//			input.editable = true;
//			input.width = 105;
//			input.height = 20;
//			
//			const loader:URLLoader = new URLLoader();
//			const progressBar:ProgressBar = new ProgressBar(null,
//															(stage.stageWidth - 100) * 0.5,
//															(stage.stageWidth - 10) * 0.5);
//			
//			const loadButton:PushButton = new PushButton(hbox2, 0, 0, 'Go', function(e:Event):void {
//				if(!input.text.match('http://'))
//					return;
//				
//				const removeListeners:Function = function():void {
//					loader.removeEventListener(Event.OPEN, onOpen);
//					loader.removeEventListener(ProgressEvent.PROGRESS, onProgress);
//					loader.removeEventListener(Event.COMPLETE, onComplete);
//					stage.removeChild(progressBar);
//				};
//				
//				if(loader.hasEventListener(Event.OPEN) || loader.hasEventListener(Event.COMPLETE))
//				{
//					removeListeners();
//					loader.close();
//				}
//				
//				const onOpen:Function = function(e:Event):void {
//					loader.removeEventListener(e.type, onOpen);
//					loader.addEventListener(ProgressEvent.PROGRESS, onProgress);
//					loader.addEventListener(Event.COMPLETE, onComplete);
//					progressBar.value = 0;
//					stage.addChild(progressBar);
//				};
//				const onProgress:Function = function(e:ProgressEvent):void {
//					progressBar.value = e.bytesLoaded / e.bytesTotal;
//				};
//				const onComplete:Function = function(e:Event):void {
//					progressBar.value = 1;
//					removeListeners();
//					list.selectedIndex = -1;
//					tf.css = loadedCSS = loader.data.toString();
//				};
//				
//				loader.addEventListener(Event.OPEN, onOpen);
//				loader.load(new URLRequest(input.text));
//			});
//			loadButton.width = 20;
//			loadButton.height = 20;

