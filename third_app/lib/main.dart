import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

// tracks

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterAudioQuery audioQuery = FlutterAudioQuery();
  List<SongInfo> songs = [];
  int currentIndex = 0;
  final GlobalKey<_PlayerState> key = GlobalKey<_PlayerState>();

  void initState() {
    super.initState();
    getTrack();
  }

  void getTrack() async {
    songs = await audioQuery.getSongs();
    setState(() {
      songs = songs;
    });
  }

  void changeTrack(bool isNext) {
    if (isNext) {
      if (currentIndex != songs.length - 1) {
        currentIndex++;
      } else {
        if (currentIndex != 0) {
          currentIndex--;
        }
      }
    }
    key.currentState.setSong(songs[currentIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Icon(Icons.music_note, color: Colors.black),
        title: Text(
          'Music Player',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: ListView.separated(
        separatorBuilder: (context, index) => Divider(),
        itemCount: songs.length,
        itemBuilder: (context, index) => ListTile(
          leading: CircleAvatar(
            backgroundImage: songs[index].albumArtwork == null
                ? AssetImage('images/pic1.gif')
                : FileImage(File(songs[index].albumArtwork)),
          ),
          title: Text(songs[index].title),
          subtitle: Text(songs[index].artist),
          onTap: () {
            currentIndex = index;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Player(
                  changeTrack: changeTrack,
                  songInfo: songs[currentIndex],
                  key: key,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class Player extends StatefulWidget {
  SongInfo songInfo;
  Function changeTrack;
  final GlobalKey<_PlayerState> key;
  Player({this.songInfo, this.changeTrack, this.key}) : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  double minVal = 0.0, maxVal = 0.0, currVal = 0.0;
  String currTime = '', endTime = '';

  final AudioPlayer player = AudioPlayer();
  bool isPlaying = false;

  void initState() {
    super.initState();
    setSong(widget.songInfo);
  }

  void dispose() {
    super.dispose();
    player?.dispose();
  }

  void setSong(SongInfo songInfo) async {
    widget.songInfo = songInfo;
    await player.setUrl(widget.songInfo.uri);
    currVal = minVal;
    maxVal = player.duration.inMilliseconds.toDouble();
    setState(() {
      currTime = getDuration(currVal);
      endTime = getDuration(maxVal);
    });
    isPlaying = false;
    changeStatus();
    player.positionStream.listen((duration) {
      currVal = duration.inMilliseconds.toDouble();
      setState(() {
        currTime = getDuration(currVal);
      });
    });
  }

  void changeStatus() {
    setState(() {
      isPlaying = !isPlaying;
    });
    if (isPlaying) {
      player.play();
    } else {
      player.pause();
    }
  }

  String getDuration(double value) {
    Duration duration = Duration(milliseconds: value.round());

    return [duration.inMinutes, duration.inSeconds]
        .map((element) => element.remainder(60).toString().padLeft(2, '0'))
        .join(':');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.arrow_back, color: Colors.black)),
        title: Text(
          "Now Playing",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Container(
        margin: EdgeInsets.fromLTRB(5, 40, 5, 0),
        child: Column(
          children: <Widget>[
            CircleAvatar(
              backgroundImage: widget.songInfo.albumArtwork == null
                  ? AssetImage('images/pic1.gif')
                  : FileImage(File(widget.songInfo.albumArtwork)),
              radius: 95,
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0, 10, 0, 7),
              child: Text(
                widget.songInfo.title,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 15),
              child: Text(
                widget.songInfo.artist,
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Slider(
              inactiveColor: Colors.black12,
              activeColor: Colors.black,
              min: minVal,
              max: maxVal,
              value: currVal,
              onChanged: (value) {
                currVal = value;
                player.seek(Duration(milliseconds: currVal.round()));
              },
            ),
            Container(
              transform: Matrix4.translationValues(0, -5, 0),
              margin: EdgeInsets.fromLTRB(5, 0, 5, 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currTime,
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    endTime,
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    child: Icon(
                      Icons.skip_previous,
                      color: Colors.black,
                      size: 55,
                    ),
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      widget.changeTrack(false);
                    },
                  ),
                  GestureDetector(
                    child: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      color: Colors.black,
                      size: 75,
                    ),
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      changeStatus();
                    },
                  ),
                  GestureDetector(
                    child: Icon(
                      Icons.skip_next,
                      color: Colors.black,
                      size: 55,
                    ),
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      widget.changeTrack(true);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
