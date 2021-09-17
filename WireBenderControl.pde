import processing.serial.*;
import controlP5.*;
import java.util.Arrays;
import java.util.Collections;

int BAUD_RATE = 115200;
Serial myPort;
String selectedPort;
char serialIn;
boolean connectionIsLocked = false;
int connectionStatus = 0; //0: not connected, 1: connected to port, 2: establishing connection to bender, 3: connected to bender, 4: time out, 5: connection lost, 6: port not found
String statusText = "status: not connected";
int startOfConnectionAttempt; // needed to track timeout when connecting
int delayAfterPortConnected = 2000;
int connectionEstablishTimeout = 1500;
int isAliveTimeout = 15000;
int lastSignOfLife;
String defaultPort = "/dev/ttyUSB1";
int checkConnectionInterval = 1000;
int lastMillis;
boolean homed = false;
int[] angleRangeBender = {-45, 45};
int[] angleRangeZAxis = {-90, 90};
Shape currentSelectedShape;

ControlP5 cp5;
int conH = 35;
Group groupManController;
Button moveBenderPlus;
Button moveBenderMinus;
Button bendPinToggle;
Button feedPlus;
Button feedMinus;
Button rotateZPlus;
Button rotateZMinus;
Button connect;
Button testConnection;
Slider benderRadius;
Slider feedDist;
Slider zAxisRadius;
ScrollableList portsList;
Textlabel statusField;
StatusLed statusLed;
Button buttonSetHome; 
Button buttonBendDegrees;
Slider sliderBendDegrees;
Button btnLoadFile;
Textlabel tlCurrentFile;

void setup() 
{
  size(325, 390);


  cp5 = new ControlP5(this);
  int xFirst = 20;
  int xScnd = xFirst + conH*2 + 5;
  int xThird = xScnd + conH*2 + 5;
  int rowY = 20;

  groupManController = cp5.addGroup("manController");

  // LOAD AND RENDER
  newHeader("LOAD FILE", xFirst, rowY);
  rowY += 15;
  btnLoadFile = newButton("load", xFirst, rowY, conH*2, conH/2);
  tlCurrentFile = cp5.addTextlabel("currentFile", "no file loaded", xScnd, rowY+4);

  // MANUAL CONTROLS
  rowY += conH + 5;
  newHeader("MANUAL CONTROLS", xFirst, rowY);
  rowY += 15;
  moveBenderMinus = newButton("Bender -", xFirst, rowY, conH*2, conH).setGroup(groupManController);
  moveBenderPlus = newButton("Bender +", xScnd, rowY, conH*2, conH).setGroup(groupManController);
  benderRadius = newSlider("bender steps", xThird, rowY, conH*2, conH, 0, angleRangeBender[1], 5);

  rowY += conH + 5;
  feedMinus = newButton("Feed -", xFirst, rowY, conH*2, conH).setGroup(groupManController);
  feedPlus = newButton("Feed +", xScnd, rowY, conH*2, conH).setGroup(groupManController);
  feedDist = newSlider("feeder steps", xThird, rowY, conH*2, conH, 0, 100, 5);

  rowY += conH + 5;
  rotateZMinus = newButton("zAxis -", xFirst, rowY, conH*2, conH).setGroup(groupManController);
  rotateZPlus = newButton("zAxis +", xScnd, rowY, conH*2, conH).setGroup(groupManController);
  zAxisRadius = newSlider("z-axis steps", xThird, rowY, conH*2, conH, 0, angleRangeZAxis[1], 5);

  rowY += conH + 5;
  bendPinToggle = newButton("BendPin", xFirst, rowY, conH*2, conH);
  buttonSetHome = newButton("Home", xScnd, rowY, conH*2, conH)
    .setColorBackground(color(255, 200, 0));

  rowY += conH + 10;
  buttonBendDegrees = newButton("bend", xFirst, rowY, conH*2, conH)
    .setColorBackground(color(255, 153, 235));
  sliderBendDegrees = newSlider("radius", xScnd, rowY, conH*2, conH, angleRangeBender[0], angleRangeBender[1], 0)
    .setNumberOfTickMarks(5)
    .snapToTickMarks(false);
  // cp5.addTextlabel("homeInfo", "test\ntest\ntestast", 200, rowY);

  // CONNECTION OPTIONS
  rowY += conH + 25;
  newHeader("CONNECTION", xFirst, rowY);
  rowY += 15;
  portsList = cp5.addScrollableList("serial ports")
    .setPosition(xFirst, rowY)
    .setSize(conH*4+5, 60)
    .setBarHeight(conH/2)
    .setItemHeight(conH/2)
    .setType(ControlP5.DROPDOWN)
    .addItems(Serial.list())
    .setOpen(false);
  if (Arrays.asList(Serial.list()).contains(defaultPort)) {
    println("default port found in ports list");
    portsList.setValue(Arrays.asList(Serial.list()).indexOf(defaultPort));
  }
  connect = newButton("connect", xThird, rowY, conH*2, conH/2);
  //testConnection = newButton("test", xThird, rowY, conH*2, conH/2);

  rowY += conH - 5;
  int ledRadius = 5;
  statusLed = new StatusLed(xFirst+ledRadius, rowY+ledRadius, ledRadius);
  statusField = cp5.addTextlabel("status", statusText, int(xFirst*1.5), rowY);

  // init connection lost counter
  lastMillis = millis();
}

void draw() {
  background(102);
  statusLed.show();

  if (connectionStatus == 3) {
    if (millis() - lastMillis > checkConnectionInterval) {
      sendCommand(Order.ISALIVE.getValue());
      lastMillis = millis();
    }
    if (millis() - lastSignOfLife > isAliveTimeout) {
      connectionStatus = 5;
      statusLed.updateStatus(connectionStatus);
      statusField.setText("status: connection to bender lost!");
    }
  }
}

void connectToPort(String portName) {
  try {
    myPort = new Serial(this, portName, BAUD_RATE);
    connectionStatus = 1;
    delay(delayAfterPortConnected);
    connectionStatus = 2;
    myPort.write(byte(Order.HELLO.getValue())); // do not use sendCommandMethod here (does not work without active connection)
    startOfConnectionAttempt = millis();
    while (true) {
      if (millis() - startOfConnectionAttempt >= connectionEstablishTimeout) {
        connectionStatus = 4;
        delay(200);
        throw new Exception ("Connection timed Out");
      }
      if (connectionStatus == 3) {
        println("connection established");
        statusField.setText("status: connected to bender!");
        statusLed.updateStatus(connectionStatus);
        lastSignOfLife = millis();
        connect.setLabel("disconnect");
        break;
      }
    }
  } 
  catch(RuntimeException e) {
    println("Port not found");
    println(e);
    try {
      myPort.stop();
    } 
    catch (Exception _e) {
    }
    finally {
      myPort = null;
      connectionStatus = 6;
      statusField.setText("status: port not found!");
      statusLed.updateStatus(connectionStatus);
    }
  }
  catch(Exception e) {
    println("connection Timed out");
    try {
      myPort.stop();
    } 
    catch (Exception _e) {
    }
    finally {
      myPort = null;
      connectionStatus = 4;
      statusField.setText("status: connection time out!");
      statusLed.updateStatus(connectionStatus);
    }
  }
}

void disconnect() {
  try {
    myPort.stop();
  } 
  catch (Exception e) {
    println(e);
  }
  finally {
    myPort = null;
    connectionStatus = 0;
    statusField.setText("status: not connected");
    statusLed.updateStatus(connectionStatus);
    connect.setLabel("connect");
    setHomed(false);
  }
}

Button newButton (String label, int posX, int posY, int w, int h) {
  Button button = cp5.addButton(label)
    .setPosition(posX, posY)
    .setSize(w, h);
  return button;
}

Slider newSlider (String label, int posX, int posY, int w, int h, int min, int max, int value) {
  Slider slider = cp5.addSlider(label)
    .setPosition(posX, posY)
    .setSize(w, h)
    .setRange(min, max)
    .setValue(value);
  return slider;
}

Textlabel newHeader(String text, int x, int y) {
  String name = text;
  text = "" + text + "";
  Textlabel tl = cp5.addTextlabel(name, text, x, y); 
  return tl;
}

void setHomed(boolean status) {
  if (status) {
    homed = true;
    println("home position set");
    buttonSetHome.setColorBackground(color(0, 255, 0));
  } else {
    homed = false;
    println("lost home position");
    buttonSetHome.setColorBackground(color(255, 100, 0));
    sendCommand(Order.DELHOMED.getValue()); // ATTENTION: THIS COMMAND WILL CURRENTLY NOT GET THROUGH BECAUSE OF LOCKED CONNECTION, SO BENDER WONT KNOW WE LOST HOME POSITION.
  }
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    String filePath = selection.getAbsolutePath();
    try {
      Table table = loadTable(filePath, "header");
      PathGenerator pg = new PathGenerator();
      ArrayList<PVector3> pointList = pg.shapeFromCSV(table);
      if (pointList == null) {
        println("Error: file could not be parsed");
      } else {
        Shape shape = new Shape(pg.shapeFromCSV(table));    
        println(shape.toString());
        currentSelectedShape = shape;
        tlCurrentFile.setText("current file: " + selection.getName());
      }
    } 
    catch (java.lang.IllegalArgumentException e) {
      // println(e);
      println("Error: not a valid .csv-file");
    }
  }
}

void controlEvent(ControlEvent theEvent) {
  float value = theEvent.getValue();
  Controller con = theEvent.getController();
  if (con == btnLoadFile) {
    selectInput("Select .csv file:", "fileSelected");
  } else if (con == moveBenderPlus) {
    sendCommand(Order.BENDER.getValue(), (int) benderRadius.getValue());
    if (homed) setHomed(false);
  } else if (con == moveBenderMinus) {
    sendCommand(Order.BENDER.getValue(), (int) -benderRadius.getValue());
    if (homed) setHomed(false);
  } else if (con == bendPinToggle) {
    sendCommand(Order.PIN.getValue());
  } else if (con == feedMinus) {
    sendCommand(Order.FEEDER.getValue(), (int) -feedDist.getValue());
  } else if (con == feedPlus) {
    sendCommand(Order.FEEDER.getValue(), (int) feedDist.getValue());
  } else if (con == rotateZMinus) {
    sendCommand(Order.ZAXIS.getValue(), (int) -zAxisRadius.getValue());
  } else if (con == rotateZPlus) {
    sendCommand(Order.ZAXIS.getValue(), (int) zAxisRadius.getValue());
  } else if (con == buttonSetHome) {
    sendCommand(Order.SETHOMED.getValue());
  } else if (con == buttonBendDegrees) {
    if (homed) {
      println("beding: " + (int) sliderBendDegrees.getValue() + " degrees");
      sendCommand(Order.BEND.getValue(), (int) sliderBendDegrees.getValue());
    }
  } else if (con == connect) {
    if (connectionStatus != 3) {
      connectToPort(portsList.getCaptionLabel().getText());
    } else {
      disconnect();
    }
  }
}

void sendCommand(int cmd) {
  if (!connectionIsLocked && connectionStatus == 3) {
    //if (connectionStatus == 3) {
    connectionIsLocked = true;
    //println("sending command: " + cmd);
    myPort.write(byte(cmd));
    delay(100);
  }
}

void sendCommand(int cmd, int value) {
  if (!connectionIsLocked && connectionStatus == 3) {
    //if (connectionStatus == 3) {
    connectionIsLocked = true;
    //println("sending command: " + cmd + " with value: " + value);
    myPort.write(byte(cmd));
    myPort.write(byte(value));
    delay(100);
  }
}

void serialEvent(Serial p) { 
  serialIn = p.readChar(); 
  //println("received data: " + byte(serialIn));
  if (serialIn == Order.RECEIVED.getValue()) {
    // println("confirmation received");
    connectionIsLocked = false;
  } else if (serialIn == Order.HELLO.getValue()) {
    connectionStatus = 3;
  } else if (serialIn == Order.ISALIVE.getValue()) {
    lastSignOfLife = millis();
    //println("isAlive");
  } else if (serialIn == Order.ISHOMED.getValue()) {
    setHomed(true);
  }
} 

class StatusLed {
  int x;
  int y;
  int status;
  int radius;

  StatusLed(int x, int y, int radius) {
    this.x = x;
    this.y = y;
    this.radius = radius;
    this.status = 0;
  }
  void updateStatus (int status) {
    this.status = status;
  }
  void show () {  
    if (status == 0) { // not connected
      fill(255, 255, 0);
    } else if (status == 3) { // connected
      fill(0, 255, 0);
    } else if (status == 4) { // time out
      fill(252, 127, 3);
    } else if (status == 5) { // connection lost
      fill(255, 0, 0);
    } else if (status == 6) { // port not found
      fill(255, 0, 0);
    } 
    noStroke();
    circle(x, y, radius*2);
  }
}
