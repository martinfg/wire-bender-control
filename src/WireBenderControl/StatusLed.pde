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
