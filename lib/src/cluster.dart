/*
 * Created by Alfonso Cejudo, Sunday, July 21st 2019.
 */

import 'base_cluster.dart';

class Cluster extends BaseCluster {
  Cluster({
    required super.x,
    required super.y,
    int? id,
    int? pointsSize,
    String? childMarkerId,
  }) {
    this.id = id;
    this.pointsSize = pointsSize;
    this.childMarkerId = childMarkerId;

    isCluster = true;
    zoom = 24; // Max value.
    parentId = -1;
  }
}
