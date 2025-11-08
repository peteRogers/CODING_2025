#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_ADXL345_U.h>
#include <Smoothed.h> 

/* Assign a unique ID to this sensor at the same time */
Adafruit_ADXL345_Unified accel = Adafruit_ADXL345_Unified(12345);
Smoothed <float> accelX; 

void setup() {
  Serial.begin(9600);
  /* Initialise the sensor */
  if(!accel.begin()){
    
   // Serial.println("Ooops, no ADXL345 detected ... Check your wiring!");
    while(1);
  }

  /* Set the range to whatever is appropriate for your project */
  //accel.setRange(ADXL345_RANGE_16_G);
  //accel.setRange(ADXL345_RANGE_8_G);
  //accel.setRange(ADXL345_RANGE_4_G);
  accel.setRange(ADXL345_RANGE_2_G);
  accelX.begin(SMOOTHED_AVERAGE, 10);
  
  
}

void loop() {
  /* Get a new sensor event */ 
  sensors_event_t event; 
  accel.getEvent(&event);
  
  accelX.add(event.acceleration.x);
  Serial.print("0>")
  Serial.print(accelX.get());
  Serial.println("<");
  delay(5);
}
