int x = 0;
void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
}

void loop() {
  for(int i = 0; i < 9; i ++){
    Serial.print(i);
    Serial.print(">");
    if(x == i){
      Serial.print(1);
    }else{
      Serial.print(0);
    }
    Serial.print("<");
  }
  Serial.println("");
  x = x + 1;
  if(x > 8){
    x = 0;
  }
  delay(500);
}
