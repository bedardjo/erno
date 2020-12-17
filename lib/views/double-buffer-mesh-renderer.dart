import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:erno/entity/entity.dart';
import 'package:erno/geometry/face.dart';
import 'package:erno/geometry/vertex.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

class DoubleBufferMeshRenderer extends StatefulWidget {
  final Size size;
  final Matrix4 model;
  final Matrix4 view;
  final Matrix4 projection;

  final List<Entity> entities;

  const DoubleBufferMeshRenderer(
      {Key key,
      this.size,
      this.model,
      this.view,
      this.projection,
      this.entities})
      : super(key: key);

  @override
  DoubleBufferMeshRendererState createState() =>
      DoubleBufferMeshRendererState();
}

class DepthBuffer {
  final List<List<double>> buffer;

  DepthBuffer(this.buffer);

  void clear() {
    for (int y = 0; y < buffer.length; y++) {
      for (int x = 0; x < buffer[y].length; x++) {
        buffer[y][x] = 10000;
      }
    }
  }

  double getDepth(int y, int x) {
    return buffer[y][x];
  }

  void setDepth(int y, int x, double depth) {
    buffer[y][x] = depth;
  }
}

class DoubleBufferMeshRendererState extends State<DoubleBufferMeshRenderer> {
  List<Int32List> screenBuffers = [];
  DepthBuffer depthBuffer;
  int currentBuffer = 0;

  ui.Image lastFrame;
  Future<ui.Image> currentFrame;

  int bufferWidth;
  int bufferHeight;

  Color transparent = Color.fromARGB(0, 0, 0, 0);

  @override
  void initState() {
    super.initState();
    bufferWidth = (widget.size.width * .25).ceil();
    bufferHeight = (widget.size.height * .25).ceil();
    screenBuffers = [
      Int32List(bufferWidth * bufferHeight),
      Int32List(bufferWidth * bufferHeight),
    ];
    List<List<double>> db = List<List<double>>.generate(bufferHeight,
        (index) => List<double>.generate(bufferWidth, (index) => 10000));
    depthBuffer = DepthBuffer(db);

    drawFrame();
  }

  @override
  void didUpdateWidget(DoubleBufferMeshRenderer oldRenderer) {
    super.didUpdateWidget(oldRenderer);
    print('did update');
    drawFrame();
  }

  void drawAllFaces(Matrix4 p, Entity e) {
    Matrix4 mvp = p * e.model;
    if (e.mesh != null) {
      for (Face f in e.mesh.faces) {
        double minY = 100000;
        double maxY = -100000;
        List<Vector3> pixels = [];
        for (Vertex v in f.vertices) {
          Vector4 translated = mvp * Vector4(v.v.x, v.v.y, v.v.z, 1.0);
          Vector3 pixel = Vector3(
              bufferWidth / 2.0 + translated.x / translated.w * bufferWidth,
              bufferHeight / 2.0 - translated.y / translated.w * bufferHeight,
              translated.z / translated.w);
          if (pixel.y < minY) {
            minY = pixel.y;
          }
          if (pixel.y > maxY) {
            maxY = pixel.y;
          }
          pixels.add(pixel);
        }
        fillScanlines(minY, maxY, pixels, f.vertices[0].c);
      }
    }
    for (Entity child in e.children) {
      drawAllFaces(mvp, child);
    }
  }

  void drawFrame() {
    Matrix4 globalMVP = widget.projection * widget.view * widget.model;
    for (int y = 0; y < bufferHeight; y++) {
      for (int x = 0; x < bufferWidth; x++) {
        depthBuffer.buffer[y][x] = 10000;
        screenBuffers[currentBuffer][y * bufferWidth + x] = transparent.value;
      }
    }

    for (Entity m in widget.entities) {
      drawAllFaces(globalMVP, m);
    }
    setState(() {
      currentFrame =
          getImage(bufferWidth, bufferHeight, screenBuffers[currentBuffer])
              .then((value) {
        this.lastFrame = value;
        return value;
      });
    });

    currentBuffer = (currentBuffer + 1) % screenBuffers.length;
  }

  List<Vector3> getXIntersections(int y, List<Vector3> pixels) {
    List<Vector3> intersections = [];
    Vector3 prev = pixels[pixels.length - 1];
    for (Vector3 px in pixels) {
      if ((prev.y <= y && y <= px.y) || (px.y <= y && y <= prev.y)) {
        Vector3 dir = px - prev;
        double t = (y - prev.y) / dir.y;
        intersections.add(prev + dir * t);
      }
      prev = px;
    }
    intersections.sort((i1, i2) => i1.x.compareTo(i2.x));
    return intersections;
  }

  void fillScanlines(double minY, double maxY, List<Vector3> pixels, Color c) {
    for (int y = max(0, minY.round()); y <= min(bufferHeight - 1, maxY); y++) {
      List<Vector3> intersections = getXIntersections(y, pixels);

      for (int i = 1; i < intersections.length; i += 2) {
        Vector3 i1 = intersections[i - 1];
        Vector3 i2 = intersections[i];

        Vector3 diff = i2 - i1;
        for (int x = max(0, i1.x.round());
            x <= min(bufferWidth - 1, i2.x.round());
            x++) {
          double t = (x - i1.x) / diff.x;
          double depth = i1.z + diff.z * t;
          if (depth < depthBuffer.getDepth(y, x)) {
            depthBuffer.setDepth(y, x, depth);
            screenBuffers[currentBuffer][y * bufferWidth + x] = c.value;
          }
        }
      }
    }
  }

  Future<ui.Image> getImage(int width, int height, Int32List pixels) {
    Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(),
      width,
      height,
      ui.PixelFormat.bgra8888,
      (ui.Image img) {
        completer.complete(img);
      },
    );

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: currentFrame,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return CustomPaint(
              size: widget.size,
              painter: FramePainter(snapshot.data),
            );
          } else if (lastFrame != null) {
            return CustomPaint(
              size: widget.size,
              painter: FramePainter(lastFrame),
            );
          } else {
            return CircularProgressIndicator();
          }
        });
  }
}

Paint p = Paint()..color = Color.fromARGB(255, 255, 255, 255);

class FramePainter extends CustomPainter {
  final ui.Image frame;

  FramePainter(this.frame);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawVertices(
        ui.Vertices(VertexMode.triangleFan, [
          Offset(0, 0),
          Offset(0, size.height),
          Offset(size.width, size.height),
          Offset(size.width, 0)
        ], textureCoordinates: [
          Offset(0, 0),
          Offset(0, frame.height.toDouble()),
          Offset(frame.width.toDouble(), frame.height.toDouble()),
          Offset(frame.width.toDouble(), 0)
        ]),
        BlendMode.dst,
        Paint()
          ..shader = ImageShader(frame, TileMode.clamp, TileMode.clamp,
              Matrix4.identity().storage));
  }

  @override
  bool shouldRepaint(FramePainter old) => frame != old.frame;
}
