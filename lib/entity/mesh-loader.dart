import 'package:erno/geometry/face.dart';
import 'package:erno/geometry/mesh.dart';
import 'package:erno/geometry/vertex.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:flutter/services.dart';

/// Assumes the given path is a text-file-asset.
Future<String> getFileData(String path) async {
  return await rootBundle.loadString(path);
}

/// This expects the asset to be specified without an extension
/// and it will look for a corresponding .obj and .mtl file.
Future<Mesh> loadMesh(String path, Color color) async {
  String objData = await getFileData(path);

  List<Vector3> vertexLibrary = [];
  List<Vector2> textureCoordinateLibrary = [];
  List<Vector3> normalLibrary = [];
  List<Face> faceLibrary = [];
  List<String> objLines = objData.split("\n").map((e) => e.trim()).toList();
  for (String line in objLines) {
    List<String> lineParts = line.split(" ");
    switch (lineParts[0]) {
      case "v":
        vertexLibrary.add(Vector3(
          double.parse(lineParts[1]),
          double.parse(lineParts[2]),
          double.parse(lineParts[3]),
        ));
        break;
      case "vt":
        textureCoordinateLibrary.add(Vector2(
          double.parse(lineParts[1]),
          1.0 - double.parse(lineParts[2]),
        ));
        break;
      case "vn":
        normalLibrary.add(Vector3(
          double.parse(lineParts[1]),
          double.parse(lineParts[2]),
          double.parse(lineParts[3]),
        ));
        break;
      case "usemtl":
        // do nothing
        break;
      case "f":
        List<Vertex> faceVertices = [];
        for (String linePart in lineParts.sublist(1, lineParts.length)) {
          List<String> lineSubParts = linePart.split("/");
          int vertIndex = int.parse(lineSubParts[0]) - 1;
          faceVertices.add(Vertex(v: vertexLibrary[vertIndex], c: color));
        }
        faceLibrary.add(Face(vertices: faceVertices));
        break;
    }
  }
  return Mesh(faces: faceLibrary);
}
