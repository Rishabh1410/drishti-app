import 'package:flutter/material.dart';
import 'package:drishti/direction_model.dart';
import 'package:drishti/directions_repository.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';


class MapPage extends StatelessWidget {
  final destination;
  const MapPage({Key key,this.destination}):super(key:key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color.fromRGBO(0, 172, 193, 1),
      ),
      home: MapScreen(destination:destination),
    );
  }
}

class MapScreen extends StatefulWidget {
  final destination;
  const MapScreen({Key key,this.destination}):super(key: key);
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(25.3176, 82.9739),
    zoom: 3.5,
  );
  FlutterTts tts;
  GoogleMapController _googleMapController;
  Marker _origin;
  Marker _destination;
  var route;
  Directions _info;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tts = FlutterTts();
    tts.speak('long press on the screen to navigate');
    /*bluetooth.startScan(timeout: Duration(seconds:30));
    var subs = bluetooth.scanResults.listen((event) {
      for(ScanResult r in event){
        print('${r.device.name}found! rssi : ${r.rssi}');
    }});
    bluetooth.stopScan();*/
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    route = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      drawerScrimColor: Colors.white,
                drawer: Drawer(
                  elevation: 1,
                ),
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Drishti',style: TextStyle(fontSize: 23),),
        actions: [
          if (_origin != null)
            TextButton(
              onPressed: () => _googleMapController.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _origin.position,
                    zoom: 18.5,
                    tilt: 50.0,
                  ),
                ),
              ),
              style: TextButton.styleFrom(
                primary: Colors.tealAccent,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text('ORIGIN',style: TextStyle(),),
            ),
          if (_destination != null)
            TextButton(
              onPressed: () => _googleMapController.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _destination.position,
                    zoom: 12.5,
                    tilt: 50.0,
                  ),
                ),
              ),
              style: TextButton.styleFrom(
                primary: Colors.indigo[700],
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text('DEST'),
            )
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onDoubleTap: () async{
              _determinePosition().then((value){
                DirectionsRepository().rev_geocode(value.latitude, value.longitude).then((value) {
                  tts.speak('your current location is $value');
                });
              });
            },
            child: GoogleMap(
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              initialCameraPosition: _initialCameraPosition,
              onMapCreated: (controller) => _googleMapController = controller,
              markers: {
                if (_origin != null) _origin,
                if (_destination != null) _destination
              },
              polylines: {
                if (_info != null)
                  Polyline(
                    polylineId:  PolylineId('overview_polyline'),
                    color: Colors.red,
                    width: 5,
                    points: _info.polylinePoints
                        .map((e) => LatLng(e.latitude, e.longitude))
                        .toList(),
                  ),
              },
              onLongPress: (argument) {
                _addMarker();
                print(argument.latitude.toStringAsFixed(5));
                print(argument.longitude);
              },
            ),
          ),
          if (_info != null)
            Positioned(
              top: 20.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 12.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white60,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 6.0,
                    )
                  ],
                ),
                child: Text(
                  '${_info.totalDistance}m, ${(_info.totalDuration/60).ceil()}mins',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        onPressed: ()async{
          _determinePosition().then((value){
                DirectionsRepository().rev_geocode(value.latitude, value.longitude).then((value) {
                  tts.speak(value);
                });
              });},
      // _googleMapController.animateCamera(
          // _info != null
          //     ? CameraUpdate.newLatLngBounds(_info.bounds, 100.0)
          //     : CameraUpdate.newCameraPosition(_initialCameraPosition),
        //),
        child: const Icon(Icons.mic_rounded),
      ),
    );
  }

  void _addMarker() async {
    print('${widget.destination}  is here');
    // Origin is not set OR Origin/Destination are both set
    // Set origin
    _determinePosition().then((value)async{
      print(value);
      await DirectionsRepository().getLatLong(widget.destination).then((des) {
        print(des);
        setState((){
          _origin = Marker(
            markerId:  MarkerId('origin'),
            infoWindow: const InfoWindow(title: 'Origin'),
            icon:BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            position: LatLng(value.latitude,value.longitude),
          );

          _destination = Marker(
            markerId:  MarkerId('destination'),
            infoWindow: const InfoWindow(title: 'Destination'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            position: LatLng(des['latitude'],des['longitude']),
          );
        });
      });

      DirectionsRepository().rev_geocode(value.latitude, value.longitude).then((value){
        DirectionsRepository().getDirections(origin:'$value', destination: widget.destination).then((value)async{ setState(() => _info = value);
        await tts.speak('navigation has started,you are ready to go');
        await tts.speak('you are ${(_info.totalDuration/60).ceil()} minutes away from your destination');
        await tts.speak('you can double tap anytime anywhere on the screen to know your current location');
        });});
    }
    );
  }
}
Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the 
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale 
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately. 
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.');
  } 

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}