#include "arduino.h"
#define MOTOR_DIR_PIN 4
#define MOTOR_SPEED_PIN 5
#define MOTORSPEED 130 // 0 : no movement, 255 : maximum

void motorInit()
{
  pinMode(MOTOR_DIR_PIN, OUTPUT);
  pinMode(MOTOR_SPEED_PIN, OUTPUT);
  analogWrite(MOTOR_SPEED_PIN, 0);
}

void motorStop()
{
  analogWrite(MOTOR_SPEED_PIN, 0);
}

void motorForward()
{
  digitalWrite(MOTOR_DIR_PIN, HIGH);
  analogWrite(MOTOR_SPEED_PIN,MOTORSPEED); 
}

void motorBackward()
{
  digitalWrite(MOTOR_DIR_PIN, LOW);
  analogWrite(MOTOR_SPEED_PIN,MOTORSPEED); 
}
