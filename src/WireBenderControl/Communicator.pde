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
  String defaultPort;
  String statusText = "status: not connected";
  String[] ports;

  boolean connectionIsLocked = false;

  char serialIn;

  public Communicator(PApplet parent, int baudRate, String defaultPort) {
    this.parent = parent;
    this.baudRate = baudRate;
    this.ports = Serial.list();
    this.lastMillis = millis();
    //connectToPort(defaultPort);
  }

  String[] getAvailablePorts() {
    return ports;
  }

  String getStatus() {
    return statusText;
  }

  void update() {
    //  if (connectionStatus == 3) {
    //    if (millis() - lastMillis > checkConnectionInterval) {
    //      comm.sendCommand(Order.ISALIVE.getValue());
    //      lastMillis = millis();
    //    }
    //    if (millis() - lastSignOfLife > isAliveTimeout) {
    //      connectionStatus = 5;
    //      statusLed.updateStatus(connectionStatus);
    //      disconnect();
    //      statusField.setText("status: connection to bender lost!");
    //    }
    //  }
  }

  void connectButtonPressed(String selectedPort) {
    if (connectionStatus != 3) {
      connectToPort(selectedPort);
    } else {
      disconnect();
    }
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

  void sendCommand(int cmd) {
    if (!connectionIsLocked && connectionStatus == 3) {
      //if (connectionStatus == 3) {
      connectionIsLocked = true;
      //println("sending command: " + cmd);
      sendSingleByte(cmd);
      delay(100);
    }
  }

  void sendCommand(int cmd, int value) {
    //if (!connectionIsLocked && connectionStatus == 3) {
    if (connectionStatus == 3) {
      connectionIsLocked = true;
      //println("sending command: " + cmd + " with value: " + value);
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
    buffer[0] = (byte)((value >> 8) & 0xff);
    buffer[1] = (byte)((value >> 0) & 0xff);
    myPort.write(buffer);
}

  void serialEventTrigger(Serial p) {
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
      gui.setHomed(true);
    }
  }
}
