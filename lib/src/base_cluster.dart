/*
 * Created by Alfonso Cejudo, Sunday, July 21st 2019.
 */

// abstract class BaseClusterWithId extends BaseCluster {
//   @override
//   final int id;
//
//   BaseClusterWithId({
//     required this.id,
//     required super.x,
//     required super.y,
//   });
// }

abstract class BaseCluster {
  double x;
  double y;
  int? zoom;
  int? pointsSize;
  int? parentId;
  int? index;
  int? id;
  bool isCluster = false;

  /// For PointCluster instances that are standalone (i.e. not cluster) items.
  String? markerId;

  /// For clusters that wish to display one representation of its children.
  String? childMarkerId;

  BaseCluster({
    required this.y,
    required this.x,
  });
}
