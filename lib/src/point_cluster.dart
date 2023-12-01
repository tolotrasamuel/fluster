/*
 * Created by Alfonso Cejudo, Sunday, July 21st 2019.
 */

import 'base_cluster.dart';

class PointCluster extends BaseCluster {
  @override
  final int index;
  PointCluster({
    required super.x,
    required super.y,
    int? zoom,
    required this.index,
    String? markerId,
  }) {
    this.zoom = zoom;
    this.markerId = markerId;

    parentId = -1;
    isCluster = false;
  }
}
