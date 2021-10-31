import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:drishti/.env.dart';
import 'package:drishti/direction_model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsRepository {
  static const String _baseUrl =
      'https://apis.mapmyindia.com/advancedmaps/v1/d91wqt9lsbqttwadcby544te8zhnp532/route_adv/walking';

  final Dio _dio;

  DirectionsRepository({Dio dio}) : _dio = dio ?? Dio();

  Future<Directions> getDirections({
    @required String origin,
    @required String destination,
  }) async {
    String origin_loc =await getLocation(origin);
    String des_loc = await getLocation(destination);
    final response = await _dio.get(
      _baseUrl + '/' + '$origin_loc;$des_loc'
      // queryParameters: {
      //   'origin': '${origin.latitude},${origin.longitude}',
      //   'destination': '${destination.latitude},${destination.longitude}',
      //   'key': googleAPIKey,
      // },
    );
    if(response.statusCode == 200)
    {
    print(response.data['routes']);
    return Directions.fromMap(response.data);
    }
    return null;
  }

  Future<String> getLocation(String place)async{
    _dio.options.headers["Authorization"] = "Bearer ${token}";
    final eLoc = await _dio.get('https://atlas.mapmyindia.com/api/places/geocode'
    ,queryParameters: {
      'address':place
    }
    );
    if(eLoc.statusCode ==200){
      var loc = eLoc.data['copResults']['eLoc'];
      print('$loc is eloc of $place');
     return loc;
    }
    return null;
  }

  Future<Map<String,double>> getLatLong(String place)async{
    _dio.options.headers["Authorization"] = "Bearer $token";
    String place_id = await getLocation(place);
    final location = await _dio.get('https://apis.mapmyindia.com/advancedmaps/v1/d91wqt9lsbqttwadcby544te8zhnp532/place_detail'
    ,queryParameters: {
      'place_id':place_id,
      'region':'IND'
    }
    );
    print(location.data);
    print("andar wala data");
    return {'latitude' : double.parse(location.data['results'][0]['latitude']),
      'longitude':double.parse(location.data['results'][0]['longitude'])
    };
  }

  Future<String> rev_geocode(double lat,double long)async{
    final address = await _dio.get('https://apis.mapmyindia.com/advancedmaps/v1/d91wqt9lsbqttwadcby544te8zhnp532/rev_geocode'
    ,queryParameters: {
      'lat': lat,
      'lng': long,
      'REST_KEY': 'd91wqt9lsbqttwadcby544te8zhnp532'
    }
    );
    print('reverse geo code is here');
    print(address.data['results'][0]['formatted_address']);
    return address.data['results'][0]['formatted_address'];
  }
}