public class Simulation {
  CAM cam;
  Shape simuShape; 
  boolean debug;
  color dotColor, pathColor;
  float simuSpeed;
  int currentCamStep;
  float currentSimuStep;
  Instruction currentInstruction; 
  PVector3 origin;

  public Simulation(CAM cam, color dotColor, color pathColor, float speed, boolean debug) {
    this.cam = cam;
    this.dotColor = dotColor;
    this.pathColor = pathColor;
    this.simuSpeed = speed;
    this.debug = debug;
    this.origin = new PVector3(0.0, 0.0, 0.0);
    this.initSimuation();
  }

  public void initSimuation() {
    currentCamStep = 0;
    currentSimuStep = 0;
    simuShape = new Shape();
    simuShape.addPoint(origin.copy()); // init first point
    currentInstruction = cam.getStep(currentCamStep);
    currentCamStep ++;
    if (debug) {
      println("\n->->->->->->->->->->->");
      println("Starting simulation");
      println("<-<-<-<-<-<-<-<-<-<-<-");
      println(currentInstruction.toString());
    }
  }

  // TODO: Properly implement stepwise bending simulation
  //public void nextStep() {
  //  if (currentInstruction == null) return;
  //  //println("ATTRIBUTE :" + currentInstruction.getAttribute());
  //  if (currentSimuStep < currentInstruction.getAttribute()) {     
  //    // avoid overflow if target % simuSpeed is not 0
  //    if (currentSimuStep + simuSpeed > currentInstruction.getAttribute()) {
  //      float remainder = currentInstruction.getAttribute() - currentSimuStep;
  //      currentInstruction.transformStepwise(simuShape, remainder);
  //      currentSimuStep = currentInstruction.getAttribute();
  //    } else {
  //      currentInstruction.transformStepwise(simuShape, simuSpeed);
  //      currentSimuStep += simuSpeed;
  //    }
  //    //println("current step: " + currentSimuStep + "/" + currentInstruction.getAttribute());
  //  } else {
  //    currentInstruction = cam.getStep(currentCamStep);
  //    if (currentInstruction == null) {
  //      if (debug) {
  //        println("Simulation complete");
  //      }
  //      return;
  //    } else {
  //      if (debug) {
  //        println(currentInstruction.toString());
  //      }
  //    }
  //    // add a new point at origin every step
  //    simuShape.addPoint(origin.copy());
  //    currentSimuStep = 0.0;
  //    currentCamStep ++;
  //    nextStep();
  //  }
  //}

  public void simulateResult() {
    if (currentInstruction == null) return;
    currentInstruction.transform(simuShape);
    currentInstruction = cam.getStep(currentCamStep);
    if (currentInstruction == null) {
        if (debug) {
          println("Simulation complete");
        }
      return;
    } else {
      if (debug) {
        println(currentInstruction.toString());
      }
    }
    // add a new point at origin every step
    simuShape.addPoint(origin.copy());
    currentCamStep ++;
    simulateResult();
  }

  public void show(PGraphics pg) {
    simuShape.show(pg, dotColor, pathColor, true);
  }
}
