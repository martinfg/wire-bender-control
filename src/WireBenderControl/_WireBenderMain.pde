import peasy.*;
import java.util.*;

ArrayList<PVector> points = new ArrayList<PVector>();
PeasyCam cam;
float axisLen = 15.0;
float axisAlpha = 150;
Shape shape;
PathGenerator pathGen;
Processor processor;
Simulation simu;
Maschine maschine;
boolean showTargetShape = true;
boolean showAxis = true;
float simuSpeed = 1.0;

//DEBUG
PVector3 pv = new PVector3(10.0, 0.0, 0.0);
float bendRadius = 0.1;
float angle = 0.0;
int currentCalcStep = 0;

public void setup() {  
  size(1024, 768, P3D);
  cam = new PeasyCam(this, 250);
  cam.setMinimumDistance(0);
  cam.setMaximumDistance(500);

  PShape maschineModel = loadShape("nozzle.obj");
  maschine = new Maschine(maschineModel);

  pathGen = new PathGenerator();
  //processor = new Processor(new Shape(pathGen.getSimpleShape(6)));
  processor = new Processor(new Shape(pathGen.getPerlinShape(10, 1000)));
  shape = processor.preprocessShape();
  println(shape);
  processor.calcCAM();
  simu = new Simulation(
    processor.getCam(), 
    color(255, 200), 
    color(255, 100, 100, 200), 
    simuSpeed, 
    true);
  simu.simulateResult();

  //PVector3 xAxis = new PVector3(1, 0, 0);
  //PVector3 point = new PVector3(1, 1, 0);
  //float dir = processor.directionOfBend(point, xAxis);
  //print(dir);

  //noLoop();
}

void keyPressed() {
  if (key == 'n') {
    currentCalcStep ++;
  }
  if (key == 'b') {
    currentCalcStep --;
  }
  if (key == 'r') {
    processor = new Processor(new Shape(pathGen.getRandomShape(10)));
    shape = processor.preprocessShape();
    processor.calcCAM();
    simu = new Simulation(
      processor.getCam(), 
      color(255, 200), 
      color(255, 100, 100, 200), 
      simuSpeed, 
      true);
    simu.simulateResult();
  }
  if (key == 't') {
    processor = new Processor(new Shape(pathGen.getPerlinShape(10, 1000)));
    shape = processor.preprocessShape();
    processor.calcCAM();
    simu = new Simulation(
      processor.getCam(), 
      color(255, 200), 
      color(255, 100, 100, 200), 
      simuSpeed, 
      true);
    simu.simulateResult();
  }

  if (key == 'a') {
    showAxis = !showAxis;
  }
  if (key == CODED) {
    if (keyCode == RIGHT) {
      simu.nextStep();
    } 
    if (keyCode == DOWN) {
      simu.initSimuation();
    }
    if (keyCode == UP) {
      showTargetShape = !showTargetShape;
    }
  }
}

public void draw() {
  background(52);

  //_debugVectorAlignment();

  // axis
  if (showAxis) showAxis();

  // show Maschine
  maschine.show();

  if (showTargetShape) {
    shape.show(color(200, 255, 100, 150), color(255, 50), false);
  }

  simu.show();
  // simu.nextStep();  

  // show calc Steps
  //int step = currentCalcStep % processor.calcSteps.size();
  //Shape s = processor.calcSteps.get(step);
  //s.show(color(255), color(255), false);
}

void showAxis() {
  //X-Axis
  stroke(255, 0, 0, axisAlpha);
  line(0, 0, 0, axisLen, 0, 0);
  //Y-Axis
  stroke(0, 255, 0, axisAlpha);
  line(0, 0, 0, 0, axisLen, 0);
  //Z-Axis
  stroke(0, 0, 255, axisAlpha);
  line(0, 0, 0, 0, 0, axisLen);
}


void _debugVectorAlignment() {
  PVector3 xAxis = new PVector3(1.0, 0.0, 0.0);
  PVector3 yAxis = new PVector3(0.0, 1.0, 0.0);
  PVector3 zAxis = new PVector3(0.0, 0.0, 1.0);
  //PVector3 v = new PVector3(10.0, 10.0, 10.0);
  //v.rotY(-0.5*angle);
  //v.rotZ(angle);
  //angle += 0.01;
  PVector3 v = new PVector3(random(-100, 100), random(-100, 100), random(-100, 100));

  //PVector3 v_ = v.copy();
  //float angleToXY = processor.getAngleToRotateIntoPlane(v, xAxis, yAxis);
  //v_.rotX(-angleToXY);
  //float angleToXZ = processor.getAngleToRotateIntoPlane(v_, zAxis, xAxis);
  //// v_.rotZ(-angleToXZ);

  //v.rotX(-angleToXY);
  //v.rotZ(-angleToXZ);

  _showVector(v, color(255, 0, 0));
  // _showVector(v_, color(0, 255, 0));

  // println("angle: " + angleToXY + " v: " + v  " v_: " + v_);
}

void _showVector(PVector3 p, color c) {
  // Debugging 
  noStroke();
  fill(c);
  pushMatrix();
  translate(p.x, p.y, p.z); 
  sphere(1);
  popMatrix();
  strokeWeight(1);
  stroke(255);
  line(0, 0, 0, p.x, p.y, p.z);
}
