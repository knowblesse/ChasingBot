/*
chasingbot.ino
Ver 1.0.2
@Knowblesse
Initial Commit : 22FEB07
Current Edit : 22AUG10
*/

// Pin Numbers
#define SPEAKER_PIN 11
#define BT_RX 31
#define BT_TX 30
#define PIN_TONE_GEN 45

//Library
#include <SoftwareSerial.h>
#include <EEPROM.h>
#include "motorDriver.h"

SoftwareSerial BT(BT_RX, BT_TX);

// Welcome Message
#define MSGSIZE 1
void printWelcomeMsg();

// Command sent to the ANY-MAZE
char letter_cson = 'q';
char letter_csoff = 'w';
char letter_EXStart = 's';
char letter_EXEnd = 'e';

enum ExpMode
{
  CONDITIONING,
  EXTINCTION,
  RETENTION
};

struct ExpParam
{
  double habituation_time;
  double cs_duration;
  double us_onset;
  double us_duration_min;
  double us_duration_max;
  double isi_duration_min;
  double isi_duration_max;
  int num_trial;
};

struct PersonalParam
{
  ExpParam cndParam;
  ExpParam extParam; //ignores us_onset, us_duration
  ExpParam retParam; //ignores us_onset, us_duration
};

int mode; // Experiment Mode
PersonalParam pParam; // Personal Parameter
ExpParam param; // Experiment Parameter

void setup()
{
  /********************************************/
  /*                Initialize                */
  /********************************************/
  // Init. Serial Comm.
  Serial.begin(115200); // For Debug
  Serial1.begin(115200); // SmartPhone 
  BT.begin(115200); // ANY-MAZE

  // Init. Tone Gen
  pinMode(PIN_TONE_GEN, OUTPUT);
  digitalWrite(PIN_TONE_GEN, LOW);
  
  // Init. Motor
  motorInit();

  // Wait for key input
  while(true)
  {
    if(Serial1.available() > 0 && char(Serial1.read()) >= 65) break;
  }
  randomSeed(millis());
  printWelcomeMsg();
  
  /********************************************/
  /*             Load User Profile            */
  /********************************************/
  bool invalidInput = true;
  Serial1.println("Who are you?");
  Serial1.println("a. KI&YB   b. BM    c. QuickTestMode");
  while(invalidInput)
  {
    if(Serial1.available())
    {
      switch(char(Serial1.read()))
      {
        /* Change this part for a new parameter   */
        /* The unit for the time parameter is sec */
        /*                BEGIN                   */
        case 'a':
          Serial1.println("Choi lab 2.5nd & Crazy Rabbit");
          
          pParam.cndParam.habituation_time = 300;
          pParam.cndParam.cs_duration = 10;
          pParam.cndParam.us_onset = 7.5; 
          pParam.cndParam.us_duration_min = 2.5;
          pParam.cndParam.us_duration_max = 2.5;
          pParam.cndParam.isi_duration_min = 50;
          pParam.cndParam.isi_duration_max = 50;
          pParam.cndParam.num_trial = 5;

          pParam.extParam.habituation_time = 300;
          pParam.extParam.cs_duration = 10;
          pParam.extParam.isi_duration_min = 50;
          pParam.extParam.isi_duration_max = 50;
          pParam.extParam.num_trial = 30;

          pParam.retParam.habituation_time = 300;
          pParam.retParam.cs_duration = 10;
          pParam.retParam.isi_duration_min = 50;
          pParam.retParam.isi_duration_max = 50;
          pParam.retParam.num_trial = 5;

          invalidInput = false;
          break;

        case 'b':
          Serial1.println("Jay Park in the lab");
          
          pParam.cndParam.habituation_time = 1;
          pParam.cndParam.cs_duration = 0;
          pParam.cndParam.us_onset = 0;
          pParam.cndParam.us_duration_min = 3;
          pParam.cndParam.us_duration_max = 9;
          pParam.cndParam.isi_duration_min = 10;
          pParam.cndParam.isi_duration_max = 31;
          pParam.cndParam.num_trial = 8;

          pParam.extParam.habituation_time = 1;
          pParam.extParam.cs_duration = 0;
          pParam.extParam.isi_duration_min = 10;
          pParam.extParam.isi_duration_max = 31;
          pParam.extParam.num_trial = 30;

          pParam.retParam.habituation_time = 1;
          pParam.retParam.cs_duration = 0;
          pParam.retParam.isi_duration_min = 10;
          pParam.retParam.isi_duration_max = 31;
          pParam.retParam.num_trial = 1;

          invalidInput = false;
          break;
        /*                   END                */

        case 'c':
          Serial1.println("Quick Test Mode");
          
          pParam.cndParam.habituation_time = 10;
          pParam.cndParam.cs_duration = 10;
          pParam.cndParam.us_onset = 8;
          pParam.cndParam.us_duration_min = 2;
          pParam.cndParam.us_duration_max = 5;
          pParam.cndParam.isi_duration_min = 10;
          pParam.cndParam.isi_duration_max = 20;
          pParam.cndParam.num_trial = 10;

          pParam.extParam.habituation_time = 10;
          pParam.extParam.cs_duration = 10;
          pParam.extParam.isi_duration_min = 10;
          pParam.extParam.isi_duration_max = 10;
          pParam.extParam.num_trial = 10;

          pParam.retParam.habituation_time = 10;
          pParam.retParam.cs_duration = 10;
          pParam.retParam.isi_duration_min = 10;
          pParam.retParam.isi_duration_max = 10;
          pParam.retParam.num_trial = 5;
          
          invalidInput = false;
          break;

        default:
          Serial1.println("Wrong Input");
          Serial1.println("Who are you?");
          Serial1.println("a. KI&YB   b. BM    c. QuickTestMode");
          break;
      }
    }
  }
}

void loop()
{
  /********************************************/
  /*            Setup New Experiment          */
  /********************************************/
  bool invalidInput = true;
  Serial1.println("Which condition do you want?");
  Serial1.println("a. Conditioning   b. Extinction   c. Retention/Renewal");
  while(invalidInput)
  {
    if(Serial1.available())
    {
      switch(char(Serial1.read()))
      {
        case 'a':
          Serial1.println("Conditioning");
          mode = CONDITIONING;
          param = pParam.cndParam;
          invalidInput = false;
          break;

        case 'b':
          Serial1.println("Extinction");
          mode = EXTINCTION;
          param = pParam.extParam;
          invalidInput = false;
          break;

        case 'c':
          Serial1.println("Retention");
          mode = RETENTION;
          param = pParam.retParam;
          invalidInput = false;
          break;

        default:
          Serial1.println("Wrong Input");
          Serial1.println("Which condition do you want?");
          Serial1.println("a. Conditioning   b. Extinction   c. Retention/Renewal");
          break;
      }
    }
  }

  /********************************************/
  /*             Start Experiment             */
  /********************************************/
  Serial1.println("Press 'a' to start the experiment");
  while(true)
    {
      if (Serial1.available() && (char(Serial1.read()) == 'a'))
      {
        Serial1.println("Test Start");
        BT.write(letter_EXStart);
        break;
      }
    }

  /********************************************/
  /*          Main Experiment Loop            */
  /********************************************/

  bool emergency_stop = false;

  Serial1.println("Hab Start");
  long hab_onset_time_ms = millis();
  while((millis() - hab_onset_time_ms) < param.habituation_time*1000)
  {
    // emergency stop
    if (Serial1.available() && (char(Serial1.read()) == 's'))
    {
      Serial1.println("Emergency Stop");
      BT.write(letter_EXEnd);
      emergency_stop = true;
      break;
    }
  }
  Serial1.println("Hab End");

  long trial_onset_time_ms;
  long time_from_trial_onset_ms;
  long us_duration_ms;
  long iti_duration_ms;

  bool isITI = false; 
  bool isCSOn = false;
  bool isUSArmed; // if true, US is present in this trial, but not yet executed
  bool isUSOn = false;

  for(int curr_trial=1; curr_trial<= param.num_trial; curr_trial++)
  {
    if(emergency_stop) break;
    Serial1.println("+-------------------------------------------------+");
    Serial1.print("Trial : ");
    Serial1.print(curr_trial);
    
    // Setup Trial Variables
    us_duration_ms = random(param.us_duration_min*1000, param.us_duration_max*1000);
    iti_duration_ms = random(param.isi_duration_min*1000, param.isi_duration_max*1000);

    // if cs_duration is more than zero, turn on the sound
    // if cs_duration is zero, then skip the CS presentation
    if(param.cs_duration > 0)
    {
      BT.write(letter_cson);
      Serial1.print(" CS ");
      Serial1.print(param.cs_duration,2);
      Serial1.print("s ");
      digitalWrite(PIN_TONE_GEN, HIGH);
      isCSOn = true;
    }

    // if the Experiment Mode is Conditioning, US is armed
    // if the Experiment Mode is Extinction or Retention, US is not armed
    if (mode == CONDITIONING)
    {
      isUSArmed = true;
      Serial1.print("US ");
      Serial1.print(param.us_onset);
      Serial1.print("-");
      Serial1.print(us_duration_ms/1000,2);
      Serial1.println("s");
    }
    else
    {
      isUSArmed = false;
      Serial1.println("US X");
    }

    trial_onset_time_ms = millis();

    while(true)
    {
      time_from_trial_onset_ms = millis() - trial_onset_time_ms;

      // check if cs_duration has reached
      if(isCSOn && (time_from_trial_onset_ms > param.cs_duration*1000))
      {
        BT.write(letter_csoff);
        digitalWrite(PIN_TONE_GEN, LOW);
        isCSOn = false;
      }

      // if US is armed, check if us_onset has reached
      if(isUSArmed && (time_from_trial_onset_ms >= param.us_onset*1000))
      {
        if(random(0,100) < 50) motorForward();
        else motorBackward();
        isUSArmed = false;
        isUSOn = true;
      }

      // if US is on, check if us_duration has reached
      if(isUSOn && (time_from_trial_onset_ms > (param.us_onset*1000 + us_duration_ms)))
      {
        motorStop();
        isUSOn = false;
      }

      // if everything is finished during this trial, exit the while loop
      if(!isCSOn && !isUSArmed && !isUSOn) break;

      // emergency stop
      if (Serial1.available() && (char(Serial1.read()) == 's'))
      {
        Serial1.println("Emergency Stop");
        BT.write(letter_EXEnd);
        emergency_stop = true;
        break;
      }
    }

    Serial1.print("ITI start. Current ITI : ");
    Serial1.print(iti_duration_ms);
    Serial1.println(" ms");
    long iti_onset_time_ms = millis();
    while((millis() - iti_onset_time_ms) < iti_duration_ms)
    {
      // emergency stop
      if (Serial1.available() && (char(Serial1.read()) == 's'))
      {
        Serial1.println("Emergency Stop");
        BT.write(letter_EXEnd);
        emergency_stop = true;
        break;
      }
    }
    Serial1.println("ITI end");
  }
  Serial1.println("Experiment Done");
  BT.write(letter_EXEnd);
}

void printWelcomeMsg()
{
  for(int i = 0; i < MSGSIZE; i++)
  {
    Serial1.print(char(EEPROM.read(i)));
  }
}
