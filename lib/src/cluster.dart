/*
 * Created by Alfonso Cejudo, Sunday, July 21st 2019.
 */

import 'base_cluster.dart';

class Cluster extends BaseCluster {
  @override
  final int id;

  @override
  final int pointsSize;

  Cluster({
    required super.x,
    required super.y,
    required this.id,
    required this.pointsSize,
    String? childMarkerId,
  }) {
    this.childMarkerId = childMarkerId;
    isCluster = true;
    zoom = 24; // Max value.
    parentId = -1;
  }
}
