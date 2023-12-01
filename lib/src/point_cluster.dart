/*
 * Created by Alfonso Cejudo, Sunday, July 21st 2019.
 */

import 'base_cluster.dart';

class PointCluster extends BaseCluster {
  PointCluster({
    required super.x,
    required super.y,
    int? zoom,
    int? index,
    String? markerId,
  }) {
    this.zoom = zoom;
    this.index = index;
    this.markerId = markerId;

    parentId = -1;
    isCluster = false;
  }
}
