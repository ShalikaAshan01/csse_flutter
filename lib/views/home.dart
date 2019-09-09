import 'dart:async';

import 'package:csse/views/map_sample.dart';
import 'package:csse/views/qr_scanner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class Home extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _Home();
  }
}

class _Home extends State<Home> {
  StreamSubscription<Position> _positionStreamSubscription;
  Position _position = Position();
  Placemark _placemark;
  String _address = '';

  GoogleMapController mapController;
  Set<Marker> markers = Set();
  LatLng _latLng =LatLng(7.8731,80.7718);

  @override
  void initState() {
    super.initState();
    _listening();
  }

  @override
  void didUpdateWidget(Home oldWidget) {
    super.didUpdateWidget(oldWidget);
    _listening();
  }
  @override
  void dispose() {
    super.dispose();
    _listening();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Easy Travel Drivers"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => QrScanner()));
        },
        label: Text("Scan"),
        icon: Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Container
        (child: displayLocation()),
    );
  }


  ///check permission and display map
  Widget displayLocation(){
    return FutureBuilder<GeolocationStatus>(
      future: Geolocator().checkGeolocationPermissionStatus(),
      builder: (BuildContext context, AsyncSnapshot<GeolocationStatus> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == GeolocationStatus.denied) {

          PermissionHandler().shouldShowRequestPermissionRationale(PermissionGroup.location)
          .then((bool val){
            if(!val){
              Alert(
                  context: context,
                  title: "Access to location denied",
                  desc: "Allow access to the location services for this App using the device settings.After Enabling please restart the app",
                buttons: [
                  DialogButton(
                    child: Text(
                      "Ok",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    onPressed: () => PermissionHandler().openAppSettings(),
                    width: 120,
                  )
                ],
              ).show();
//              PermissionHandler().openAppSettings();
            }
          });

          return _permissionDenied('Access to location denied',
              'Allow access to the location services for this App using the device settings.');
        }
        return _displayMap();
      },
    );
  }

  ///show map
  Widget _displayMap(){
    if(_position.longitude != null){
      return Container(
        child: Column(
          children: <Widget>[
            Text(_position.toString()),
            Text(_position.timestamp.toIso8601String()),
            Text(_address),
            Expanded(
                child: GoogleMap(
                  onMapCreated: (GoogleMapController controller){
                    mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: _latLng,
                    zoom: 20.0
                  ),

                  myLocationEnabled: true,
                )
            )
          ],
        ),
      );
    }
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Center(child: CircularProgressIndicator()),
        Padding(
          padding: const EdgeInsets.only(top:8.0),
          child: Text("Loading...",style: TextStyle(fontWeight: FontWeight.bold),),
        )
      ],
    ));
}

  ///get current location
  void  _listening() {
    LocationOptions locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
    final Stream<Position> positionStream =
    Geolocator().getPositionStream(locationOptions);
    _positionStreamSubscription = positionStream.listen((Position position) async{
        mapController?.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(_position.latitude, _position.longitude),
              zoom: 20.0
            ),
          )
        );
        _position = position;
        getPlacemark();
    });
  }

  Future<void> getPlacemark() async {
    String address = 'unknown';
    final List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(_position.latitude, _position.longitude);

    if (placemarks != null && placemarks.isNotEmpty) {
      address = _buildAddressString(placemarks.first);
    }

    setState(() {
      _address = '$address';
    });
  }
  static String _buildAddressString(Placemark placemark) {
    final String name = placemark.name ?? '';
    final String city = placemark.locality ?? '';
    final String state = placemark.administrativeArea ?? '';
    final String country = placemark.country ?? '';

    return '$name, $city, $state, $country';
  }

  Widget _permissionDenied(String title,String text){
    
//    showDialog(
//        context: context,
//        builder: (BuildContext context){
//          return AlertDialog(
//            title: Text(title),
//            content: Text(text),
//            actions: <Widget>[
//              FlatButton(
//                child: Text("Ok"),
//                onPressed: (){
//
//                },
//              )
//            ],
//          );
//        }
//    );
    
    return Container(
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(child: Text(title,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20.0),),),
            Container(child: Text(text,style: TextStyle(fontSize: 20.0,),),),
          ],
        ),
      ),
    );
  }
}

//        _latLng = LatLng(_position.latitude, _position.longitude);
//        markers.add(Marker(
//          markerId: MarkerId("Location"),
//          position: LatLng(_position.latitude, _position.longitude),
//            infoWindow: InfoWindow(title: "Las"),
//            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
//        ));