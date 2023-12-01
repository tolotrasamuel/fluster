/*
 * Created by Alfonso Cejudo, Wednesday, July 24th 2019.
 */

import 'package:fluster/fluster.dart';
import 'package:test/test.dart';

import 'common.dart';

void main() {
  group('Fluster API Tests', () {
    late Fluster fluster;

    setUp(() {
      fluster = Fluster(
          minZoom: 0,
          maxZoom: 20,
          radius: 150,
          extent: 2048,
          nodeSize: 0,
          points: <Clusterable>[],
          createCluster: (cluster, longitude, latitude) {
            return MockClusterable();
          });
    });

    test('Empty Set Test', () {
      // -180, -85, 180, 85
      expect(
          fluster
              .clusters(west: -180, south: -85, east: 180, north: 85, zoom: 2)
              .length,
          0);
    });
  });
}
