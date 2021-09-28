import uibooster.*;
import uibooster.components.*;
import uibooster.model.*;
import uibooster.model.formelements.*;
import uibooster.model.options.*;
import uibooster.utils.*;

import g4p_controls.*;
import processing.serial.*;
import controlP5.*;
import java.util.Arrays;
import java.util.Collections;
import peasy.*;

ControlP5 cp5;
GUI gui;
Communicator comm;

public static String DEFAULT_PORT;
public static int FEEDING_CONSTANT ;
public static int OFFSET_FOR_NEG_BEND ;
public static int Z_ANGLE_CONSTANT;
public static int NEG_BEND_ANGLE_CONSTANT;
public static int BEND_ANGLE_CONSTANT;

public static boolean DEBUG = false;
public static boolean DEBUG_SERIAL = false;

ArrayList<PShape> assets;
JSONObject config;

public final void parseConfig() {
  try {
    config = loadJSONObject("config.json");
    DEFAULT_PORT = config.getString("DEFAULT_PORT");
    FEEDING_CONSTANT = config.getInt("FEEDING_CONSTANT");
    Z_ANGLE_CONSTANT = config.getInt("Z_ANGLE_CONSTANT");
    OFFSET_FOR_NEG_BEND = config.getInt("OFFSET_FOR_NEG_BEND");
    BEND_ANGLE_CONSTANT = config.getInt("BEND_ANGLE_CONSTANT");
    NEG_BEND_ANGLE_CONSTANT = config.getInt("NEG_BEND_ANGLE_CONSTANT");
} 
  catch(NullPointerException e) {
    new UiBooster().showInfoDialog("Error: Could not find config.json in /data directory");
    exit();
  }
  catch(RuntimeException e) {
    new UiBooster().showInfoDialog("Error while parsing config.json:" + "\n" + e);
    exit();
  }
}

public static void debug(String msg) {
  if (DEBUG) println(msg);
}

public static void debugSerial(String msg) {
  if (DEBUG_SERIAL) println(msg);  
}

void settings() {
  size(800, 490, P3D);
}

void setup() 
{  
  // load & parse config
  parseConfig();

  // load assets
  PShape nozzleObj = loadShape("assets/nozzle.obj");
  assets = new ArrayList<PShape>();
  assets.add(nozzleObj);

  // setup view frustrum
  float fov = PI/3.0;
  float cameraZ = (height/2.0) / tan(fov/2.0);
  perspective(fov, float(width)/float(height), 
    cameraZ/10.0, cameraZ*10.0);

  // set window title
  surface.setTitle("WireBenderControlV0.2");

  comm = new Communicator(this, 115200);
  cp5 = new ControlP5(this);
  cp5.setAutoDraw(false);
  gui = new GUI(this, cp5, comm, 45);
}

void serialEvent(Serial p) { 
  comm.serialEventTrigger(p);
} 

void controlEvent(ControlEvent ce) {
  if (gui != null) {
    gui.controlEventTrigger(ce);
  }
}

void fileSelected(File selection) {
  gui.onFileSelected(selection);
}


void draw() {
  background(82);
  gui.show();
  comm.update();
}
