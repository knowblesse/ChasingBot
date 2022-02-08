#include <SD.h>
#include <pcmConfig.h>
#include <pcmRF.h>
#include <TMRpcm.h>
#define SD_ChipSelectPin 53

#define MotorDirectionPin 4
#define MotorSpeedPin 5
#define MotorSpeed 150 // 0 : no movement, 255 : maximum
#define SpeakerPin 12
// Motor Functions Init.
void motorInit();
void motorStop();
void motorForward();
void motorBackward();
TMRpcm tmrpcm;
String musicFileName;
void setup() {
  // put your setup code here, to run once:
  motorInit();
  tmrpcm.speakerPin = SpeakerPin;
  if (!SD.begin(SD_ChipSelectPin)) {  // see if the card is present and can be initialized:
    Serial.println("No Sdcard");
    return;   // don't do anything more if not
  }
  else Serial.println("Yes SDcard");  
  musicFileName = "sin1.wav";
}

void loop() {
  // put your main code here, to run repeatedly:
  tmrpcm.play(musicFileName.c_str());
  delay(3000);
  motorForward();
  delay(5000);
  motorBackward();
  delay(5000);
  tmrpcm.disable();
  delay(2000);
}


void motorInit(){
  pinMode(MotorDirectionPin, OUTPUT);
  pinMode(MotorSpeedPin, OUTPUT);
  analogWrite(MotorSpeedPin, 0);
}

void motorStop(){
  analogWrite(MotorSpeedPin, 0);
}

void motorForward(){
  digitalWrite(MotorDirectionPin, HIGH);
  analogWrite(MotorSpeedPin,MotorSpeed); 
}

void motorBackward(){
  digitalWrite(MotorDirectionPin, LOW);
  analogWrite(MotorSpeedPin,MotorSpeed); 
}
