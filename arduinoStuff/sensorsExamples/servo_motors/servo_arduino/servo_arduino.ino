#include <Servo.h>

Servo myServo;
int input;

void setup() {
  Serial.begin(9600);
  myServo.attach(9);
  
}

void loop() {

   myServo.writeMicroseconds(input);
}

void serialEvent() {
  if(Serial.available()){
      String inString = Serial.readStringUntil('\n');
      
      input = inString.toInt();
      input = map(input, 0, 99, 900, 2100);
      
      
  }
}
