class Communicator {

  PApplet parent;
  Serial myPort;

  int baudRate;
  int connectionStatus = 0; //0: not connected, 1: connected to port, 2: establishing connection to bender, 3: connected to bender, 4: time out, 5: connection lost, 6: port not found
  int startOfConnectionAttempt; // needed to track timeout when connecting
  int delayAfterPortConnected = 2000;
  int connectionEstablishTimeout = 1500;
  int isAliveTimeout = 15000;
  int lastSignOfLife;
  int checkConnectionInterval = 1000;
  int lastMillis;

  String selectedPort;
  String statusText = "status: not connected";
  String[] ports;

  boolean benderIsBusy = false;

  char serialIn;

  CAM benderInstructions;

  public Communicator(PApplet parent, int baudRate) {
    this.parent = parent;
    this.baudRate = baudRate;
    this.ports = Serial.list();
    this.lastMillis = millis();
    this.benderInstructions = null;
  }

  String[] getAvailablePorts() {
    return ports;
  }

  String getStatus() {
    return statusText;
  }

  void update() {
    if (benderInstructions != null) {
      Instruction step;
      // TODO: SEND SEQUENCE START
      if (!benderIsBusy) {
        if ((step = benderInstructions.popStep()) != null) {
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
        } else {
          // TODO: SEND SEQUENCE END
          benderInstructions = null;
          println("bending sequence done");
        }
      }
    }

    //  if (connectionStatus == 3) {
    //    if (millis() - lastMillis > checkConnectionInterval) {
    //      comm.sendCommand(Order.ISALIVE.getValue());
    //      lastMillis = millis();
    //    }
    //    if (millis() - lastSignOfLife > isAliveTimeout) {
    //      connectionStatus = 5;
    //      statusLed.upda atus(connectionStatus);
    //      disconnect();
    //      statusField.setText("status: connection to bender lost!");
    //    }
    //  }
  }

  void sendInstructionsToBender(CAM cam) {
    benderInstructions = cam;
  }

  void connectButtonPressed(String selectedPort) {
    if (connectionStatus != 3) {
      connectToPort(selectedPort);
    } else {
      disconnect();
    }
  }

  void overwriteSetting() {
    sendCommand(Order.SET_FEEDING_CONSTANT.getValue(), FEEDING_CONSTANT);
    sendCommand(Order.SET_Z_ANGLE_CONSTANT.getValue(), Z_ANGLE_CONSTANT);
    sendCommand(Order.SET_OFFSET_FOR_NEG_BEND.getValue(), OFFSET_FOR_NEG_BEND);
    sendCommand(Order.SET_BEND_ANGLE_CONSTANT.getValue(), BEND_ANGLE_CONSTANT);
    sendCommand(Order.SET_NEG_BEND_ANGLE_CONSTANT.getValue(), NEG_BEND_ANGLE_CONSTANT);
  }

  void connectToPort(String portName) {
    try {
      myPort = new Serial(parent, portName, baudRate);
      connectionStatus = 1;
      delay(delayAfterPortConnected);
      connectionStatus = 2;
      myPort.write(byte(Order.HELLO.getValue())); // do not use comm.sendCommandMethod here (does not work without active connection)
      startOfConnectionAttempt = millis();
      while (true) {
        if (millis() - startOfConnectionAttempt >= connectionEstablishTimeout) {
          connectionStatus = 4;
          delay(200);
          throw new Exception ("Connection timed Out");
        }
        if (connectionStatus == 3) {
          println("connection established");
          gui.updateStatus(connectionStatus);
          lastSignOfLife = millis();
          overwriteSetting();
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
        gui.updateStatus(connectionStatus);
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
        gui.updateStatus(connectionStatus);
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
      gui.updateStatus(0);
      gui.setHomed(false);
    }
  }

  // TODO: RENAME TO sendOrder
  void sendCommand(int cmd) {
    if (connectionStatus == 3) {
      println("sending command: " + cmd);
      sendSingleByte(cmd);
      delay(100);
    }
  }

  void sendCommand(int cmd, int value) {
    if (connectionStatus == 3) {
      benderIsBusy = true;
      println("sending command: " + cmd + " with value: " + value);
      sendSingleByte(cmd);
      sendByteArray(value);
      delay(100);
    }
  }

  void sendSingleByte(int value) {
    if (value > -128 && value < 128) {
      myPort.write(byte(value));
    } else {
      // TODO: Throw exception here
      println("value error while sending byte");
    }
  }

  void sendByteArray(int value) {
    byte[] buffer = new byte[2];
    buffer[1] = (byte)((value >> 8) & 0xff);
    buffer[0] = (byte)((value >> 0) & 0xff);
    // println(buffer);
    myPort.write(buffer);
  }

  void serialEventTrigger(Serial p) {
    serialIn = p.readChar(); 
    println("received data: " + byte(serialIn));
    if (serialIn == Order.RECEIVED.getValue()) {
      // println("confirmation received");
    } else if (serialIn == Order.CMD_EXECUTED.getValue()) {
      benderIsBusy = false;
    } else if (serialIn == Order.HELLO.getValue()) {
      connectionStatus = 3;
    } else if (serialIn == Order.ISALIVE.getValue()) {
      lastSignOfLife = millis();
      //println("isAlive");
    } else if (serialIn == Order.ISHOMED.getValue()) {
      gui.setHomed(true);
    }
  }
}
