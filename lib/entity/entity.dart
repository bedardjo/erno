import 'package:erno/geometry/mesh.dart';
import 'package:vector_math/vector_math_64.dart';

class Entity {
  Matrix4 model = Matrix4.identity();
  final Mesh mesh;
  List<Entity> children = [];

  Entity(this.mesh);
}
