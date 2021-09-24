class GUI {
  PApplet parent;
  Communicator comm;
  ControlP5 cp5;

  Button btnMoveBenderPlus;
  Button btnMoveBenderMinus;
  Button btnBendPinToggle;
  Button btnFeedPlus;
  Button btnFeedMinus;
  Button btnRotateZPlus;
  Button btnRotateZMinus;
  Button btnConnect;
  Button btnSetHome; 
  Button btnBendDegrees;
  Button btnSendToBender;
  Button btnSimulate;
  Button btnLoadFile;

  Slider sldrBenderRadius;
  Slider sldrFeedDist;
  Slider sldrZAxisRadius;
  Slider sldrBendDegrees;

  ScrollableList scrListPortsList;

  Textlabel tlStatusField;
  Textlabel tlCurrentFile;

  StatusLed statusLed;
  AnimationView animationView;

  int buttonHeight;
  int[] angleRangeBender = {-90, 90};
  int[] angleRangeZAxis = {-90, 90};

  boolean homedState;

  Shape currentShape;
  CAM currentCam;
  String currentShapeName;
  Processor processor;

  public GUI(PApplet parent, ControlP5 cp5, Communicator comm, int buttonHeight) {
    this.parent = parent;
    this.comm = comm;
    this.buttonHeight = buttonHeight;
    this.cp5 = cp5;
    initControls();
    processor = new Processor();
  }

  void show() {
    animationView.show();
    cp5.draw();
    statusLed.show();
    scrListPortsList.draw(parent.getGraphics()); // HACKY: draw port selector on top again (so ist not blocked by statusField)
  }

  void controlEventTrigger(ControlEvent ce) {
    Controller c = ce.getController();
    if (c == btnLoadFile) {
      parent.selectInput("Select .csv file:", "fileSelected");
    } else if (c == btnSendToBender) {
      onBtnSendToBenderPressed();
    } else if (c == btnSimulate) {
      if (currentShape != null) {
        // TODO: IMPLEMENT ME (Show animated bending process)
      }
    } else if (c == btnMoveBenderPlus) {
      comm.sendCommand(Order.BENDER.getValue(), (int) sldrBenderRadius.getValue());
      if (homedState) setHomed(false);
    } else if (c == btnMoveBenderMinus) {
      comm.sendCommand(Order.BENDER.getValue(), (int) -sldrBenderRadius.getValue());
      if (homedState) setHomed(false);
    } else if (c == btnBendPinToggle) {
      comm.sendCommand(Order.PIN.getValue());
    } else if (c == btnFeedMinus) {
      comm.sendCommand(Order.FEEDER.getValue(), (int) -sldrFeedDist.getValue());
    } else if (c == btnFeedPlus) {
      comm.sendCommand(Order.FEEDER.getValue(), (int) sldrFeedDist.getValue());
    } else if (c == btnRotateZMinus) {
      comm.sendCommand(Order.ZAXIS.getValue(), (int) -sldrZAxisRadius.getValue());
    } else if (c == btnRotateZPlus) {
      comm.sendCommand(Order.ZAXIS.getValue(), (int) sldrZAxisRadius.getValue());
    } else if (c == btnSetHome) {
      comm.sendCommand(Order.SETHOMED.getValue());
    } else if (c == btnBendDegrees) {
      if (homedState) {
        println("beding: " + (int) sldrBendDegrees.getValue() + " degrees");
        comm.sendCommand(Order.BEND.getValue(), (int) sldrBendDegrees.getValue());
      }
    } else if (c == btnConnect) {
      comm.connectButtonPressed(scrListPortsList.getCaptionLabel().getText());
    }
  }

  void setHomed(boolean status) {
    if (status) {
      homedState = true;
      println("home position set");
      btnSetHome.setColorBackground(color(0, 255, 0));
    } else {
      homedState = false;
      println("lost home position");
      btnSetHome.setColorBackground(color(255, 100, 0));
      comm.sendCommand(Order.DELHOMED.getValue()); // ATTENTION: THIS COMMAND WILL CURRENTLY NOT GET THROUGH BECAUSE OF LOCKED CONNECTION, SO BENDER WONT KNOW WE LOST HOME POSITION.
    }
  }

  void onFileSelected(File selection) {
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
          currentShape = shape;
          currentShapeName = selection.getName();

          processor.setShape(currentShape);
          processor.preprocessShape();
          processor.calcCAM();
          currentCam = processor.getCam();
          animationView.updateCam(currentCam);

          tlCurrentFile.setText("current file: " + selection.getName());
        }
      } 
      catch (java.lang.IllegalArgumentException e) {
        // println(e);
        println("Error: not a valid .csv-file");
      }
    }
  }

  void sendInstructionsToBender() {
    CAM cam = currentCam;
    Instruction step;
    while ((step = cam.popStep()) != null) {
      if (step instanceof FeedInstruction) {
        float dist = step.getAttribute();
        println("feeding:" + step.getAttribute());      
        comm.sendCommand(Order.FEEDER.getValue(), (int) dist);
      } else if (step instanceof BendWireInstruction) {
        float angle = step.getAttribute();
        println("bending:" + step.getAttribute());      
        comm.sendCommand(Order.BEND.getValue(), (int) angle);
      } else if (step instanceof RotateHeadInstruction) {
        float angle = step.getAttribute();
        println("rotating zAxis:" + step.getAttribute());      
        comm.sendCommand(Order.ZAXIS.getValue(), (int) angle);
      }
    }
  }

  void onBtnSendToBenderPressed() {
    if (currentShape != null) {
      if (homedState) {
        sendInstructionsToBender();
      } else {
        println("home first");
      }
    } else {
      println("no shape selected");
    }
  }

  void updateStatus(int status) {
    switch(status) {
    case 0:
      println("IMPLEMENT ME");
    case 3:
      tlStatusField.setText("status: connected to bender");
      statusLed.updateStatus(status);
      btnConnect.setLabel("disconnect");
      break;
    case 4:
      tlStatusField.setText("status: connection timed out");
      statusLed.updateStatus(status);
      btnConnect.setLabel("connect");
      break;
    case 5:
      tlStatusField.setText("status: connection lost");
      statusLed.updateStatus(status);
      btnConnect.setLabel("connect");
      break;
    case 6:
      tlStatusField.setText("status: port not found");
      statusLed.updateStatus(status);
      btnConnect.setLabel("connect");
      break;
    }
  }

  void initControls() {
    // ANIMATION VIEW
    animationView = new AnimationView(
      parent, 
      width/2, 
      0, 
      width/2, 
      height, 
      color(255, 120, 120), 
      color(120, 255, 120), 
      1.0, 
      assets);

    // CONTROLS
    int xFirst = 20;
    int xScnd = xFirst + buttonHeight*2 + buttonHeight / 5;
    int xThird = xScnd + buttonHeight*2 + buttonHeight / 5;
    int rowY = 20;

    // LOAD AND RENDER
    newHeader("LOAD FILE", xFirst, rowY);
    rowY += 15;
    btnLoadFile = newButton("load", xFirst, rowY, buttonHeight*2, buttonHeight/2);
    tlCurrentFile = cp5.addTextlabel("currentFile", "no file loaded", xScnd, rowY + buttonHeight / 6);

    rowY += buttonHeight / 1.75;
    btnSendToBender = newButton("send to bender", xFirst, rowY, buttonHeight*2, buttonHeight/2)
      .setColorBackground(color(145, 0, 0));
    // btnSimulate = newButton("simulate", xScnd, rowY, buttonHeight*2, buttonHeight/2)
    //  .setColorBackground(color(50, 200, 30));

    // MANUAL CONTROLS
    rowY += buttonHeight + 5;
    newHeader("MANUAL CONTROLS", xFirst, rowY);
    rowY += 15;

    btnMoveBenderMinus = newButton("Bender -", xFirst, rowY, buttonHeight*2, buttonHeight);
    btnMoveBenderPlus = newButton("Bender +", xScnd, rowY, buttonHeight*2, buttonHeight);
    sldrBenderRadius = newSlider("bender steps", xThird, rowY, buttonHeight*2, buttonHeight, 0, angleRangeBender[1], 5);

    rowY += buttonHeight + 5;
    btnFeedMinus = newButton("Feed -", xFirst, rowY, buttonHeight*2, buttonHeight);
    btnFeedPlus = newButton("Feed +", xScnd, rowY, buttonHeight*2, buttonHeight);
    sldrFeedDist = newSlider("feeder steps", xThird, rowY, buttonHeight*2, buttonHeight, 0, 100, 5);

    rowY += buttonHeight + 5;
    btnRotateZMinus = newButton("zAxis -", xFirst, rowY, buttonHeight*2, buttonHeight);
    btnRotateZPlus = newButton("zAxis +", xScnd, rowY, buttonHeight*2, buttonHeight);
    sldrZAxisRadius = newSlider("z-axis steps", xThird, rowY, buttonHeight*2, buttonHeight, 0, angleRangeZAxis[1], 5);

    rowY += buttonHeight + 5;
    btnBendPinToggle = newButton("BendPin", xFirst, rowY, buttonHeight*2, buttonHeight);
    btnSetHome = newButton("Home", xScnd, rowY, buttonHeight*2, buttonHeight)
      .setColorBackground(color(255, 200, 0));

    rowY += buttonHeight + 10;
    btnBendDegrees = newButton("bend", xFirst, rowY, buttonHeight*2, buttonHeight)
      .setColorBackground(color(255, 153, 235));
    sldrBendDegrees = newSlider("radius", xScnd, rowY, buttonHeight*2, buttonHeight, angleRangeBender[0], angleRangeBender[1], 0)
      .setNumberOfTickMarks(5)
      .snapToTickMarks(false);

    // CONNECTION OPTIONS
    rowY += buttonHeight + 25;
    newHeader("CONNECTION", xFirst, rowY);
    rowY += 15;
    scrListPortsList = cp5.addScrollableList("serial ports")
      .setPosition(xFirst, rowY)
      .setSize(buttonHeight*4+5, 75)
      .setBarHeight(buttonHeight/2)
      .setItemHeight(buttonHeight/2)
      .setType(ControlP5.DROPDOWN)
      .addItems(comm.getAvailablePorts())
      .setOpen(false);

    btnConnect = newButton("connect", xThird, rowY, buttonHeight*2, buttonHeight/2);
    rowY += buttonHeight / 1.25;
    int ledRadius = 5;
    statusLed = new StatusLed(xFirst+ledRadius, rowY+ledRadius, ledRadius);
    tlStatusField = cp5.addTextlabel("status", comm.getStatus(), int(xFirst*1.5), rowY);

    // set port list current entry to default port (if available)
    if (Arrays.asList(Serial.list()).contains(comm.defaultPort)) {
      println("default port found in ports list");
      scrListPortsList.setValue(Arrays.asList(comm.getAvailablePorts()).indexOf(comm.defaultPort));
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
      //.setRange(min, max)
      //.setValue(value)
      ;
    return slider;
  }

  Textlabel newHeader(String text, int x, int y) {
    String name = text;
    text = "" + text + "";
    Textlabel tl = cp5.addTextlabel(name, text, x, y); 
    return tl;
  }
}
