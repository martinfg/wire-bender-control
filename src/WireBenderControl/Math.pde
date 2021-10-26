public class Matrix {
  private float[][] m;

  public Matrix(float[] row0, float[] row1, float[] row2) {
    this.m = new float[3][3];
    this.m[0] = row0;
    this.m[1] = row1;
    this.m[2] = row2;
  }

  public float[][] getMatrix() {
    return this.m;
  }    

  public void multiplyWithMatrix(Matrix matrix) {
    float[][] m2 = matrix.getMatrix();

    // first row 
    float _11 = this.m[0][0] * m2[0][0] + this.m[0][1] * m2[1][0] + this.m[0][2] * m2[2][0];
    float _12 = this.m[0][0] * m2[0][1] + this.m[0][1] * m2[1][1] + this.m[0][2] * m2[2][1];
    float _13 = this.m[0][0] * m2[0][2] + this.m[0][1] * m2[1][2] + this.m[0][2] * m2[2][2];
    float[] row1 = {_11, _12, _13};

    // second row
    float _21 = this.m[1][0] * m2[0][0] + this.m[1][1] * m2[1][0] + this.m[1][2] * m2[2][0];
    float _22 = this.m[1][0] * m2[0][1] + this.m[1][1] * m2[1][1] + this.m[1][2] * m2[2][1];
    float _23 = this.m[1][0] * m2[0][2] + this.m[1][1] * m2[1][2] + this.m[1][2] * m2[2][2];
    float[] row2 = {_21, _22, _23};

    // third row
    float _31 = this.m[2][0] * m2[0][0] + this.m[2][1] * m2[1][0] + this.m[2][2] * m2[2][0];
    float _32 = this.m[2][0] * m2[0][1] + this.m[2][1] * m2[1][1] + this.m[2][2] * m2[2][1];
    float _33 = this.m[2][0] * m2[0][2] + this.m[2][1] * m2[1][2] + this.m[2][2] * m2[2][2];
    float[] row3 = {_31, _32, _33};

    this.m[0] = row1;
    this.m[1] = row2;
    this.m[2] = row3;
  }

  public String toString() {
    String s = "";
    s += Arrays.toString(this.m[0]) + "\n";
    s += Arrays.toString(this.m[1]) + "\n";
    s += Arrays.toString(this.m[2]);
    return s;
  }
}

public class PVector3 extends PVector {
  public PVector3(float x, float y, float z) {
    super(x, y, z);
  }

  public PVector3 copy() {
    return(new PVector3(this.x, this.y, this.z));
  }

  public PVector3 sub(PVector p) {
    float x = this.x - p.x;
    float y = this.y - p.y;
    float z = this.z - p.z;
    return new PVector3(x, y, z);
  }

  public PVector3 cross(PVector3 p) {
    float x = this.y*p.z - this.z*p.y;
    float y = this.z*p.x - this.x*p.z;
    float z = this.x*p.y - this.y*p.x;
    return (new PVector3(x, y, z));
  }
  
  public float dot(PVector3 p) {
    float a = this.x * p.x;
    float b = this.y * p.y;
    float c = this.z * p.z;    
    return (a + b + c);
  }

  public void trans(PVector dir) {
    this.add(dir);
  }

  public void rotX(float a) {
    float[] row1 = {1.0, 0.0, 0.0};     
    float[] row2 = {0.0, (float) Math.cos(a), (float) -Math.sin(a)};     
    float[] row3 = {0.0, (float) Math.sin(a), (float) Math.cos(a)};          
    this.multiplyWithMatrix(new Matrix(row1, row2, row3));
  }

  public void rotY(float a) {
    float[] row1 = {(float) Math.cos(a), 0.0, (float) Math.sin(a)};     
    float[] row2 = {0.0, 1.0, 0, 0};     
    float[] row3 = {(float) -Math.sin(a), 0.0, (float) Math.cos(a)};          
    this.multiplyWithMatrix(new Matrix(row1, row2, row3));
  }

  public void rotZ(float a) {
    float[] row1 = {(float) Math.cos(a), (float) -Math.sin(a), 0.0};
    float[] row2 = {(float) Math.sin(a), (float) Math.cos(a), 0.0};     
    float[] row3 = {0.0, 0.0, 1.0};     
    this.multiplyWithMatrix(new Matrix(row1, row2, row3));
  }

  private void multiplyWithMatrix(Matrix matrix) {
    float[][] m = matrix.getMatrix();
    float x = m[0][0] * this.x + m[0][1] * this.y + m[0][2] * this.z;
    float y = m[1][0] * this.x + m[1][1] * this.y + m[1][2] * this.z;
    float z = m[2][0] * this.x + m[2][1] * this.y + m[2][2] * this.z;
    this.x = x;
    this.y = y;
    this.z = z;
  }

  public String toString() {
    return "["+this.x + ", "+this.y+", "+this.z+"]";
  }
}
