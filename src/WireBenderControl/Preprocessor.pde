public class Preprocessor {
  Shape shape;
  CAM cam;
  ArrayList<Shape> calcSteps;

  public Preprocessor(Shape shape) {
    this.shape = shape.copy();
  }

  public Preprocessor() {
  }

  public void setShape(Shape shape) {
    this.shape = shape.copy();
  }

  public Shape preprocessShape() {
    // reverse Point list
    shape.reverseOrder();  
    debug(shape.toString());

    // normazile points by 0-centering
    shape.zeroCenter(shape.getPoint(0)); 

    return shape.copy();
  }

  public void calcCAM() {
    this.cam = new CAM();
    calcSteps = new ArrayList<Shape>();

    for (int i = 0; i < this.shape.getLength() - 1; i++) {
      float distance = 0.0;
      float bendAngle = 0.0;
      float benderRotationAngle = 0.0;
      PVector3 currentPoint = new PVector3(0.0, 0.0, 0.0);
      PVector3 nextPoint = this.shape.getPoint(i+1);

      // Always take the current (p0) and the next point (p1) and align the vector defined by those points
      // with the x-Axis. Since we apply the transformation calculated in this step to all points 
      // afterwards we can assume, that p1 is always the origin (0,0,0).
      // Therefore first rotate the vector into the XY-Plane. The resulting angle corresponds
      // to the rotatation of the bender head. Then rotate the vector onto the XZ-Plane around the z-Axis.
      // The angle of this rotation corresponds to the actual bend.
      // Signs have to be swapped since the method returns the angle between the plane and the vector and
      // in order to align we have to rotate in the opposite direction.

      debug("=============== i=" + i + " ==============");
      float[] aligmentAngles = getAlignmentAngles(nextPoint);     
      benderRotationAngle = -aligmentAngles[0];

      PVector3 p_ = nextPoint.copy();
      p_.rotX(benderRotationAngle);
      PVector3 xAxis = new PVector3(1.0, 0.0, 0.0);

      bendAngle = angleBetweenTwoVectors(p_, xAxis);
      debug("angle between vectors " + bendAngle);
      float bendDir = directionOfBend(p_, xAxis);
      bendAngle *= bendDir;

      // calc distance between points
      distance = this.distanceBetweenPoints(currentPoint, nextPoint);

      // skip bend and head rotation for the first set of points (2 points are always on a line)
      // skip head rototation for second set of points (3 points are always on one plane)

      // write Instructions, order of actions matters here: 
      // 1. First the x-rotator needs to be brought into position
      // 2. Then the bend (around Z-axis) has to be made
      // 3. Finally the wire can be fed
      if (benderRotationAngle != 0 && i > 1) {
        this.cam.addStep(new RotateHeadInstruction(benderRotationAngle));
      }
      if (bendAngle != 0 && i > 0) {
        this.cam.addStep(new BendWireInstruction(bendAngle));
      }
      if (distance != 0) {
        this.cam.addStep(new FeedInstruction(distance));
      }
      debug("headRotation: " + degrees(benderRotationAngle) + " / bend: " + degrees(bendAngle) + " / distance: " + distance + "\n");

      // finally transform all points in order to get the next point into position
      for (int j = 0; j < shape.getLength(); j++) {
        PVector3 p = shape.getPoint(j);
        p.rotX(benderRotationAngle);
        p.rotZ(bendAngle);        
        p.trans(new PVector3(-distance, 0.0, 0.0));
      }
    }
    this.cam.listSteps();
  }

  public CAM getCam() {
    return cam;
  }

  private float[] getAlignmentAngles(PVector3 p) {
    // BUG: plainNormal is somehow mixed up. 
    // -> in order to rotate into XY-Plane, y-Axis has to be specified as plane normal.
    // -> for rotation into XZ-Plane, z-Axis has to be specified
    float[] angles = new float[2];
    PVector3 xAxis = new PVector3(1, 0, 0);
    PVector3 yAxis = new PVector3(0, 1, 0);
    //PVector3 zAxis = new PVector3(0, 0, 1);

    // rotation into XY-plane
    debug("rotation into XY: ");
    float[] anglesToXY = getAngleToRotateIntoPlane(p, xAxis, yAxis);
    float angleToXY = (abs(anglesToXY[0]) < abs(anglesToXY[1]) ? anglesToXY[0] : anglesToXY[1]);
    String smallerAngle = abs(anglesToXY[0]) < abs(anglesToXY[1]) ? "t1 smaller" : "t2 smaller";
    debug(smallerAngle);
    angles[0] = angleToXY;
    //PVector3 p_ = p.copy();
    //p_.rotX(-angleToXY);

    // rotation into XZ-plane
    //debug("rotation into XZ: ");
    //float[] anglesToXZ = getAngleToRotateIntoPlane(p_, zAxis, xAxis);
    //angles[1] = (abs(anglesToXZ[0]) < abs(anglesToXZ[1]) ? anglesToXZ[0] : anglesToXZ[1]);
    return angles;
  }

  private float distanceBetweenPoints(PVector3 p1, PVector3 p2) {
    return(p1.dist(p2));
  }

  private float[] getAngleToRotateIntoPlane(PVector point, PVector rotationAxis, PVector planeNormal) {
    debug("(with point: " + point + ") ");
    // Use implementation from https://math.stackexchange.com/q/4093224
    // https://github.com/andywiecko/RotateVectorToLieOnPlane/blob/main/Assets/TestScript.cs    
    PVector r = rotationAxis.copy().normalize();
    PVector n = planeNormal.copy().normalize();
    PVector v = point.copy().normalize();

    float A = v.dot(n);
    float B = (r.cross(v)).dot(n);
    float C = (v.dot(r)) * (n.dot(r));
    // debug("A: " + A + " B: " + B + " C: " + C);

    float x_num1 = C*(C-A);
    float x_num2 = sqrt(pow(B, 2)*(pow((A-C), 2) + pow(B, 2) - pow(C, 2)));  
    float x_denom = pow((A-C), 2) + pow(B, 2);
    float x1 = (x_num1 + x_num2) / x_denom;
    float x2 = (x_num1 - x_num2) / x_denom;
    // debug("x1: " + x1 + " x2: " + x2);

    float y_num1 = (C-A) * x1 - C;
    float y_num2 = (C-A) * x2 - C;
    float y1 = y_num1 / B;
    float y2 = y_num2 / B;
    // debug("y1: " + y1 + " y2: " + y2);

    float theta1 = atan2(x1, y1);
    float theta2 = atan2(x2, y2);
    // debug("t1: " + degrees(theta1) + " t2: " + degrees(theta2));
    debug("t1: " + theta1 + " t2: " + theta2);

    // check if theta-values a NaN (case if point already in plane)
    if (Float.isNaN(theta1) && Float.isNaN(theta2)) {
      float[] angles = {0.0, 0.0};
      return angles;
    } else {
      float[] angles = {theta1, theta2};
      return angles;
    }
  }

  private float angleBetweenTwoVectors(PVector3 v1, PVector3 v2) {
    return (float) Math.atan2(v1.cross(v2).mag(), v1.dot(v2));
  }

  private float directionOfBend(PVector3 v1, PVector3 v2) {
    PVector3 zAxis = new PVector3(0.0, 0.0, 1.0);
    PVector3 angleDir = v1.cross(v2);
    debug("calc dir of bend with v1: " + v1 + " v2: " + v2);
    debug("direction of bend: " + Math.signum(angleDir.dot(zAxis)));
    return Math.signum(angleDir.dot(zAxis));
  }
}
