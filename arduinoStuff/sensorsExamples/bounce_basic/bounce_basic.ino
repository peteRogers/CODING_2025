#include <Bounce2.h>

// INSTANTIATE A Bounce OBJECT
Bounce bounce = Bounce();
// SET A VARIABLE TO STORE THE LED STATE
int ledState = LOW;

void setup() {
  // 1) IF YOUR INPUT HAS AN INTERNAL PULL-UP
  bounce.attach(7, INPUT_PULLUP);  // USE INTERNAL PULL-UP
  bounce.interval(5);              // interval in ms
  // LED SETUP
  pinMode(13, OUTPUT);
  digitalWrite(13, ledState);
}

void loop() {
  // Update the Bounce instance (YOU MUST DO THIS EVERY LOOP)
  bounce.update();

  // <Bounce>.changed() RETURNS true IF THE STATE CHANGED (FROM HIGH TO LOW OR LOW TO HIGH)
  if (bounce.changed()) {
    int deboucedInput = bounce.read();

    if (deboucedInput == LOW) {
      ledState = !ledState;        // SET ledState TO THE OPPOSITE OF ledState
      digitalWrite(13, ledState);  // WRITE THE NEW ledState
    }
  }
}
