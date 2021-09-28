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
  Button btnReloadSettings;
  Button btnCloseSettings;  
  Button btnSettings;

  Slider sldrBenderRadius;
  Slider sldrFeedDist;
  Slider sldrZAxisRadius;
  Slider sldrBendDegrees;

  ScrollableList scrListPortsList;

  Textlabel tlStatusField;
  Textlabel tlCurrentFile;
  Textlabel tlFeedingConstant;
  Textlabel tlOffsetForNegBend;
  Textlabel tlZAngleConstant;
  Textlabel tlNegBendAngleConstant;
  Textlabel tlBendAngleConstant;

  StatusLed statusLed;
  AnimationView animationView;

  Group grpLoadAndRender;
  Group grpSettings;

  int buttonHeight;
  int[] angleRangeBender = {-90, 90};
  int[] angleRangeZAxis = {-90, 90};

  boolean homedState;

  Shape currentShape;
  CAM currentCam;
  String currentShapeName;
  Preprocessor preprocessor;

  public GUI(PApplet parent, ControlP5 cp5, Communicator comm, int buttonHeight) {
    this.parent = parent;
    this.comm = comm;
    this.buttonHeight = buttonHeight;
    this.cp5 = cp5;
    initControls(); //<>//
    preprocessor = new Preprocessor(); //<>//
  }

  void show() {
    animationView.show();
    cp5.draw();
    statusLed.show();
    scrListPortsList.draw(parent.getGraphics()); // HACKY: draw port selector on top again (so its not blocked by statusField)
  }

  void controlEventTrigger(ControlEvent ce) {
    Controller c = ce.getController();
    if (c == btnLoadFile) {
      parent.selectInput("Select .csv file:", "fileSelected");
    } else if (c == btnSendToBender) {
      onBtnSendToBenderPressed();
      //} else if (c == btnSimulate) {
      //  if (currentShape != null) {
      //    // TODO: IMPLEMENT ME (Show animated bending process)
      //  }
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
    } else if (c == btnSettings) {
      onBtnSettingsPressed();
    } else if (c == btnReloadSettings) {
      onBtnReloadSettingsPressed();
    } else if (c == btnCloseSettings) {
      onBtnCloseSettingsPressed();
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
          new UiBooster().showInfoDialog("Error: file could not be parsed");
        } else {
          Shape shape = new Shape(pg.shapeFromCSV(table));    
          debug(shape.toString());
          currentShape = shape;
          currentShapeName = selection.getName();

          preprocessor.setShape(currentShape);
          preprocessor.preprocessShape();
          preprocessor.calcCAM();
          currentCam = preprocessor.getCam();
          animationView.updateCam(currentCam);

          tlCurrentFile.setText("current file: " + selection.getName());
        }
      } 
      catch (java.lang.IllegalArgumentException e) {
        new UiBooster().showInfoDialog("Error: not a valid .csv-file.\n" + e);
      }
    }
  }

  void onBtnSendToBenderPressed() {
    if (currentShape != null) {
      if (homedState) {
        comm.sendInstructionsToBender(currentCam);
      } else {
        println("home first");
      }
    } else {
      println("no shape selected");
    }
  }

  void onBtnSettingsPressed() {
    grpLoadAndRender.setVisible(false);
    grpSettings.setVisible(true);
  }

  void onBtnReloadSettingsPressed() {
    parseConfig();
    tlFeedingConstant.setText(str(FEEDING_CONSTANT));
    tlZAngleConstant.setText(str(Z_ANGLE_CONSTANT));
    tlOffsetForNegBend.setText(str(OFFSET_FOR_NEG_BEND));
    tlBendAngleConstant.setText(str(BEND_ANGLE_CONSTANT));
    tlNegBendAngleConstant.setText(str(NEG_BEND_ANGLE_CONSTANT));
    comm.overwriteSetting();
  }

  void onBtnCloseSettingsPressed() {
    grpLoadAndRender.setVisible(true);
    grpSettings.setVisible(false);
  }


  void updateStatus(int status) {
    println("connection Status: " + status);
    switch(status) {
    case 0:
      tlStatusField.setText("status: not connected");
      statusLed.updateStatus(status);
      btnConnect.setLabel("connect");
      break;
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

    // LOAD AND RENDER // SETTING
    grpLoadAndRender = cp5.addGroup("grpLoadAndRender");
    grpSettings = cp5.addGroup("grpSettings");

    newHeader("LOAD FILE", xFirst, rowY).moveTo(grpLoadAndRender);
    newHeader("SETTINGS", xFirst, rowY).moveTo(grpSettings);
    rowY += 15;
    btnLoadFile = newButton("load", xFirst, rowY, buttonHeight*2, buttonHeight/2).moveTo(grpLoadAndRender);
    tlCurrentFile = cp5.addTextlabel("currentFile", "no file loaded", xScnd, rowY + buttonHeight / 6).moveTo(grpLoadAndRender);

    cp5.addTextlabel("feed constant")
      .setPosition(xFirst, rowY)
      .setSize(buttonHeight, buttonHeight/2)
      .setText("feed constant:")
      .moveTo(grpSettings);
    tlFeedingConstant = cp5.addTextlabel("feed constant value")
      .setPosition(xScnd, rowY)
      .setSize(buttonHeight, buttonHeight/2)
      .setText(str(FEEDING_CONSTANT))
      .moveTo(grpSettings);

    cp5.addTextlabel("z axis constant")
      .setPosition(xFirst, rowY+12)
      .setSize(buttonHeight, buttonHeight/2)
      .setText("z axis constant:")
      .moveTo(grpSettings);
    tlZAngleConstant = cp5.addTextlabel("z axis constant value")
      .setPosition(xScnd, rowY+12)
      .setSize(buttonHeight, buttonHeight/2)
      .setText(str(Z_ANGLE_CONSTANT))
      .moveTo(grpSettings);

    cp5.addTextlabel("offset for neg bend")
      .setPosition(xFirst, rowY+24)
      .setSize(buttonHeight, buttonHeight/2)
      .setText("- bend offset:")
      .moveTo(grpSettings);
    tlOffsetForNegBend = cp5.addTextlabel("- bend offset value")
      .setPosition(xScnd, rowY+24)
      .setSize(buttonHeight, buttonHeight/2)
      .setText(str(OFFSET_FOR_NEG_BEND))
      .moveTo(grpSettings);

    cp5.addTextlabel("+ bend constant")
      .setPosition(xFirst, rowY+36)
      .setSize(buttonHeight, buttonHeight/2)
      .setText("+ bend constant:")
      .moveTo(grpSettings);
    tlBendAngleConstant = cp5.addTextlabel("+ bend constant value")
      .setPosition(xScnd, rowY+36)
      .setSize(buttonHeight, buttonHeight/2)
      .setText(str(BEND_ANGLE_CONSTANT))
      .moveTo(grpSettings);
  
    cp5.addTextlabel("- bend constant")
      .setPosition(xFirst, rowY+48)
      .setSize(buttonHeight, buttonHeight/2)
      .setText("- bend constant:")
      .moveTo(grpSettings);
    tlNegBendAngleConstant = cp5.addTextlabel("- bend constant value")
      .setPosition(xScnd, rowY+48)
      .setSize(buttonHeight, buttonHeight/2)
      .setText(str(NEG_BEND_ANGLE_CONSTANT))
      .moveTo(grpSettings);

    btnReloadSettings = newButton("reload", xThird, rowY, buttonHeight*2, buttonHeight/2).moveTo(grpSettings);
    btnCloseSettings = newButton("close", xThird, rowY+buttonHeight/2+5, buttonHeight*2, buttonHeight/2).moveTo(grpSettings)
      .setColorBackground(color(255, 100, 100));

    rowY += buttonHeight / 1.75;
    btnSettings = newButton("Settings", xThird, rowY, buttonHeight*2, buttonHeight/2).moveTo(grpLoadAndRender)
      .setColorBackground(color(50));  

    btnSendToBender = newButton("send to bender", xFirst, rowY, buttonHeight*2, buttonHeight/2)
      .setColorBackground(color(145, 0, 0))
      .moveTo(grpLoadAndRender);
    // btnSimulate = newButton("simulate", xScnd, rowY, buttonHeight*2, buttonHeight/2)
    //  .setColorBackground(color(50, 200, 30));
    grpLoadAndRender.setVisible(true);
    grpSettings.setVisible(false);

    // MANUAL CONTROLS
    rowY += buttonHeight + 5;
    newHeader("MANUAL CONTROLS", xFirst, rowY);
    rowY += 15;

    btnMoveBenderMinus = newButton("Bender -", xFirst, rowY, buttonHeight*2, buttonHeight);
    btnMoveBenderPlus = newButton("Bender +", xScnd, rowY, buttonHeight*2, buttonHeight); //<>//
    sldrBenderRadius = newSlider("bender steps", xThird, rowY, buttonHeight*2, buttonHeight, 0, angleRangeBender[1], 5); //<>//

    rowY += buttonHeight + 5; //<>//
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
    if (Arrays.asList(Serial.list()).contains(DEFAULT_PORT)) {
      debug("default port found in ports list");
      scrListPortsList.setValue(Arrays.asList(comm.getAvailablePorts()).indexOf(DEFAULT_PORT));
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
      .setValue(value)
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
