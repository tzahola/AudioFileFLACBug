# AudioFileFLACBug
Demonstrating a bug in the FLAC decoder of Apple's AudioToolbox framework

## Bug summary

The first time you call [AudioFileReadPacketData](https://developer.apple.com/documentation/audiotoolbox/1502788-audiofilereadpacketdata?language=objc) on a FLAC file, it takes unreasonably long to return, unless you read *exactly one* packet. 

## Using this project

1. Clone this repository
2. Run the `make_test_files` shell script from the repository root. This will create two FLAC files (`big.flac` and `small.flac`) filled with data from `/dev/urandom`.
3. Open `AudioFileFLACBug.xcodeproj`
4. Launch the application on an iOS device or an iOS Simulator.

### Observations

By default the program will produce an output like this:
```
AudioFileReadPacketData begin: 1 packets, 24610 bytes
AudioFileReadPacketData done : 1 packets, 24586 bytes, took: 0.000233 s
AudioFileReadPacketData begin: 1 packets, 24610 bytes
AudioFileReadPacketData done : 1 packets, 24586 bytes, took: 0.000647 s
AudioFileReadPacketData begin: 1 packets, 24610 bytes
AudioFileReadPacketData done : 1 packets, 24586 bytes, took: 0.000238 s
AudioFileReadPacketData begin: 1 packets, 24610 bytes
...
```
Now in `AppDelegate.m`, change the `maxPacketCount` constant to something other than `1`:
```
const int maxPacketCount = 2;
```
Launch the application again, and observe the drastic increase in the duration of the first `AudioFileReadPacketData` call:
```
AudioFileReadPacketData begin: 2 packets, 49220 bytes
AudioFileReadPacketData done : 2 packets, 49172 bytes, took: 0.595209 s    <---- more than half a second!
AudioFileReadPacketData begin: 2 packets, 49220 bytes
AudioFileReadPacketData done : 2 packets, 49172 bytes, took: 0.000165 s
AudioFileReadPacketData begin: 2 packets, 49220 bytes
AudioFileReadPacketData done : 2 packets, 49172 bytes, took: 0.000187 s
AudioFileReadPacketData begin: 2 packets, 49220 bytes
```
By changing the program to use `small.flac` instead of `big.flac` (`[NSBundle.mainBundle URLForResource:@"big" withExtension:@"flac"]`), you can verify that the duration of the first `AudioFileReadPacketData` will be proportional to the size of the file. That is, it will be almost unnoticeable for `small.flac` (being 2 MByte), but there will be a definite lag for `big.flac` (470 MByte). 

I couldn't reproduce similar behavior when decoding ALAC or MP3 files via the AudioFile APIs, so this issue seems to be unique to the FLAC decoder in the AudioToolbox framework. 
