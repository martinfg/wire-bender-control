public class Maschine {
  PShape model;
  PVector3 headPosition;
  float headWidth;

  public Maschine(PShape model) {
    this.model = model;
    this.headWidth = 2.5;
    this.headPosition = new PVector3(headWidth, -headWidth, 0.0);
  }

  public void show(PGraphics pg) {
    pg.lights();

    // Feeder
    pg.fill(255, 200, 100, 20);
    pg.pushMatrix();
    pg.rotateY(-HALF_PI);
    pg.translate(-3.6, -3.6, 0);
    //box(d, w, h);
    pg.scale(0.5);
    pg.shape(model, 0, 0);
    pg.popMatrix();

    // BendingHead
    //pg.fill(255, 0, 0);
    //pg.noStroke();
    //pg.pushMatrix();
    //pg.translate(headPosition.x, headPosition.y, headPosition.z);
    //sphere(headWidth);
    //pg.popMatrix();
  }
}
