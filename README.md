![License](https://img.shields.io/github/license/hsoju/vu-voice)

# vu-voice

Codebase for building a voice application for use in imvu's native client. IMVU currently only supports flash-based applications for user generated products, meaning for now, the assets will be solely actionscript-based and targeted for use with Adobe Flash Player.

# Usage

After cloning this repo it is recommended to have a pre-2021 version of Adobe Animate in order to edit the Flash application files. While other text editors, (VSCode, Sublime Text, Atom), can edit the actionscript files directly, compression to an executable .swf file is needed in order to run any flash program. Since Adobe announced [EOL for Flash in 2021](https://www.adobe.com/products/flashplayer/end-of-life.html), it is reasonable to assume Adobe Animate will no longer support a Flash-based workflow in later releases. For reference all work done for this project uses a 2019 version of Adobe Animate.

## Overview

Application uses the [imvu-flash](https://github.com/imvu/imvu-flash) api to send audio using RTMP across imvu's media server. Audio is recorded from the user's microphone, encoded, then sent across the network using AMF (Action Message Format). Once the message is picked up on the receiver's end, the message is decoded then played back through the receiver's default speakers.

### Recording

Current stable version uses a 5khz sampling rate with a default [Asao](https://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/media/Microphone.html#codec) codec. This is the lowest sampling rate supported by the [Microphone](https://help.adobe.com/en_US/FlashPlatform/reference/**actionscript**/3/flash/media/Microphone.html#rate) package, and as a result allows for the minimum amount of audio data to be sent with each packet at the expense of having the lowest recording quality. Migrating to the speex codec is an option however it utilizes a default 16khz sampling rate which cannot be lowered.

All sample data events are captured as [IEEE 754 single-precision](<https://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/utils/ByteArray.html#readFloat()>) (32-bit) floating point numbers, but a negligible amount of precision is lost during encoding.

### Encoding

```Actionscript
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
    byteString += encoder[offsetInt];
}
```

Floating point numbers captured from sample data events are first mapped to a range of integers ranging from 0 to 100. Each integer from 0 to 100 is mapped to a utf-8 encoded character. If the sample data events are negative, instead of mapping to a separate utf-8 encoded character, an '!' character is used along with the encoding mapping to the absolute value of the data. If data is repeated, (ex. a succession of 0's denoting silence), the '#' character is used.

Majority of sample data events are represented with an 8bit utf-8 encoded character, (+floating point values or repetitions), but in the worst cases sample data events can require 16bit or 24-bit characters for representation.

### Playback

Audio is reassembled by decoding messages using a reverse lookup of the encoding map. To play the sound through speakers, the utf-8 string representation of the integer values are converted into their original floating point numeric values, and processed through a [ByteArray](https://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/utils/ByteArray.html). Sound is played by writing each sample a successive number of times to each sample data event, and as a result has a close correlation to the original sampling rate.

_For reference_:

| 44khz | 22khz | 11khz | 8khz | 5khz |
| ----- | ----- | ----- | ---- | ---- |
| 2x    | 4x    | 8x    | 11x  | 16x  |

Important to note, even when recording at the standard sampling rate of 44khz, samples must be sent **TWICE** to the sample data event. This is because audio played back through the [Sound](https://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/media/Sound.html) package always transmits in stereo and **NOT** mono.

## Includes

A general-purpose persistency loader .swf executable is packaged alongside the main voice chat application. On imvu, when trying on a flash product, the application will no longer be displayed on the screen once the user leaves the product. The persistency loader keeps the application window open until the user leaves the room, but requires that the target executable have the name **"main.swf"**
when bundled together in the flash product.

# Problems

There are certain constraints from both IMVU and Adobe Flash that cause complications when trying to create a distributed audio chat service.

- **AMF messages can only be 40k in length.** This means that each packet sent using IMVU's client widgets cannot exceed a certain size. Attempting to send a full sample data event recorded at 44khz, where each sample is 4 bytes, will not be possible. The message will be dropped and will never be collected by the receiver.
- **IMVU media servers have a hard bandwidth limit.** Even if a packet is sufficiently small enough by AMF standards, IMVU's servers are configured to **stop** sending messages if too much data is sent. This means while you may be able to send a packet of size 35k, every subsequent message will be dropped and the receiver will no longer collect any messages from the client widget. Additionally, even if packets are of a decently small size, if the messages are being sent too frequently (50ms), IMVU's servers will be unable to keep up with the load and will buffer the messages. This means that audio may not be received at all, or in the best case cut in and out with extreme latency issues (receiving audio several seconds after transmission).

# Resources

- Everything you need to know about imvu's flash api: https://github.com/imvu/imvu-flash
- Information on all Actionscript 3 classes and packages: https://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/package-detail.html
