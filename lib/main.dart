import 'dart:math';

import 'package:erno/entity/entity.dart';
import 'package:erno/entity/mesh-loader.dart';
import 'package:erno/geometry/matrices.dart';
import 'package:erno/geometry/mesh.dart';
import 'package:erno/views/double-buffer-mesh-renderer.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  runApp(ErnoApp());
}

class ErnoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ERNO!!',
      home: RubiksCubeApp(),
    );
  }
}

class RubiksCubeApp extends StatefulWidget {
  @override
  RubiksCubeAppState createState() => RubiksCubeAppState();
}

class RubiksCubeAppState extends State<RubiksCubeApp> {
  Future<Mesh> bevelledCube;
  Future<Mesh> facePlate;
  @override
  void initState() {
    super.initState();
    bevelledCube = loadMesh(
        "assets/models/bevelled_cube.obj", Color.fromARGB(255, 5, 5, 5));
    facePlate = loadMesh(
        "assets/models/face_plate.obj", Color.fromARGB(255, 210, 70, 70));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([bevelledCube, facePlate]),
        builder: (context, snapshot) => snapshot.hasData
            ? RubiksCube(
                bevelledCube: snapshot.data[0],
                facePlate: snapshot.data[1],
              )
            : CircularProgressIndicator());
  }
}

class RubiksCube extends StatefulWidget {
  final Mesh bevelledCube;
  final Mesh facePlate;

  const RubiksCube({Key key, this.bevelledCube, this.facePlate})
      : super(key: key);

  @override
  RubiksCubeState createState() => RubiksCubeState();
}

class RubiksCubeState extends State<RubiksCube> {
  Vector3 cameraPosition;
  double cameraRotation = 0;
  double cameraHeight = 10.0;
  Matrix4 model;
  Matrix4 view;
  Matrix4 projection;

  List<Entity> cubeParts = [];

  double cameraHeightStart;
  double cameraRotatonPanStart;
  Offset panDown;

  @override
  void initState() {
    super.initState();
    cameraPosition = Vector3(
        10.0 * cos(cameraRotation), cameraHeight, -10.0 * sin(cameraRotation));
    model = Matrix4.translation(-cameraPosition);
    view = lookat(
        Vector3.zero(), -cameraPosition.normalized(), Vector3(0, 1.0, 0));
    projection = frustum(-1.0, 1.0, -1.0, 1.0, 2.0, 20.0);

    for (int y = -1; y <= 1; y++) {
      for (int x = -1; x <= 1; x++) {
        for (int z = -1; z <= 1; z++) {
          Entity part = Entity(widget.bevelledCube);
          part.model = Matrix4.translation(
              Vector3(x.toDouble(), y.toDouble(), z.toDouble()));
          cubeParts.add(part);
        }
      }
    }

    Entity ul = Entity(widget.bevelledCube);
    ul.model = Matrix4.translation(Vector3(-1.0, 1.0, -1.0));
    cubeParts.add(ul);

    Entity fp3 =
        Entity(widget.facePlate.withNewColor(Color.fromARGB(255, 255, 70, 0)));
    fp3.model =
        Matrix4.translation(Vector3(-.51, 0, 0)) * Matrix4.rotationZ(pi / 2);
    ul.children.add(fp3);

    Entity fp1 = Entity(widget.facePlate);
    fp1.model = Matrix4.translation(Vector3(0, .51, 0));
    ul.children.add(fp1);
    Entity fp2 =
        Entity(widget.facePlate.withNewColor(Color.fromARGB(255, 0, 255, 0)));
    fp2.model =
        Matrix4.translation(Vector3(0, 0, -.51)) * Matrix4.rotationX(-pi / 2);
    ul.children.add(fp2);

    Entity um = Entity(widget.bevelledCube);
    um.model = Matrix4.translation(Vector3(0.0, 1.0, -1.0));
    cubeParts.add(um);

    Entity ur = Entity(widget.bevelledCube);
    ur.model = Matrix4.translation(Vector3(1.0, 1.0, -1.0));
    cubeParts.add(ur);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 210, 210, 255),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
              onPanDown: (details) {
                cameraHeightStart = cameraHeight;
                cameraRotatonPanStart = cameraRotation;
                panDown = details.localPosition;
              },
              onPanUpdate: (details) {
                setState(() {
                  Offset movement = details.localPosition - panDown;
                  cameraRotation = cameraRotatonPanStart - (movement.dx * .01);
                  cameraHeight = cameraHeightStart + movement.dy * .1;

                  cameraPosition = Vector3(10.0 * cos(cameraRotation),
                      cameraHeight, -10.0 * sin(cameraRotation));
                  model = Matrix4.translation(-cameraPosition);
                  view = lookat(Vector3.zero(), -cameraPosition.normalized(),
                      Vector3(0, 1.0, 0));
                });
              },
              child: AspectRatio(
                  aspectRatio: 1.0,
                  child: LayoutBuilder(
                    builder: (context, constraints) => DoubleBufferMeshRenderer(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        model: model,
                        view: view,
                        projection: projection,
                        entities: cubeParts),
                  )))
        ],
      ),
    );
  }
}
