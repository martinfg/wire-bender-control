public class Shape {
  private ArrayList<PVector3> points;

  public Shape() {
    this.points = new ArrayList<PVector3>();
  }

  public Shape(ArrayList<PVector3> points) {
    this.points = points;
  }

  public void zeroCenter(PVector3 firstPoint) {
    ArrayList<PVector3> centeredPoints = new ArrayList<PVector3>();
    for (int i = 0; i < points.size(); i++) {
      centeredPoints.add(points.get(i).sub(firstPoint));
    }
    points = centeredPoints;
  }

  public int getLength() {
    return this.points.size();
  }

  public void trans(PVector3 v) {
    for (PVector3 p : this.points) {
      p.trans(v);
    }
  }

  public void rotX(float angle) {
    for (PVector3 p : this.points) {
      p.rotX(angle);
    }
  }

  public void rotY(float angle) {
    for (PVector3 p : this.points) {
      p.rotY(angle);
    }
  }

  public void rotZ(float angle) {
    for (PVector3 p : this.points) {
      p.rotZ(angle);
    }
  }

  public PVector3 getPoint(int index) {
    return this.points.get(index);
  }

  public void addPoint(PVector3 point) {
    points.add(point);
  }

  public Shape copy() {
    ArrayList<PVector3> pointsCopy = new ArrayList<PVector3>();
    for (PVector3 p : this.points) {
      pointsCopy.add(p.copy());
    }
    return (new Shape(pointsCopy));
  }

  public void reverseOrder() {
    Collections.reverse(this.points);
  }

  public String toString() {
    String s = "";  
    for (PVector3 p : points) {
      s += p.toString();
      s += "\n";
    }
    return s;
  }

  public void show(PGraphics pg, color pathColor, color dotColor, boolean connectLastToOrigin) {
    if (points.size() < 1) return;
    PVector3 prevPoint = this.points.get(0);
    for (PVector3 p : this.points) {
      // show points
      pg.pushMatrix();
      pg.translate(p.x, p.y, p.z);
      pg.noStroke();
      pg.fill(dotColor);
      //sphere(1);
      pg.popMatrix();

      // show lines
      pg.strokeWeight(3);
      pg.stroke(pathColor);
      if (this.points.get(0) != p) {
        pg.line(prevPoint.x, prevPoint.y, prevPoint.z, 
          p.x, p.y, p.z);
        prevPoint = p;
      }
    }
    // last point in List is connected to origin
    if (connectLastToOrigin) {
      pg.strokeWeight(3);
      pg.stroke(pathColor);
      PVector3 lastInList = points.get(points.size()-1);
      pg.line(lastInList.x, lastInList.y, lastInList.z, 0.0, 0.0, 0.0);
    }
  }
}
