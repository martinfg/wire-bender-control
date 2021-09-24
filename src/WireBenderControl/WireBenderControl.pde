import g4p_controls.*;
import processing.serial.*;
import controlP5.*;
import java.util.Arrays;
import java.util.Collections;
import peasy.*;

ControlP5 cp5;
GUI gui;
Communicator comm;

ArrayList<PShape> assets;

void settings() {
  size(800, 490, P3D);
}

void setup() 
{  
  // setup view frustrum
  float fov = PI/3.0;
  float cameraZ = (height/2.0) / tan(fov/2.0);
  perspective(fov, float(width)/float(height), 
              cameraZ/10.0, cameraZ*10.0);

  // load assets
  println(dataPath(""));
  PShape nozzleObj = loadShape("nozzle.obj");
  assets = new ArrayList<PShape>();
  assets.add(nozzleObj);

  // set window title
  surface.setTitle("WireBenderControlV0.1");

  comm = new Communicator(this, 115200, "defaultPort");
  cp5 = new ControlP5(this);
  cp5.setAutoDraw(false);
  gui = new GUI(this, cp5, comm, 45);
}

void serialEvent(Serial p) { 
  comm.serialEventTrigger(p);
} 

void controlEvent(ControlEvent ce) {
  gui.controlEventTrigger(ce);
}

void fileSelected(File selection) {
  gui.onFileSelected(selection);
}


void draw() {
  background(82);
  gui.show();
  comm.update(); 
}
