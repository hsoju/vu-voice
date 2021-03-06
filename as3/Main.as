package  {
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import flash.events.ActivityEvent;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.events.MouseEvent;
	import flash.events.SampleDataEvent;
	import flash.events.StatusEvent;
	
	import flash.geom.ColorTransform;

	import flash.media.Microphone;
	import flash.media.Sound;
	import flash.media.SoundCodec;
	
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import flash.system.Security;
	
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import com.imvu.widget.ClientWidget;
	import com.imvu.events.WidgetEvent;
	import com.imvu.events.WidgetEventData;
	import com.imvu.widget.WidgetAsset;
	
	public class Main extends ClientWidget {
		
		public var mic:Microphone;
		public var micRate:int = 5;
		public var sound:Sound = new Sound();
		public var micEnabled:Boolean = false;
		public var recordingEnabled:Boolean = false;
		public var soundEnabled:Boolean = true;
		
		public var currBytes:ByteArray = new ByteArray();
		public var soundBytes:ByteArray = new ByteArray();
		
		public var encoder:Array;
		public var decoder:Object;
		
		public var isSending:Boolean = false;
		public var sendAudioTimer:Timer;
		public var sendAudioInterval:Number = 300;
		
		public var cycle:int = 0;
		
		public var currUsername:String = "Me";
		public var currText:TextField = new TextField();
		public var currMeter:Sprite = new Sprite();
		
		public var mutedUsers:Dictionary = new Dictionary();
		public var availablePosns:Array = new Array();
		
		public var leftPadding:int = 20;
		
		public function initWidget():void {
			for (var i:int = 0; i < 20; i++) {
				availablePosns.push(true);
			}
			availablePosns[0] = false;
			var startPosn:Number = 15;
			
			if (this.space != null) {
				currUsername = this.space.avatarName;
			}
			
			getDecoder();
			generateUser(currText, currUsername, startPosn);
			generateMeter(currMeter, currUsername, startPosn);
			generateMasterVolume();
			
			sound.addEventListener(SampleDataEvent.SAMPLE_DATA, playback);
			this.addEventListener("updateGuest", updateGuestUI);
			this.addEventListener("playSound", stream);
			//debug();
		}
		
		public function debug(): void {
			var username:String = "Raja";
			addGuest(username);
			setTimeout(removeGuest, 1000, username);
		}
		
		public function startRecording(event:MouseEvent):void {
			mic = Microphone.getMicrophone(); 
			if (mic != null) {
				getEncoder();
				event.target.removeEventListener(MouseEvent.CLICK, startRecording);
				mic.rate = micRate;
				mic.setUseEchoSuppression(true);
				mic.addEventListener(SampleDataEvent.SAMPLE_DATA, getAudio);
				mic.addEventListener(ActivityEvent.ACTIVITY, updateGuest);
				mic.addEventListener(StatusEvent.STATUS, permissions);
				sendAudioTimer = new Timer(this.sendAudioInterval, 0);
				sendAudioTimer.addEventListener(TimerEvent.TIMER, sendAudio);
				sendAudioTimer.start();
			} else {
				micEnabled = false;
			}
		}
		
		public function permissions(event:StatusEvent):void {
			if (!mic.muted) {
				getChildByName(currUsername).addEventListener(MouseEvent.CLICK, muteHandler);
				getChildByName(currUsername).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
				addLoopback();
			}
			micEnabled = !mic.muted;
		}
				
		public function updateGuest(event:ActivityEvent): void {
			if (event.activating) {
				this.fireRemoteEvent("updateGuest", true);
			}
		}
		
		public function getAudio(event:SampleDataEvent): void {
			var sample:Number = 0.0;
			while (event.data.bytesAvailable) {
				sample = event.data.readFloat();
				currBytes.writeFloat(sample);
			}
		}

		public function sendAudio(event:TimerEvent): void {
			if ((currBytes.length > 0) && (currBytes.length < 8193)) {
				var byteString:String = this.encodeAudio();
				if (isSending) {
					this.fireRemoteEvent("playSound", byteString);
/*					decodeAudio(byteString);
					sound.play();*/
				}
			} else {
				currBytes = new ByteArray();
			}
		}
		
		public function playback(event:SampleDataEvent): void {
			var playingBytes:ByteArray = soundBytes;
			var samp:Number;
			for (var i:int = 0; i < 1024 && playingBytes.bytesAvailable; i++) {
				samp = playingBytes.readFloat();
				event.data.writeFloat(samp); 
				event.data.writeFloat(samp);
				
				event.data.writeFloat(samp); 
				event.data.writeFloat(samp);				
				
				event.data.writeFloat(samp); 
				event.data.writeFloat(samp);
				
				event.data.writeFloat(samp); 
				event.data.writeFloat(samp);		
				
				event.data.writeFloat(samp); 
				event.data.writeFloat(samp);
				
				event.data.writeFloat(samp); 
				event.data.writeFloat(samp);				
				
				event.data.writeFloat(samp); 
				event.data.writeFloat(samp);
				
				event.data.writeFloat(samp); 
				event.data.writeFloat(samp);		

			}
		}
		
		public function updateGuestUI(event:WidgetEvent) {
			var dat:WidgetEventData  = event.data;
			var activation:Boolean = dat.args as Boolean;
			var username:String = String(dat.fromUser);
			var guest:DisplayObject = getChildByName(username);
			if (activation) {
				if (guest == null) {
					addGuest(username);
				}
			}
			setTimeout(removeGuest, 2000, username);
		}
				
		public function addGuest(username:String): void {
			var user:TextField = new TextField();
			var meter:Sprite = new Sprite();
			var iterPosns:Array = availablePosns;
			var posn:Number = (iterPosns.length + 2) * 15;
			for (var i:int = 1; i < iterPosns.length; i++) {
				if (iterPosns[i]) {
					availablePosns[i] = false;
					posn = ((i + 1) * 15);
					break;
				}
			}
			generateUser(user, username, posn);
			generateMeter(meter, username, posn);
		}
		
		public function removeGuest(username:String): void {
			var tf:TextField = getChildByName(username + "-text") as TextField;
			var ix:int = ((tf.y / 15) - 1) as int
			availablePosns[ix] = true;
			removeChild(getChildByName(username + "-text"));
			removeChild(getChildByName(username));
		}
		
		public function masterHandler(event:MouseEvent): void {
			if ((micEnabled) && (!mutedUsers[currUsername])) {
				getChildByName(currUsername).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
			}
			soundEnabled = !soundEnabled;
			var newColor:ColorTransform = new ColorTransform();
			if (soundEnabled) {
				getChildByName("master_volume").transform.colorTransform = newColor;
				if ((micEnabled) && (!mic.muted)) {
					getChildByName(currUsername).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
				}
			} else {
				newColor.color = 0x808080;
				getChildByName("master_volume").transform.colorTransform = newColor;
			}
		}
		
		public function muteHandler(event:MouseEvent): void {
			if (soundEnabled) {
				var newColor:ColorTransform = new ColorTransform();
				if (event.target.transform.colorTransform.color == 0x808080) {
					mutedUsers[event.target.name] = false;
					if (event.target.name == currUsername) {
						if (mic != null) {
							mic.gain = 50;
						}
					}
				} else {
					newColor.color = 0x808080
					mutedUsers[event.target.name] = true;
					if (event.target.name == currUsername) {
						if (mic != null) {
							mic.gain = 0;
						}
					}
				}
				event.target.transform.colorTransform = newColor;
			}
		}
		
		public function stream(event:WidgetEvent) {
			var dat:WidgetEventData = event.data;
			var username:String = dat.fromUser;
			if ((!mutedUsers[username]) && (soundEnabled)) {
				var encodedAudio:String = String(dat.args);
				decodeAudio(encodedAudio);
				sound.play();
			}
		}
		
		public function encodeAudio(): String {
			isSending = false;
			var rawBytes:ByteArray = currBytes;
			currBytes = new ByteArray();
			rawBytes.position = 0;
			var byteString:String = "";
			var lastInt:int = 101;
			while (rawBytes.bytesAvailable) {
				var offsetByte:Number = (rawBytes.readFloat() * 100);
				var offsetInt:int = int(offsetByte);
				if (lastInt == offsetInt) {
					byteString += "#";
					lastInt = offsetInt;
				} else {
					lastInt = offsetInt;
					if (offsetInt < 0) {
						byteString += "!";
						offsetInt *= -1;
					}
					if ((!isSending) && (offsetInt > 1)) {
						isSending = true;
					}
					byteString += encoder[offsetInt];
				}
			}
			return byteString;
		}
		
		public function decodeAudio(encodedAudio:String): void {
			var receivedByteString:String = encodedAudio;
			var receivedBytes = new ByteArray();
			var currSign:int = 1;
			var lastFloat:Number = 101;
			for (var i:int = 0; i < receivedByteString.length; i++) {
				var char:String = receivedByteString.charAt(i);
				var currFloat:Number = 102;
				if (char == "#") {
					currFloat = lastFloat;
				} else {
					if (char == "!") {
						currSign = -1;
					} else {
						currFloat = (currSign * decoder[char]);
						currSign = 1;
					}
				}
				if (currFloat < 101) {
					receivedBytes.writeFloat(currFloat);
					lastFloat = currFloat;
				}
			}
			receivedBytes.position = 0;
			this.soundBytes = receivedBytes;
		}
		
		public function generateUser(user:TextField, username:String, posn:Number): void {
			user.autoSize = TextFieldAutoSize.LEFT;
			user.background = false;
			user.border = false;
			user.x = leftPadding + 10;
			user.y = posn;
			user.text = username;
			user.name = username + "-text";
			addChild(user);
		}
		
		public function generateMeter(voiceMeter:Sprite, username:String, posn:Number): void {
			voiceMeter.graphics.beginFill(0x66FF9C);
			voiceMeter.graphics.drawCircle(leftPadding, posn + 10, 5);
			voiceMeter.graphics.endFill();
			voiceMeter.name = username;
			voiceMeter.buttonMode = true;
			addChild(voiceMeter);
			if (!(username in mutedUsers)) {
				mutedUsers[username] = false;
			}
			var newColor:ColorTransform = new ColorTransform();
			if (username == currUsername) {
				newColor.color = 0x808080
				voiceMeter.transform.colorTransform = newColor;
				mutedUsers[username] = true;
				voiceMeter.addEventListener(MouseEvent.CLICK, startRecording);
			} else {
				if (mutedUsers[username]) {
					newColor.color = 0x808080;
					voiceMeter.transform.colorTransform = newColor;
				}
				voiceMeter.addEventListener(MouseEvent.CLICK, muteHandler);
			}
		}
		
		public function generateMasterVolume(): void {
			var master:Sprite = new Sprite();
			var startPadding:int = leftPadding - 10;
			master.name = "master_volume";
			var primaryBar:Sprite = new Sprite();
			primaryBar.graphics.beginFill(0x89FAA4);
			primaryBar.graphics.drawRect(startPadding, 12, 5, 3);
			primaryBar.graphics.endFill();
			primaryBar.name = "primary_bar";
			var secondaryBar:Sprite = new Sprite();
			secondaryBar.graphics.beginFill(0x7FFA7F);
			secondaryBar.graphics.drawRect(startPadding + 6, 9, 5, 6);
			secondaryBar.graphics.endFill();
			secondaryBar.name = "secondary_bar";
			var tertiaryBar:Sprite = new Sprite();
			tertiaryBar.graphics.beginFill(0x5FE06E);
			tertiaryBar.graphics.drawRect(startPadding + 12, 6, 5, 9);
			tertiaryBar.graphics.endFill();
			tertiaryBar.name = "tertiary_bar";
			master.addChild(primaryBar);
			master.addChild(secondaryBar);
			master.addChild(tertiaryBar);
			master.buttonMode = true;
			addChild(master);
			master.addEventListener(MouseEvent.CLICK, masterHandler);
		}
		
		public function addLoopback(): void {
			var recorder:Sprite = new Sprite();
			var padding:int = leftPadding - 12;
			recorder.graphics.beginFill(0xFA7F7F);
			recorder.graphics.drawCircle(padding, 26, 3);
			recorder.graphics.endFill();
			recorder.name = "_recorder";
			recorder.buttonMode = true;
			addChild(recorder);
			recorder.addEventListener(MouseEvent.CLICK, setLoopback);
		}
		
		public function setLoopback(event:MouseEvent): void {
			if (soundEnabled) {
				recordingEnabled = !recordingEnabled
				var newColor:ColorTransform = new ColorTransform();
				if (recordingEnabled) {
					newColor.color = 0xFA1B1B
					mic.setLoopBack(true);
				} else {
					mic.setLoopBack(false);
				}
				event.target.transform.colorTransform = newColor;
			}
		}
		
		public function getEncoder(): void {
			this.encoder = ["$", "%", "&", "'", "(", ")", "*", "+", ",", "-", 
							".", "/", "0", "1", "2", "3", "4", "5", "6", "7", "8", 
							"9", ":", ";", "<", "=", ">", "?", "@", "A", "B", "C", 
							"D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", 
							"O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", 
							"Z", "[", "]", "^", "_", "`", "a", "b", "c", "d", "e", 
							"f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", 
							"q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "{", 
							"|", "}", "«", "¡", "¢", "£", "¤", "¥", "¦", "§", "¨", 
							"©", "ª", "~"]
		}
		
		public function getDecoder(): void {
			this.decoder = {"$":0.0, "%":0.01, "&":0.02, "'":0.03, "(":0.04, ")":0.05, 
							"*":0.06, "+":0.07, ",":0.08, "-":0.09, ".":0.1, "/":0.11, 
							"0":0.12, "1":0.13, "2":0.14, "3":0.15, "4":0.16, "5":0.17, 
							"6":0.18, "7":0.19, "8":0.2, "9":0.21, ":":0.22, ";":0.23, 
							"<":0.24, "=":0.25, ">":0.26, "?":0.27, "@":0.28, "A":0.29, 
							"B":0.3, "C":0.31, "D":0.32, "E":0.33, "F":0.34, "G":0.35, 
							"H":0.36, "I":0.37, "J":0.38, "K":0.39, "L":0.4, "M":0.41, 
							"N":0.42, "O":0.43, "P":0.44, "Q":0.45, "R":0.46, "S":0.47, 
							"T":0.48, "U":0.49, "V":0.5, "W":0.51, "X":0.52, "Y":0.53, 
							"Z":0.54, "[":0.55, "]":0.56, "^":0.57, "_":0.58, "`":0.59, 
							"a":0.6, "b":0.61, "c":0.62, "d":0.63, "e":0.64, "f":0.65, 
							"g":0.66, "h":0.67, "i":0.68, "j":0.69, "k":0.7, "l":0.71, 
							"m":0.72, "n":0.73, "o":0.74, "p":0.75, "q":0.76, "r":0.77, 
							"s":0.78, "t":0.79, "u":0.8, "v":0.81, "w":0.82, "x":0.83, 
							"y":0.84, "z":0.85, "{":0.86, "|":0.87, "}":0.88, "«":0.89, 
							"¡":0.9, "¢":0.91, "£":0.92, "¤":0.93, "¥":0.94, "¦":0.95, 
							"§":0.96, "¨":0.97, "©":0.98, "ª":0.99, "~":1.0}
		}
	}
	
}
