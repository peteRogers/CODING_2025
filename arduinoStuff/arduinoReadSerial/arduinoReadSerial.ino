#include <Servo.h>

Servo myServo;
String inputLine = "";
int servopos = 20;

const int SERVO_PIN = 9;

void setup() {
  Serial.begin(9600);
  myServo.attach(SERVO_PIN);
  myServo.write(90); // start in middle
}

void loop() {
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
  myServo.write(servopos);
}

void parseLine(String line) {
  int separator = line.indexOf(':');
  if (separator == -1) return;

  int id = line.substring(0, separator).toInt();
  int value = line.substring(separator + 1).toInt();

  // Optional: only react to ID 0
  if (id == 0) {
    servopos = constrain(value, 0, 180);
    Serial.print("0:");
    Serial.println(value);
  }
}