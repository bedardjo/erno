import 'package:erno/entity/entity.dart';
import 'package:erno/geometry/face.dart';
import 'package:erno/geometry/vertex.dart';
import 'package:flutter/cupertino.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:ui' as ui;

class MeshRenderer extends StatefulWidget {
  final Matrix4 model;
  final Matrix4 view;
  final Matrix4 projection;

  final List<Entity> entities;

  const MeshRenderer(
      {Key key, this.model, this.view, this.projection, this.entities})
      : super(key: key);
  @override
  MeshRendererState createState() => MeshRendererState();
}

class MeshRendererState extends State<MeshRenderer> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: MeshPainter(
            model: widget.model,
            view: widget.view,
            projection: widget.projection,
            entities: widget.entities));
  }
}

Paint unusedPaint = Paint()..color = Color.fromARGB(255, 255, 255, 255);

class MeshPainter extends CustomPainter {
  final Matrix4 model;
  final Matrix4 view;
  final Matrix4 projection;

  final List<Entity> entities;

  ui.Image img;

  MeshPainter({this.model, this.view, this.projection, this.entities});

  void projectAllFaces(Matrix4 p, Entity e, List<Face> projectedFaces) {
    Matrix4 mvp = p * e.model;
    if (e.mesh != null) {
      for (Face f in e.mesh.faces) {
        List<Vertex> projectedVerts = [];
        for (Vertex v in f.vertices) {
          Vector4 translated = mvp * Vector4(v.v.x, v.v.y, v.v.z, 1.0);
          Vector3 perspectiveDivided = Vector3(translated.x / translated.w,
              translated.y / translated.w, translated.z / translated.w);
          projectedVerts.add(Vertex(v: perspectiveDivided, c: v.c));
        }
        projectedFaces.add(Face(vertices: projectedVerts));
      }
    }
    for (Entity child in e.children) {
      projectAllFaces(mvp, child, projectedFaces);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    Matrix4 globalMVP = projection * view * model;
    List<Face> projectedFaces = [];
    for (Entity m in entities) {
      projectAllFaces(globalMVP, m, projectedFaces);
    }
    projectedFaces.sort((Face f1, Face f2) {
      double f1MinZ = f1.vertices
          .reduce((value, element) => value.v.z < element.v.z ? value : element)
          .v
          .z;
      double f2MinZ = f2.vertices
          .reduce((value, element) => value.v.z < element.v.z ? value : element)
          .v
          .z;
      return f1MinZ < f2MinZ ? 1 : -1;
    });
    drawProjectedFaces(projectedFaces, canvas, size);
    canvas.restore();
  }

  void drawProjectedFaces(List<Face> projectedFaces, Canvas canvas, Size size) {
    for (Face f in projectedFaces) {
      canvas.drawVertices(
          ui.Vertices(
              VertexMode.triangles,
              f.vertices
                  .map((v) => Offset(size.width / 2.0 + v.v.x * size.width,
                      size.height / 2.0 - v.v.y * size.height))
                  .toList(),
              colors: f.vertices.map((v) => v.c).toList()),
          BlendMode.dst,
          unusedPaint);
    }
  }

  @override
  bool shouldRepaint(MeshPainter old) {
    return true;
  }
}
