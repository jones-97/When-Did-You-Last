import 'package:flutter/material.dart';
// import 'package:flutter_system_ringtones/flutter_system_ringtones.dart';

class RingtonePickerScreen extends StatefulWidget {
  final String? selectedRingtoneUri;
  const RingtonePickerScreen({Key? key, this.selectedRingtoneUri}) : super(key: key);

  @override
  _RingtonePickerScreenState createState() => _RingtonePickerScreenState();
}

class Tone {
    String title = '';
    String uri = '';

    void setTone(String t, String u) {
      t = title;
      u = uri;
    }

    String getTitle() {
      return this.title;
    }

    String getUri() {
      return this.uri;
    }
  }
  
class _RingtonePickerScreenState extends State<RingtonePickerScreen> {
 // List<String> _ringtonesUri = [];
List<String> _ringtones = [];
 //  List<String> _ringtoneTitles = [];

 // List<Tone> _tones = [];

  String? _selectedRingtoneUri;

   

  @override
  void initState() {
    super.initState();
    _selectedRingtoneUri = widget.selectedRingtoneUri;
    _loadRingtones();
  }

  Future<void> _loadRingtones() async {
    // List<Ringtone> ringtones = await FlutterSystemRingtones.getRingtoneSounds();
    List<String> ringtones = ["A", "Ringetone"];
    setState(() {
      List <String>_ringtones = ringtones;
     // _ringtoneTitles = ringtones.map((rt) => rt.title).toList();
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Ringtone'),
      ),
      body: _ringtones.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _ringtones.length,
              itemBuilder: (context, index) {
                final ringtone = _ringtones[index];
                // return ListTile(
                //   title: Text(ringtone.title), // Display the ringtone URI or name
                //   trailing: _selectedRingtoneUri == ringtone.uri
                //       ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                //       : null,
                //   onTap: () {
                //     Navigator.pop(context, ringtone.uri); // Return the selected ringtone URI
                //   },
                // );
              },
            ),
    );
  }
}