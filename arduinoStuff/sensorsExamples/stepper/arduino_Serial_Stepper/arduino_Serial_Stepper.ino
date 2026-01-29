#include <Servo.h>

#include <Unistep2.h>
Unistep2 stepper(8,9,10,11, 4096, 800);
int stepperpos;
String inputLine = "";

void setup() {
  Serial.begin(9600);
  pinMode(13, OUTPUT);
}

void loop() {
 stepper.run();
 if(stepper.stepsToGo() == 0){
  stepper.stop();
 }
}


//receiving serial messages
void serialEvent() {
    while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n') {
      parseLine(inputLine);
      inputLine = "";
    } 
    else if (c != '\r') {
      inputLine += c;
    }
  }
    stepper.moveTo(stepperpos);
  }


void parseLine(String line) {
  int separator = line.indexOf(':');
  if (separator == -1) return;

  int id = line.substring(0, separator).toInt();
  int value = line.substring(separator + 1).toInt();

  // Optional: only react to ID 0
  if (id == 0) {
    stepperpos = constrain(value, 0, 4096);
    Serial.print("0:");
    Serial.println(value);
  }
}
