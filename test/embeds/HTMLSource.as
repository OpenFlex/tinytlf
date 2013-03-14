package embeds
{
	public class HTMLSource
	{
		[Embed(source = "assets/html/single.txt", mimeType = "application/octet-stream")]
		public static const Single:Class;
		
		[Embed(source = "assets/html/small.txt", mimeType = "application/octet-stream")]
		public static const Small:Class;
		
		[Embed(source = "assets/html/large.txt", mimeType = "application/octet-stream")]
		public static const Large:Class;
		
		[Embed(source = "assets/html/long.txt", mimeType = "application/octet-stream")]
		public static const Long:Class;
		
		[Embed(source = "assets/html/japanese.txt", mimeType = "application/octet-stream")]
		public static const Japanese:Class;
		
		[Embed(source = "assets/html/idle_words.txt", mimeType = "application/octet-stream")]
		public static const IdleWords:Class;
		
		[Embed(source = "assets/html/farmer_one.txt", mimeType = "application/octet-stream")]
		public static const FarmerOneByChristianCantrell:Class;
	}
}
