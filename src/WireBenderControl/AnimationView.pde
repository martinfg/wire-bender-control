class AnimationView {
  GViewPeasyCam peasyView;

  String title;
  boolean showAxis = true;
  float axisLen = 15.0;
  float axisAlpha = 50;

  Shape shape;
  Simulation simu;
  float simuSpeed;
  color dotColor;
  color pathColor;
  Maschine maschine;

  AnimationView(PApplet app, int x, int y, int w, int h, color dotColor, color pathColor, float simuSpeed, ArrayList<PShape> machineAssets) {
    peasyView = new GViewPeasyCam(app, x, y, w, h, 100);
    PeasyCam pcam = peasyView.getPeasyCam();
    pcam.setMinimumDistance(100);
    pcam.setMaximumDistance(400);
    //pcam.setDistance(100);

    // this.title = title;
    this.maschine = new Maschine(machineAssets.get(0));
    this.dotColor = dotColor;
    this.pathColor = pathColor;
    this.simuSpeed = simuSpeed;
  }

  void show() {
    PGraphics pg = peasyView.getGraphics();
    PeasyCam peasyCam = peasyView.getPeasyCam();
    pg.beginDraw();
    pg.resetMatrix();
    //pg.ambientLight(100, 100, 100);
    //pg.directionalLight(220, 220, 0, 0.8f, 1, -1.2f);
    peasyCam.feed();
    pg.background(180);
    if (showAxis) showAxis(pg);
    maschine.show(pg);
    if (simu != null) simu.show(pg);
    else {
      peasyCam.beginHUD();
      pg.fill(255);
      pg.textSize(10);
      pg.textAlign(CENTER, CENTER);
      pg.text("no shape selected", peasyView.width()/2, peasyView.height()/2);      
      peasyCam.endHUD();
    }
    peasyCam.beginHUD();
    pg.pushMatrix();
    pg.fill(200, 255, 200, 255);
    pg.stroke(255);
    pg.strokeWeight(1);
    pg.lights();
    pg.translate(50, 50, 0);
    pg.rotateX(peasyCam.getRotations()[0]);
    pg.rotateY(peasyCam.getRotations()[1]);
    pg.rotateZ(peasyCam.getRotations()[2]);
    pg.box(25);
    pg.popMatrix();
    peasyCam.endHUD();
    pg.endDraw();
  }

  void updateCam(CAM cam) {
    this.simu = new Simulation(cam, dotColor, pathColor, simuSpeed, false);
    simu.simulateResult();
  }

  void showAxis(PGraphics pg) {
    //X-Axis
    pg.strokeWeight(1);
    pg.stroke(255, 0, 0, axisAlpha);
    pg.line(0, 0, 0, axisLen, 0, 0);
    //Y-Axis
    pg.stroke(0, 255, 0, axisAlpha);
    pg.line(0, 0, 0, 0, axisLen, 0);
    //Z-Axis
    pg.stroke(0, 0, 255, axisAlpha);
    pg.line(0, 0, 0, 0, 0, axisLen);
  }




  //void mousePressed() {
  //  println("mousePressed in secondary window");
  //}
}
