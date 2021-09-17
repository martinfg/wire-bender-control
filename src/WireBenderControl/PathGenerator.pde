public class PathGenerator {
  private ArrayList<ArrayList> simpleShapes;

  public PathGenerator() {
    simpleShapes = new ArrayList<ArrayList>();

    // wiered cube
    simpleShapes.add(new ArrayList<PVector3>(
      Arrays.asList(
      new PVector3(0.0, 0.0, 0.0), 
      new PVector3(50.0, 0.0, 0.0), 
      //new PVector3(50.0, 50.0, 0.0), 
      new PVector3(0.0, 50.0, 0.0), 
      new PVector3(0.0, 50.0, 50.0)//, 
      //new PVector3(50.0, 50.0, 50.0), 
      //new PVector3(50.0, 0.0, 50.0)
      )));

    // rectangle not centered
    simpleShapes.add(new ArrayList<PVector3>(
      Arrays.asList(
      new PVector3(50.0, 0.0, 0.0), 
      new PVector3(100.0, 0.0, 0.0), 
      new PVector3(100.0, 50.0, 0.0), 
      new PVector3(50.0, 50.0, 0.0), 
      new PVector3(50.0, 0.0, 0.0)
      )));

    // cube with handle
    simpleShapes.add(new ArrayList<PVector3>(
      Arrays.asList(
      new PVector3(0.0, 0.0, 0.0), 
      new PVector3(50.0, 0.0, 0.0), 
      new PVector3(50.0, -50.0, 0.0), 
      new PVector3(100.0, -50.0, 0.0), 
      new PVector3(100.0, 0.0, 0.0), 
      new PVector3(50.0, 0.0, 0.0), 
      new PVector3(50.0, 0.0, 50.0), 
      new PVector3(100.0, 0.0, 50.0), 
      new PVector3(100.0, -50.0, 50.0), 
      new PVector3(50.0, -50.0, 50.0), 
      new PVector3(50.0, 0.0, 50.0) 
      )));

    // ZickTack2D
    simpleShapes.add(new ArrayList<PVector3>(
      Arrays.asList(
      //new PVector3(0.0, 0.0, 0.0), 
      new PVector3(10.0, 0.0, 0.0), 
      new PVector3(20.0, -30.0, 0.0), 
      new PVector3(50.0, 0.0, 0.0), 
      new PVector3(75.0, 10.0, 0.0), 
      new PVector3(100.0, 0.0, 0.0), 
      new PVector3(150.0, 35.0, 0.0)
      )));

    // AlignTest
    simpleShapes.add(new ArrayList<PVector3>(
      Arrays.asList(
      new PVector3(20.0, 20.0, 20.0), 
      new PVector3(40.0, 40.0, 40.0), 
      new PVector3(60.0, 60.0, 60.0)
      )));

    // open 2d triangle
    simpleShapes.add(new ArrayList<PVector3>(
      Arrays.asList(
      new PVector3(0.0, 0.0, 0.0), 
      new PVector3(10.0, 10.0, 0.0), 
      new PVector3(20.0, 0.0, 0.0), 
      new PVector3(30.0, 10.0, 0.0), 
      new PVector3(40.0, 0.0, 0.0) 
      )));

    // random 3d
    simpleShapes.add(new ArrayList<PVector3>(
      Arrays.asList(
      new PVector3(15.0, 0.0, -9.0), 
      new PVector3(-7.0, 31.0, 13.0), 
      new PVector3(-120.0, 50.0, 3.0), 
      new PVector3(1.0, 0.1, 6.2), 
      new PVector3(42.0, 0.0, -7.0) 
      )));
  }

  public ArrayList<PVector3> shapeFromCSV(Table table) {
    try {
      ArrayList<PVector3> points = new ArrayList<PVector3>();
      for (TableRow row : table.rows()) {
        float x = row.getInt("x");
        float y = row.getInt("y");
        float z = row.getInt("z");
        points.add(new PVector3(x, y, z));
      }
      // println(points.size());
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


  //public ArrayList<PVector> generatePath(int numSegments){
  //  ArrayList path = new ArrayList<PVector>();    
  //  return path;
  //}
}
