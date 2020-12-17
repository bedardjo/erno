import 'package:erno/geometry/face.dart';
import 'package:flutter/material.dart';

class Mesh {
  final List<Face> faces;

  Mesh({this.faces});

  Mesh withNewColor(Color color) {
    return Mesh(faces: faces.map((f) => f.withNewColor(color)).toList());
  }
}
