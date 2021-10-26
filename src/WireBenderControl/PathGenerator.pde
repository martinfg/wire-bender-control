public class PathGenerator {
  private ArrayList<ArrayList> simpleShapes;

  public PathGenerator() {}

  public ArrayList<PVector3> shapeFromCSV(Table table) {
    try {
      ArrayList<PVector3> points = new ArrayList<PVector3>();
      for (TableRow row : table.rows()) {
        float x = row.getInt("x");
        float y = row.getInt("y");
        float z = row.getInt("z");
        points.add(new PVector3(x, y, z));
      }
      return points;
    } 
    catch (Exception e) {
      println(e);
      return null;
    }
  }

  public ArrayList<PVector3> getSimpleShape(int index) {
    return simpleShapes.get(index);
  }

  public ArrayList<PVector3> getRandomShape(int len) {
    ArrayList<PVector3> points = new ArrayList<PVector3>();
    for (int i = 0; i < len; i++) {
      points.add(new PVector3(random(-50, 50), random(-50, 50), random(-50, 50)));
    }
    return points;
  }

  public ArrayList<PVector3> getPerlinShape(int len, float scale) {
    ArrayList<PVector3> points = new ArrayList<PVector3>();
    float xoff = random(-100, 100);
    float yoff = random(-100, 100);
    float zoff = random(-100, 100);    
    for (int i = 0; i < len; i++) {
      PVector3 p = new PVector3(noise(xoff), noise(yoff), noise(zoff));
      p.mult(scale);
      points.add(p);

      xoff += 0.03;
      yoff += 0.05;
      zoff -= 0.1;
    }
    return points;
  }
}
