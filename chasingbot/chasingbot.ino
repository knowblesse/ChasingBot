/*
chasingbot.ino
22FEB07
---------------------------------
       Required Librarys
---------------------------------
SoftwareSerial - Default 
SD - Defulat
TMRpcm - Install from library manager

---------------------------------
             Warings
---------------------------------
Music file must have following format
- unsigned 8bit pcm
- 8~32kHz
- mono
*/

// Pin Numbers
// SD card DI - 51
// SD card DO - 50
// SD card CLK - 52
#define SD_PIN 53
#define SPEAKER_PIN 11
#define MOTOR_DIR_PIN 4
#define MOTOR_SPEED_PIN 5
#define BT_RX 31
#define BT_TX 30

//TMRpcm Librarys (Play music)
#include <pcmRF.h>
#include <TMRpcm.h>
#include <pcmConfig.h>
#include <SoftwareSerial.h>
#include <SD.h>

SoftwareSerial BT(BT_RX, BT_TX);
TMRpcm tmrpcm;

// Motor Variables
#define MOTORSPEED 150 // 0 : no movement, 255 : maximum

// Motor Functions Init.
void motorInit();
void motorStop();
void motorForward();
void motorBackward();

//for test
char letter_cson = 'q';
char letter_csoff = 'w';
char letter_EXStart = 's';
char letter_EXEnd = 'e';

unsigned long time = 0;
long hab = -1; //habituation time
int hstate = 0;
int test = 0;
int prob = 0;
int isi_a = -1;     //CS와 다음 CS 사이의 시간 
int isi_b = 0; //interstimulus end
long int isi = 0;
int prob_a = 1;     //로봇 이동 방향(확률) 
int prob_b = 3;
int trial_set = -1; // how many trial do?
int speed1 = -1;
long us_start = -1;
long us_work = -1;
int us_work_1 = 3;
int us_work_2 = 9;

String musicFileName;

int ran1;
int ran2;

int rep = 1;
int rep2 = 1;
//for question
char person_state = 0;
char test_state = 0;
char start_state = 0;
char default_state = 0;

int KI_Mode = 0;
int BM_Mode = 0;

unsigned long starttime;

String serial_input=""; //받는 문자열

unsigned long pre_time = 0;
unsigned long cur_time = 0;

void setup()
{
  // Init. Serial Comm.
  Serial.begin(115200); // For Debug
  Serial1.begin(115200); // SmartPhone 
  BT.begin(115200); // ANY-MAZE

  // Init. Motor
  motorInit();

  // Init. Speaker
  tmrpcm.speakerPin = SPEAKER_PIN; 

  // Init. SD Card
  while (!SD.begin(SD_PIN)) 
  {
    Serial.println("No SD card");
    delay(1000);
  }
}

void loop()
{
  int x, delay_en;

  if(person_state == 0){
    Serial1.println("Who are you?");
    Serial1.println("a. KI&YB   b. BM    d. Debug");
  }

  while(person_state != 1)
  {
    while(Serial1.available())
    {
      char val = (char) Serial1.read();
      if(val != -1)
      {
        switch(val)
        {
          case 'a':
            Serial1.println("Choi lab 2.5nd & Crazy Rabbit");
            speed1 = 2000;
            hab = 120000;
            isi_a = 50;
            isi_b = 50;
            trial_set = 5;
            us_start = 7500;
            us_work = 2500;
            KI_Mode = 1;
            musicFileName = "sin1.wav";

            break;

          case 'b':
            Serial1.println("Jay Park in the lab");
            BM_Mode = 1;
            speed1 = 2000;
            hab = 1000;
            isi_a = 10;
            isi_b = 31;
            us_start = 0;
            us_work = random(us_work_1, us_work_2);
            us_work = us_work * 1000;
            trial_set = 8;
            musicFileName = "sin1.wav";
            ran1 = millis();

            break;

          case 'd':
            test_state = 1;
            default_state = 1;

            break;
        }
        val = -1;
        person_state = 1;
      }
    }
  }
  if(test_state == 0){
    Serial1.println("Which condition do you want?");
    Serial1.println("a. Conditioning   b. Extinction   c. Retention/Renwal");
  }


  while(test_state != 1)
  {
    while(Serial1.available())
    {
      char val = (char) Serial1.read();
      if(val != -1)
      {

        switch(val)
        {
          case 'a':
            Serial1.println("conditioning");
            break;

          case 'b':
            Serial1.println("Extinction");
            speed1 = 0;
            trial_set = 30;
            break;

          case 'c':
            Serial1.println("Retention");
            speed1 = 0;
            trial_set = 1;
            us_start = 10000;
            us_work = 1; //그대로 두세용 소리 뒤에 US delay임

            if(KI_Mode == 1){
              Serial1.println("KI_Mode");
              speed1 = 0;
              trial_set = 5;
            }
            break;


        }
      }
      test_state = 1;
      val = -1;
    }
  }

  if(default_state == 1)
  {
    Serial1.println("Do NOT type in before the question completes");
    Serial1.println("Robot speed?");

    while(speed1 == -1){
      while(Serial1.available()){
        serial_input = Serial1.readStringUntil('\n');
        if(serial_input != -1){
          speed1 = serial_input.toInt();
          Serial1.println(speed1);
        }
      }
    }

    Serial1.println("Habituation time?");
    while(hab == -1){
      while(Serial1.available()){
        serial_input = Serial1.readStringUntil('\n');
        if(serial_input != -1){
          hab = (serial_input.toInt())*1000;
          Serial.println(hab/1000);
        }
      }
    }

    Serial1.println("ISI duration?");
    while(isi_a == -1){
      while(Serial1.available()){
        serial_input = Serial1.readStringUntil('\n');
        if(serial_input != -1){
          isi_a = (serial_input.toInt());
          isi_b = (serial_input.toInt()+1);
          Serial1.println(isi_a);          
        }
      }
    }

    Serial1.println("How many trials?");
    while(trial_set == -1){
      while(Serial1.available()){
        serial_input = Serial1.readStringUntil('\n');
        if(serial_input != -1){
          trial_set = serial_input.toInt();
          Serial1.println(trial_set);
        }
      }
    }

    Serial1.println("When does the US start after the CS onset?");
    while(us_start == -1){
      while(Serial1.available()){
        serial_input = Serial1.readStringUntil('\n');
        if(serial_input != -1){
          us_start = (serial_input.toInt())*1000;
          Serial1.println(us_start);
        }
      }
    }

    Serial1.println("US duration?");
    while(us_work == -1){
      while(Serial1.available()){
        serial_input = Serial1.readStringUntil('\n');
        if(serial_input != -1){
          us_work = (serial_input.toInt())*1000;
          Serial1.println(us_work);
        }
      }
    }

    Serial1.println("Which music do you want to play?");
    Serial1.println("a. Sin   b. whitenoise   c. 4season");
    while(musicFileName == ""){
      while(Serial1.available()){
        char val = (char) Serial1.read();
        switch(val){
          case 'a':
            musicFileName = "sin1.wav";
            break;

          case 'b':
            musicFileName = "whitenoise.wav";
            break;

          case 'c':
            musicFileName = "season4.wav";
            break; 
        }
        Serial1.println(musicFileName);
      }
    }

    //music = "sin1.wav";
    default_state = 0;
  }

  if(start_state == 0)
  {
    Serial1.println("Now what?");
    Serial1.println("a. start   b. reset   c. music");
  }

  while(start_state != 1)
  {
    while(Serial1.available())  //mySerial에 전송된 값이 있으면
    {
      char val = (char) Serial1.read();
      if(val != -1)
      {
        switch(val)
        {
          case 'a':
            Serial1.println("test start");
            test = 1;
            starttime = millis();
            BT.write(letter_csoff);
            BT.write(letter_EXStart);
            ran2 = millis();
            start_state = 1;
            break;

          case 'b':
            Serial1.println("option reset");
            person_state = 0;
            test_state = 0;
            speed1 = -1;
            isi_a = -1;
            hab = -1;
            us_start = -1;
            us_work = -1;
            trial_set = -1; 
            musicFileName = "";
            start_state = 1;
            break;
        }

      }
    }
  }

  hstate = 0;
  int trial = 0;

  int initial_state = 0;
  int seed = 0;

  while(test == 1)
  {
    time = millis() - starttime;
    if(BM_Mode == 1){
      if(initial_state == 0){
        seed = ((ran2 - ran1) % 2 )+ 1;
        initial_state = 1;
      }
      else{
        seed = (seed % 2) + 1;      
      }
      prob = seed;
    }
    else{
      prob = random(prob_a, prob_b);
    }
    isi = random(isi_a, isi_b);
    isi = isi * 1000;
    trial = trial + 1;
    if(hstate == 0)
    {
      Serial.print(time);
      Serial.println("Hab Start");
      Serial1.println("Hab Start");
      delay(hab);
      hstate = 1;
      Serial1.println("Hab End");
    }

    Serial.print(time);
    Serial1.println(trial);

    tmrpcm.disable();
    if(trial <= trial_set)
    {
      time = millis() - starttime;
      Serial.print(time);
      Serial1.println("CS on");
      if(BM_Mode == 1){
        Serial1.println("BM_Mode");
        us_work = random(3, 9);
        us_work = us_work * 1000;
      }

      tmrpcm.play(musicFileName.c_str());

      BT.write(letter_cson);

      delay(us_start);

      time = millis() - starttime;
      Serial.print(time);

      if(prob == 1)
      {
        Serial1.println("US Forward");
        motorForward();
      }
      if(prob == 2)
      {
        Serial1.println("US Backward");
        motorBackward();
      }

      //Serial1.println(us_work/1000);
      delay(us_work);

      time = millis() - starttime;
      Serial.print(time);
      Serial1.println("CS US off");
      tmrpcm.disable();

      BT.write(letter_csoff);

      motorStop();

      time = millis() - starttime;
      Serial.print(time);
      Serial1.println("ITI start");
      Serial1.println(isi/1000);
      delay(isi);
      Serial1.println("ITI end\n");

    }

    if(trial == trial_set)
    {
      Serial.print(time);
      Serial1.println("End Test\n");

      motorStop();
      test = 0;
      BT.write(letter_EXEnd);
    }
  }

  test = 0;
  start_state = 0;

}

// Motor Functions
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
