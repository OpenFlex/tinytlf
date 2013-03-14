package embeds
{
	public class Helvetica
	{
		[Embed(source = "assets/fonts/Helvetica Regular.ttf", fontFamily = "Helvetica", embedAsCFF="false")]
		public static const regular:Class;
		
		[Embed(fontWeight = "bold", source = "assets/fonts/Helvetica Bold.ttf", fontFamily = "Helvetica", embedAsCFF="false")]
		public static const bold:Class;
		
		[Embed(source = "assets/fonts/Helvetica Italic.ttf", fontStyle = "italic", fontFamily = "Helvetica", embedAsCFF="false")]
		public static const italic:Class;
		
		[Embed(fontWeight = "bold", source = "assets/fonts/Helvetica Bold Italic.ttf", fontStyle = "italic", fontFamily = "Helvetica", embedAsCFF="false")]
		public static const boldItalic:Class;
		
		[Embed(source = "assets/fonts/Helvetica Regular.ttf", fontFamily = "Helvetica")]
		public static const regularCFF:Class;
		
		[Embed(fontWeight = "bold", source = "assets/fonts/Helvetica Bold.ttf", fontFamily = "Helvetica")]
		public static const boldCFF:Class;
		
		[Embed(source = "assets/fonts/Helvetica Italic.ttf", fontStyle = "italic", fontFamily = "Helvetica")]
		public static const italicCFF:Class;
		
		[Embed(fontWeight = "bold", source = "assets/fonts/Helvetica Bold Italic.ttf", fontStyle = "italic", fontFamily = "Helvetica")]
		public static const boldItalicCFF:Class;
	}
}