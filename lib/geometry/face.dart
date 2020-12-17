import 'dart:ui';

import 'package:erno/geometry/vertex.dart';

class Face {
  final List<Vertex> vertices;

  Face({this.vertices});

  Face withNewColor(Color color) {
    return Face(
        vertices: vertices.map((v) => Vertex(v: v.v, c: color)).toList());
  }
}
