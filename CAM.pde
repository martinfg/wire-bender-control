public class CAM {
  private ArrayList<Instruction> steps;
  private int stepCount = 0;

  public CAM() {
    this.steps = new ArrayList<Instruction>();
  }

  public void addStep(Instruction instruction) {
    this.steps.add(instruction);
  }

  public void listSteps() {
    println("\n=========================");
    for (int i = 0; i < this.steps.size(); i++) {
      int step_num = i + 1;
      if (step_num < 10) {  
        println(" " + step_num + ": " + this.steps.get(i));
      } else {
        println(step_num + ": " + this.steps.get(i));
      }
    }
    println("=========================");
  }

  public Instruction getStep(int index) {
    if (index < steps.size() && index >= 0) {
      return steps.get(index);
    } else {
      return null;
    }
  }
  
  public Instruction popStep() {
    if (stepCount < steps.size()) {
      Instruction step = steps.get(stepCount);
      stepCount ++;
      return step;
    } else {
      stepCount = 0;
      return null;
    }
  }
}
