package  {
	
	import com.imvu.widget.ClientWidget
	
	
	public class Loader extends ClientWidget {
		
		
		public function initWidget():void {
			loadApp();
		}
		
		public function loadApp():void {
			if (this.space != null) {
				var mainPath:String = this.path + "debug.swf";
				if (!(mainPath in this.space.widgets)) {
					this.space.loadWidget(this.path + "debug.swf");
				}
			}
		}
	}
	
}
