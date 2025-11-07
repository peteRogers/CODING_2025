int vibr_Pin = 3;

void setup() {
  pinMode(vibr_Pin, INPUT);
  Serial.begin(9600);
}

void loop() {
  long measurement = pulseIn(vibr_Pin, HIGH);

  if (measurement > 0) {              // vibration detected
    long maxValue = measurement;      // start tracking the highest value
    unsigned long startTime = millis();

    // keep sampling until the knock finishes (no signal for 100 ms)
    while (millis() - startTime < 50) {
      long newMeasurement = pulseIn(vibr_Pin, HIGH, 50000); // timeout = 50 ms
      if (newMeasurement > 0) {
        if (newMeasurement > maxValue) maxValue = newMeasurement;
        startTime = millis(); // reset timer each time vibration continues
      }
    }

    // when no more pulses are detected for 100 ms, print the max value
    Serial.print("0>");
    Serial.print(maxValue);
    Serial.println("<");
    delay(200); // brief pause to avoid detecting same knock twice
  }
}