public class Instruction {
  float distance;
  public String toString() {
    return "";
  }
  public void transform(Shape shape) {
  }
  public void transformStepwise(Shape shape, float step) {
  }
  public float getAttribute() {
    return distance;
  }
}

public class RotationInstruction extends Instruction {
  float angle;
  public float getAngle() {
    return angle;
  }
  @Override
    public float getAttribute() {
    return degrees(angle);
  }
}

public class FeedInstruction extends Instruction {
  public FeedInstruction(float distance) {
    this.distance = distance;
  }
  public String toString() {
    super.toString();
    return ("FEED wire:   " + this.distance  + "mm");
  }
  public void transform(Shape shape) {
    super.transform(shape);
    shape.trans(new PVector3(distance, 0.0, 0.0));
  }
  public void transformStepwise(Shape shape, float step) {
    super.transform(shape);
    shape.trans(new PVector3(step, 0.0, 0.0));
  }
}

public class RotateHeadInstruction extends RotationInstruction {
  public RotateHeadInstruction(float angle) {
    this.angle = angle;
  }
  public String toString() {
    super.toString();
    return ("ROTATE head: " + degrees(this.angle)  + "°");
  }
  public void transform(Shape shape) {
    super.transform(shape);
    shape.rotX(angle);
  }
  public void transformStepwise(Shape shape, float step) {
    super.transform(shape);
    //shape.rotX(radians(step));
    shape.rotX(step);
  }
}

public class BendWireInstruction extends RotationInstruction {
  public BendWireInstruction(float angle) {
    this.angle = angle;
  }
  public String toString() {
    super.toString();
    return ("BEND wire    " + degrees(this.angle)  + "°");
  }
  public void transform(Shape shape) {
    super.transform(shape);
    shape.rotZ(angle);
  }
  public void transformStepwise(Shape shape, float step) {
    super.transform(shape);
    // shape.rotZ(radians(step));
    shape.rotZ(step);
  }
}

//public class RotateYInstruction extends RotationInstruction {
//  public RotateYInstruction(float angle) {
//    this.angle = angle;
//  }
//  public String toString() {
//    super.toString();
//    return ("ROTATE Y:  " + degrees(this.angle)  + "°");
//  }
//  public void transform(Shape shape) {
//    super.transform(shape);
//    shape.rotY(angle);
//  }
//  public void transformStepwise(Shape shape, float step) {
//    super.transform(shape);
//    shape.rotY(radians(step));
//  }
//}
