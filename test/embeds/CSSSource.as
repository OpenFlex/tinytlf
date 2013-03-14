package embeds
{
	import org.tinytlf.types.CSS;

	public class CSSSource
	{
		public static const Default:Class = CSS.defaultCSS;
		
		[Embed(source = "assets/css/helvetica.css", mimeType = "application/octet-stream")]
		public static const Helvetica:Class;
		
		[Embed(source = "assets/css/idle_words.css", mimeType = "application/octet-stream")]
		public static const IdleWords:Class;
	}
}