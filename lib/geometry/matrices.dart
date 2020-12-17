import 'package:vector_math/vector_math_64.dart';

/**
 * All matrices are column major (as is flutter's Matrix4)
 */
Matrix4 lookat(Vector3 eye, Vector3 p, Vector3 up) {
  Vector3 zaxis = (eye - p).normalized();
  Vector3 xaxis = up.cross(zaxis).normalized();
  Vector3 yaxis = zaxis.cross(xaxis);
  return Matrix4(
      xaxis.x,
      yaxis.x,
      zaxis.x,
      0,
      xaxis.y,
      yaxis.y,
      zaxis.y,
      0,
      xaxis.z,
      yaxis.z,
      zaxis.z,
      0,
      -xaxis.dot(eye),
      -yaxis.dot(eye),
      -zaxis.dot(eye),
      1);
}

Matrix4 frustum(double left, double right, double bottom, double top,
    double near, double far) {
  return Matrix4(
      2.0 * near / (right - left),
      0,
      0,
      0,
      0,
      2.0 * near / (top - bottom),
      0,
      0,
      (right + left) / (right - left),
      (top + bottom) / (top - bottom),
      -(near + far) / (far - near),
      -1.0,
      0,
      0,
      -2.0 * near * far / (far - near),
      0);
}
