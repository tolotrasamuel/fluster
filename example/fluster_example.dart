/*
 * Created by Alfonso Cejudo, Wednesday, July 24th 2019.
 */

import 'package:fluster/fluster.dart';
import 'package:fluster/src/cluster.dart';

void main() {
  const currentZoom = 10;

  var markers = <MapMarker>[
    MapMarker(
        data: MyData(
          locationName: 'One',
        ),
        markerId: '9000001',
        latitude: 40.736291,
        longitude: -73.990243),
    MapMarker(
        data: MyData(
          locationName: 'Two',
        ),
        markerId: '9000002',
        latitude: 40.731349,
        longitude: -73.997723),
    MapMarker(
        data: MyData(
          locationName: 'Three',
        ),
        markerId: '9000003',
        latitude: 40.670274,
        longitude: -73.964054),
    MapMarker(
        data: MyData(
          locationName: 'Four',
        ),
        markerId: '9000004',
        latitude: 38.889974,
        longitude: -77.019908),
  ];

  var fluster = Fluster<MyData>(
    minZoom: 0,
    maxZoom: 21,
    radius: 150,
    extent: 2048,
    nodeSize: 64,
    points: markers,
    createCluster: (Cluster cluster, double longitude, double latitude) =>
        ClusterableWithId(
      data: MyData(
        locationName: null,
      ),
      latitude: latitude,
      longitude: longitude,
      clusterId: cluster.id,
      pointsSize: cluster.pointsSize,
      markerId: cluster.id.toString(),
      childMarkerId: cluster.childMarkerId,
    ),
  );

  // [-180, -85, 180, 85]
  var clusters = fluster.clusters(
      west: -180, south: -85, east: 180, north: 85, zoom: currentZoom);

  print('Number of clusters at zoom $currentZoom: ${clusters.length}');
}

class MyData {
  String? locationName;
  String? thumbnailSrc;

  MyData({this.locationName, this.thumbnailSrc});
}

class MapMarker extends ClusterableWithData<MyData> {
  MapMarker(
      {required super.latitude,
      required super.longitude,
      required super.data,
      required super.markerId});
}
