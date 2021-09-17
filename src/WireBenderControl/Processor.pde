public class Processor {
  Shape shape;
  CAM cam;
  ArrayList<Shape> calcSteps;

  public Processor(Shape shape) {
    this.shape = shape.copy();
  }

  public Processor() {
  }

  public void setShape(Shape shape) {
    this.shape = shape.copy();
  }

  public Shape preprocessShape() {
    // reverse Point list
    shape.reverseOrder();  

    // normazile points by 0-centering
    shape.zeroCenter(shape.getPoint(0)); 

    // rotate Shape, to that first two points a connected by a line aligned with the x-axis
    // after zeroCentering we can assume that the first point of the shape is equal to the origin
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

      // Always take the current (p0) and the next point (p1) and align the vector definded by those point
      // with the x-Axis. Since we apply the transformation calculated in this step to all points after
      // afterwards, we can assume, that p1 is always the origin (0,0,0).
      // Therefore first rotate the angle into the XY-Plane. The angle corresponds
      // to the rotatation of the bender head. Then rotate the vector on the XY-Plane around the z-Axis.
      // To angle of this rotation corresponds to the actual bend.
      // signs have to be swapped since the method returns the angle between the plane and the vector.
      // in order to align we have to rotate in the opposite direction
      //println(" =============== i=" + i + " ==============");
      //println(shape);
      float[] aligmentAngles = getAlignmentAngles(nextPoint);     
      benderRotationAngle = -aligmentAngles[0];
      benderRotationAngle = radians(round(degrees(benderRotationAngle)));
      //bendAngle = -aligmentAngles[1];
      //bendAngle = radians(round(degrees(bendAngle)));

      // calc angle between points vector and x Axis
      // and the direction of the bend
      PVector3 xAxis = new PVector3(1.0, 0.0, 0.0);
      //PVector3 point = nextPoint.copy();
      //point.normalize();
      bendAngle = angleBetweenTwoVectors(nextPoint, xAxis);
      float bendDir = directionOfBend(nextPoint, xAxis);
      bendAngle *= bendDir;
      // println("next Point " + nextPoint + " bendDir " + bendDir + " angle " + degrees(_bendAngle));

      // calc distance between points
      distance = this.distanceBetweenPoints(currentPoint, nextPoint);

      // skip bends for the first set of points!

      // write Instructions, order of actions matters here: 
      // 1. First the X-Rotater needs to be brought into position
      // 2. Then the bend (around Z-axis) has to be made
      // 3. Finally the wire can be fed
      if (benderRotationAngle != 0) {
        if (i != 0) {
          this.cam.addStep(new RotateHeadInstruction(benderRotationAngle));
        }
      }
      if (bendAngle != 0) {
        if (i != 0) {
          this.cam.addStep(new BendWireInstruction(bendAngle));
        }
      }
      if (distance != 0) {
        this.cam.addStep(new FeedInstruction(distance));
      }
      //println("distance: " + distance + " / headRotation: " + degrees(benderRotationAngle) + " / bend: " + degrees(bendAngle) + "\n");

      // finally transform all points in order to get the next point into position

      //for (int j = 0; j < shape.getLength(); j++) {
      //  PVector3 p = shape.getPoint(j);
      //  p.rotX(benderRotationAngle);
      //  p.rotZ(bendAngle);        
      //  p.trans(new PVector3(-distance, 0.0, 0.0));
      //}

      // ======== DO IT STEPWISE FOR DEBUGGIN AND VISUALIZATION PURPOSES =============
      calcSteps.add(shape.copy());
      for (int j = 0; j < shape.getLength(); j++) {
        PVector3 p = shape.getPoint(j);
        p.rotX(benderRotationAngle);
      }
      calcSteps.add(shape.copy());
      for (int j = 0; j < shape.getLength(); j++) {
        PVector3 p = shape.getPoint(j);
        p.rotZ(bendAngle);
      }
      calcSteps.add(shape.copy());
      for (int j = 0; j < shape.getLength(); j++) {
        PVector3 p = shape.getPoint(j);
        p.trans(new PVector3(-distance, 0.0, 0.0));
      }
      // ======== DO IT STEPWISE FOR DEBUGGIN AND VISUALIZATION PURPOSES =============
    }
    this.cam.listSteps();
  }

  public CAM getCam() {
    return cam;
  }

  private float[] getAlignmentAngles(PVector3 p) {
    float[] angles = new float[2];
    PVector3 xAxis = new PVector3(1, 0, 0);
    PVector3 yAxis = new PVector3(0, 1, 0);
    PVector3 zAxis = new PVector3(0, 0, 1);

    PVector3 p_ = p.copy();
    float[] anglesToXY = getAngleToRotateIntoPlane(p, xAxis, yAxis);
    float angleToXY = (abs(anglesToXY[0]) < abs(anglesToXY[1]) ? anglesToXY[0] : anglesToXY[1]);
    p_.rotX(-angleToXY);
    angles[0] = angleToXY;
    float[] anglesToXZ = getAngleToRotateIntoPlane(p_, zAxis, xAxis);
    angles[1] = (abs(anglesToXZ[0]) < abs(anglesToXZ[1]) ? anglesToXZ[0] : anglesToXZ[1]);
    return angles;
  }

  private float distanceBetweenPoints(PVector3 p1, PVector3 p2) {
    return(p1.dist(p2));
  }

  private float[] getAngleToRotateIntoPlane(PVector point, PVector rotationAxis, PVector plainNormal) {
    // BUG: plainNormal is somehow mixed up. 
    // -> in order to rotate into XY-Plane, y-Axis has to be specified as plane normal.
    // -> for rotation into XZ-Plane, z-Axis has to be specified

    // Use implementation from https://math.stackexchange.com/q/4093224
    // https://github.com/andywiecko/RotateVectorToLieOnPlane/blob/main/Assets/TestScript.cs    
    PVector r = rotationAxis.copy().normalize();
    PVector n = plainNormal.copy().normalize();
    PVector v = point.copy().normalize();

    float A = v.dot(n);
    float B = (r.cross(v)).dot(n);
    float C = (v.dot(r)) * (n.dot(r));
    // println("A: " + A + " B: " + B + " C: " + C);

    float x_num1 = C*(C-A);
    float x_num2 = sqrt(pow(B, 2)*(pow((A-C), 2) + pow(B, 2) - pow(C, 2)));  
    float x_denom = pow((A-C), 2) + pow(B, 2);
    float x1 = (x_num1 + x_num2) / x_denom;
    float x2 = (x_num1 - x_num2) / x_denom;
    // println("x1: " + x1 + " x2: " + x2);

    float y_num1 = (C-A) * x1 - C;
    float y_num2 = (C-A) * x2 - C;
    float y1 = y_num1 / B;
    float y2 = y_num2 / B;
    // println("y1: " + y1 + " y2: " + y2);

    float theta1 = atan2(x1, y1);
    float theta2 = atan2(x2, y2);
    println("t1: " + degrees(theta1) + " t2: " + degrees(theta2));

    // check if theta-values a NaN (case if point already in plane)
    // return 0.0 if thats the case otherweise return the smaller of the two angles
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
    PVector3 dir = new PVector3(0.0, 0.0, 1.0);
    PVector3 angleDir = v1.cross(v2);
    println(angleDir);
    println(dir);
    return Math.signum(angleDir.dot(dir));
  }

  //private float angleBetweenPlanes(PVector3 p1, PVector3 p2, PVector3 p3, PVector3 p4) {
  //  PVector3 firstPlaneNormal = this.planeNormalByPoints(p1, p2, p3);
  //  PVector3 secndPlaneNormal = this.planeNormalByPoints(p2, p3, p4);
  //  println("first plane normal / second plane normal: " + firstPlaneNormal + " " + secndPlaneNormal);
  //  float angleBetweenPlanes = PVector3.angleBetween(firstPlaneNormal, secndPlaneNormal);
  //  //print("the angle between the planes is: " + degrees(angleBetweenPlanes) + "°");
  //  return angleBetweenPlanes;
  //}

  //private PVector3 planeNormalByPoints(PVector3 p1, PVector3 p2, PVector3 p3) {
  //  // get two different vectors defining the plane
  //  PVector3 v1 = p2.sub(p1);
  //  PVector3 v2 = p3.sub(p1);
  //  // calc cross product to obtain normal vector of plane
  //  PVector3 normal = (PVector3) v1.cross(v2);
  //  println("the two vectors defining the plane and their cross product: " + v1 + " " + v2 + " " + normal);
  //  // normalize the vector
  //  normal.normalize();
  //  // return result (normalized)
  //  return normal;
  //}
}
