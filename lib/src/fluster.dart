/*
 * Created by Alfonso Cejudo, Sunday, July 21st 2019.
 */

import 'dart:math' as math;

import 'base_cluster.dart';
import 'cluster.dart';
import 'clusterable.dart';
import 'kd_bush.dart';
import 'point_cluster.dart';

typedef CreateCluster<T> = T Function(
    Cluster, double, double);

/// The List to be clustered must contain objects that conform to Clusterable.
class Fluster<T> {
  /// Any zoom value below minZoom will not generate clusters.
  final int minZoom;

  /// Any zoom value above maxZoom will not generate clusters.
  final int maxZoom;

  /// Cluster radius in pixels.
  final int radius;

  /// Adjust the extent by powers of 2 (e.g. 512. 1024, ... max 8192) to get the
  /// desired distance between markers where they start to cluster.
  final int extent;

  /// The size of the KD-tree leaf node, which affects performance.
  final int nodeSize;

  /// The List to be clustered.
  final List<ClusterableWithData<T>> _points;

  /// Store the clusters for each zoom level.
  final List<KDBush?> _trees;

  /// A callback to generate clusters of the given input type.
  final CreateCluster<T> _createCluster;

  Fluster({
    required this.minZoom,
    required this.maxZoom,
    required this.radius,
    required this.extent,
    required this.nodeSize,
    required List<ClusterableWithData<T>> points,
    required CreateCluster<T> createCluster,
  })  : _points = points,
        _trees = List.filled(maxZoom + 2, null),
        _createCluster = createCluster {
    var clusters = <BaseCluster>[];

    for (var i = 0; i < _points.length; i++) {
      clusters.add(_createPointCluster(_points[i], i));
    }

    _trees[maxZoom + 1] = KDBush(
      points: clusters,
      nodeSize: nodeSize,
    );

    for (var z = maxZoom; z >= minZoom; z--) {
      clusters = _buildClusters(clusters, z);

      _trees[z] = KDBush(points: clusters, nodeSize: nodeSize);
    }
  }

  /// Returns a list of clusters that reside within the bounding box, where
  /// bbox = [southwestLng, southwestLat, northeastLng, northeastLat].
  ///
  /// The list is comprised of the original points passed into the constructor
  /// or clusters of points (and perhaps other clusters) produced by
  /// createCluster().
  List<ClusterableWithData<T>> clusters({
    required double west,
    required double south,
    required double east,
    required double north,
    required int zoom,
  }) {
    // final west = bbox.west;
    // final south = bbox.south;
    // final east = bbox.east;
    // final north = bbox.north;

    zoom += 1;
    var minLng = ((west + 180) % 360 + 360) % 360 - 180;
    var minLat = math.max<double>(-90, math.min(90, south));
    var maxLng = east == 180 ? 180.0 : ((east + 180) % 360 + 360) % 360 - 180;
    var maxLat = math.max<double>(-90, math.min(90, north));

    if (east - west >= 360) {
      minLng = -180;
      maxLng = 180.0;
    } else if (minLng > maxLng) {
      //minLng, minLat, 180, maxLat
      var easternHemisphere = clusters(
          west: minLng, south: minLat, east: 180, north: maxLat, zoom: zoom);
      // -180, minLat, maxLng, maxLat
      var westernHemisphere = clusters(
          west: -180, south: minLat, east: maxLng, north: maxLat, zoom: zoom);

      easternHemisphere.addAll(westernHemisphere);

      return easternHemisphere;
    }

    var tree = _trees[_limitZoom(zoom)];
    if (tree == null) {
      throw Exception('Invalid tree. Contact package maintainer.');
    }
    final ids =
        tree.range(_lngX(minLng), _latY(maxLat), _lngX(maxLng), _latY(minLat));

    var result = <ClusterableWithData<T>>[];

    for (var id in ids) {
      var c = tree.points[id];
      result.add(_getPointResult(c));
    }

    return result;
  }

  /// Returns a list of clusters that are children of the given cluster.
  ///
  /// The list is comprised of the original points passed into the constructor
  /// or clusters of points (and perhaps other clusters) produced by
  /// createCluster().
  List<ClusterableWithData<T>>? children(int? clusterId) {
    if (clusterId == null) {
      return null;
    }

    var originId = clusterId >> 5;
    var originZoom = clusterId % 32;

    var index = _trees[originZoom];
    if (index == null) {
      return null;
    }

    var origin = index.points[originId];

    var r = radius / (extent * math.pow(2, originZoom - 1));
    final ids = index.within(origin.x, origin.y, r);

    var children = <ClusterableWithData<T>>[];
    for (var id in ids) {
      var c = index.points[id];

      if (c.parentId == clusterId) {
        children.add(_getPointResult(c));
      }
    }

    return children;
  }

  ClusterableWithData<T> _getPointResult(BaseCluster c) {
    late final ClusterableWithData<T> ans;
    final pointsSize = c.pointsSize;
    if (pointsSize != null && pointsSize > 0) {
      if (c is! Cluster) throw Exception('c is not Cluster');
      ans = _tryCreateCluster(c, _xLng(c.x), _yLat(c.y));
    } else {
      if (c is! PointCluster) throw Exception('c is not PointCluster');
      ans = _points[c.index];
    }
    return ans;
  }

  /// Returns a list of standalone points (not clusters) that are children of
  /// the given cluster.
  List<ClusterableWithData<T>> points(int clusterId) {
    var points = <ClusterableWithData<T>>[];

    _extractClusterPoints(clusterId, points);

    return points;
  }

  /// Find the children that are individual media points, not other clusters.
  void _extractClusterPoints(
      int? clusterId, List<ClusterableWithData<T>> points) {
    var childList = children(clusterId);

    if (childList == null || childList.isEmpty) {
      return;
    } else {
      for (var child in childList) {
        if (child.isCluster) {
          _extractClusterPoints(child.clusterId, points);
        } else {
          points.add(child);
        }
      }
    }
  }

  PointCluster _createPointCluster(ClusterableWithData<T> feature, int id) {
    var x = _lngX(feature.longitude);
    var y = _latY(feature.latitude);

    return PointCluster(
        x: x, y: y, zoom: 24, index: id, markerId: feature.markerId);
  }

  List<BaseCluster> _buildClusters(List<BaseCluster> points, int zoom) {
    var clusters = <BaseCluster>[];
    var r = radius / (extent * math.pow(2, zoom));

    for (var i = 0; i < points.length; i++) {
      var p = points[i];
      if ((p.zoom ?? 0) <= zoom) {
        continue;
      }
      p.zoom = zoom;

      var tree = _trees[zoom + 1];
      var neighborIds = tree != null
          ? tree.within(
              p.x,
              p.y,
              r,
            )
          : [];

      var pointsSize = p.pointsSize ?? 1;
      var wx = (p.x) * pointsSize;
      var wy = (p.y) * pointsSize;

      var childMarkerId;
      if (p.childMarkerId != null) {
        childMarkerId = p.childMarkerId;
      } else {
        childMarkerId = p.markerId;
      }

      var id = (i << 5) + (zoom + 1);

      for (int neighborId in neighborIds) {
        var b = tree?.points[neighborId];
        if (b == null) {
          continue;
        }

        if ((b.zoom ?? -1) <= zoom) {
          continue;
        }
        b.zoom = zoom;

        var pointsSize2 = b.pointsSize ?? 1;
        wx += (b.x) * pointsSize2;
        wy += (b.y) * pointsSize2;

        pointsSize += pointsSize2;
        b.parentId = id;
      }

      if (pointsSize == 1) {
        clusters.add(p);
      } else {
        p.parentId = id;
        clusters.add(Cluster(
            x: wx / pointsSize,
            y: wy / pointsSize,
            id: id,
            pointsSize: pointsSize,
            childMarkerId: childMarkerId));
      }
    }

    return clusters;
  }

  double _lngX(double lng) {
    return lng / 360 + 0.5;
  }

  double _latY(double lat) {
    var sin = math.sin(lat * math.pi / 180);
    var y = 0.5 - 0.25 * math.log((1 + sin) / (1 - sin)) / math.pi;

    return y < 0
        ? 0
        : y > 1
            ? 1
            : y;
  }

  double _xLng(double x) {
    return (x - 0.5) * 360;
  }

  double _yLat(double y) {
    var y2 = (180 - y * 360) * math.pi / 180;
    return 360 * math.atan(math.exp(y2)) / math.pi - 90;
  }

  int _limitZoom(int z) {
    return math.max(minZoom, math.min(z, maxZoom + 1));
  }

  ClusterableWithId<T> _tryCreateCluster(Cluster c, double xLng, double yLat) {
    final data = _createCluster(c, xLng, yLat);
    return ClusterableWithId<T>(
      data: data,
      latitude: yLat,
      longitude: xLng,
      clusterId: c.id,
      pointsSize: c.pointsSize,
      markerId: c.markerId,
      childMarkerId: c.childMarkerId,
    );
  }
}
