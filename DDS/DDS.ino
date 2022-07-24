/* RatSinger
 * @Knowblesse 2022
 * Tone Generator using Direct Digital Synthesis (DDS) with AD9833 chip and arduino nano iot 33
 */
#include <Arduino.h>
#include <U8x8lib.h>
#include <SPI.h>
// +---------------------------------------------------------------------------------+
// |                             Digial Pin Configuration                            |
// +---------------------------------------------------------------------------------+
#define PIN_ENCODER1 4
#define PIN_ENCODER2 5
#define PIN_BUTTON 6 // encoder push button
#define PIN_CSON 8 // Input signal for CS on
#define PIN_SOUND_ON 9
#define PIN_VOLUMN 10 // variable registor

// +---------------------------------------------------------------------------------+
// |                   SSD1306 based OLED Screen Configuration                       |
// +---------------------------------------------------------------------------------+
// Default pins for I2C.
// SCL : A5, SDA : A4
U8X8_SSD1306_128X64_NONAME_HW_I2C u8x8(2);

// +---------------------------------------------------------------------------------+
// |                            AD9833 Configuration                                 |
// +---------------------------------------------------------------------------------+
// AD9833 uses SPI communication. Default pins with D3 for Chip Select were used. 
// COPI : 11, SCLK : 13 (CIPO : 12)
#define PIN_CS_AD9833 3
#define CLK 25000000
// +-----+-----+--------------------+---------+---------+---------+----+-------+
// | D15 | D14 |        D13         |   D12   |   D11   |   D10   | D9 |  D8   |
// +-----+-----+--------------------+---------+---------+---------+----+-------+
// |   0 |   0 | 1-Write full 28bit | 0-14LSB | FSELECT | PSELECT |  0 | RESET |
// |     |     | 0-Write 14bit      | 1-14MSB | 0/1     | 0/1     |    |       |
// +-----+-----+--------------------+---------+---------+---------+----+-------+
// +-------+---------+---------+----+------+----+------+----+
// |  D7   |   D6    |   D5    | D4 |  D3  | D2 |  D1  | D0 |
// +-------+---------+---------+----+------+----+------+----+
// | SLEEP | SLEEP12 | OPBITEN |  0 | DIV2 |  0 | MODE |  0 |
// | 0     | 0       | 0       |    | 0    |    | 0    |    |
// +-------+---------+---------+----+------+----+------+----+
static word reset = 0x2100; //   0b0010 0001 0000 0000
static word control = 0x2000; // 0b0010 0000 0000 0000
static word phase = 0xC000; //   0b1100 0000 0000 0000

// functions
word getLSB(double freq);
word getMSB(double freq);
void setFreq(double freq);
void setVolumn(int volumn);
void changeMode(bool isIncrease);
void changeValue(bool isIncrease);

// Button states
bool buttonStatus = false;
bool waitForL1 = false;
bool waitForL2 = false;

// Freq state
bool isSetMode = false;
int freq = 2000;
int volumn = 20;
int rampUp = 0;
bool soundOn = false;

// Min Max Value
int Max_freq = 10000;
int Min_freq = 500;
int Chn_freq = 500;
int Max_volumn = 240;
int Min_volumn = 30;
int Chn_volumn = 5;
int Max_rampUp = 500;
int Min_rampUp = 0;
int Chn_rampUp = 100;

int mode = 0; // 0:Freq, 1:Volumn, 2:Ramp Up, 3:Manual 


void setup() {
  
  Serial.begin(9600);
  SPI.begin();

  // CS Init.
  pinMode(PIN_CS_AD9833, OUTPUT);
  digitalWrite(PIN_CS_AD9833, LOW);

  // Button Init.
  pinMode(PIN_ENCODER1, INPUT);
  pinMode(PIN_ENCODER2, INPUT);
  pinMode(PIN_BUTTON, INPUT_PULLUP);

  // Tone On/Off Init.
  pinMode(PIN_SOUND_ON, OUTPUT);
  digitalWrite(PIN_SOUND_ON, LOW);
  pinMode(PIN_VOLUMN, OUTPUT);
  digitalWrite(PIN_VOLUMN, HIGH);

  // Screen Init.
  u8x8.begin();
  u8x8.setFlipMode(true);
  u8x8.setPowerSave(0);
  u8x8.setFont(u8x8_font_profont29_2x3_f);
  u8x8.drawString(0,0,"Freq :");
  u8x8.drawString(4,4,String(int(freq)).c_str());

  // Load the volumn from the previous setting
}

bool L1;
bool L2;

void loop() {

  //if (Serial.available()){
  //  int a = Serial.parseInt();
  //  if (a == 1){
  //    digitalWrite(PIN_SOUND_ON, HIGH);
  //  }
  //  else if (a==0) {
  //    digitalWrite(PIN_SOUND_ON, LOW);
  //  }
  //  else {
  //    byte data = a;
  //    Serial.println("data transferred");
  //    SPI.beginTransaction(SPISettings(4000000, MSBFIRST, SPI_MODE0));
  //    digitalWrite(PIN_VOLUMN, LOW);
  //    SPI.transfer(0);
  //    SPI.transfer(data);
  //    digitalWrite(PIN_VOLUMN, HIGH);
  //  }
  //}

// +---------------------------------------------------------------------------------+
// |                                 Check Button Click                              |
// +---------------------------------------------------------------------------------+
  if (digitalRead(PIN_BUTTON)==LOW){ // LOW on press
    if(buttonStatus == false){
      if (!isSetMode){
        u8x8.clearLine(0);
        u8x8.clearLine(1);
        u8x8.clearLine(2);
        switch(mode){
          case 0:
            u8x8.drawString(0,0,"Set Freq");
            break;
          case 1:
            u8x8.drawString(0,0,"Set Vol");
            break;
          case 2:
            u8x8.drawString(0,0,"Set Smth");
            break;
          case 3:
            u8x8.drawString(0,0,"Set Man");
            break;
        }
        isSetMode = true;
      }
      else {
        setFreq(freq);
        u8x8.clearLine(0);
        u8x8.clearLine(1);
        u8x8.clearLine(2);
        switch(mode){
          case 0:
            u8x8.drawString(0,0,"Freq :");
            break;
          case 1:
            u8x8.drawString(0,0,"Vol :");
            break;
          case 2:
            u8x8.drawString(0,0,"Smooth :");
            break;
          case 3:
            u8x8.drawString(0,0,"Manual :");
            break;
        }
        isSetMode = false;
      }      
      Serial.println("Button Clicked");
      buttonStatus = true;
    }
  }
  else {
    buttonStatus = false;
  }

// +---------------------------------------------------------------------------------+
// |                               Check Button Rotation                             |
// +---------------------------------------------------------------------------------+
  L1 = !digitalRead(PIN_ENCODER1);
  L2 = !digitalRead(PIN_ENCODER2);

  if(L1 || L2){
    if(L1 && !L2){ 
      if(waitForL2 == false){
        waitForL2 = true;  
      }
      if(waitForL1 == true) { // CW rotation
        if (isSetMode) changeValue(true);
        else changeMode(true);
        waitForL1 = false;
      }
    }
  
    if(!L1 && L2) {
      if(waitForL1 == false) {
        waitForL1 = true;
      }
      if(waitForL2 == true) { // CCW rotation
        if (isSetMode) changeValue(false); 
        else changeMode(false);
        waitForL2 = false;
      }
    }
  }
  else {
    waitForL1 = false;
    waitForL2 = false;
  }

}
// update mode
void changeMode(bool isIncrease) {
  if (isIncrease) {
    if (mode < 3) mode++;
    else mode = 0;
  }
  else {
    if (mode > 0) mode--;
    else mode = 3;
  }

  // clear all lines
  u8x8.clear();
  switch(mode){
    case 0:
      u8x8.drawString(0,0,"Freq :");
      u8x8.drawString(4,4,String(int(freq)).c_str());
      break;
    case 1:
      u8x8.drawString(0,0,"Vol :");
      u8x8.drawString(4,4,String(int(volumn)).c_str());
      break;
    case 2:
      u8x8.drawString(0,0,"Smooth :");
      u8x8.drawString(4,4,String(int(rampUp)).c_str());
      break;
    case 3:
      u8x8.drawString(0,0,"Manual :");
      if (soundOn) u8x8.drawString(4,4,"ON");
      else u8x8.drawString(4,4,"OFF");
      
      break;
  }
}

void changeValue(bool isIncrease) {
  // clear value
  u8x8.clearLine(3);
  u8x8.clearLine(4);
  u8x8.clearLine(5);
  u8x8.clearLine(6);
  u8x8.clearLine(7);

  switch(mode){
    case 0:
      if (isIncrease) freq = min(freq + Chn_freq, Max_freq);
      else freq = max(freq - Chn_freq, Min_freq); 
      setFreq(freq);
      u8x8.drawString(4,4,String(int(freq)).c_str());
      break;
    case 1:
      if (isIncrease) volumn = min(volumn + Chn_volumn, Max_volumn);
      else volumn = max(volumn - Chn_volumn, Min_volumn); 
      setVolumn(volumn);
      u8x8.drawString(4,4,String(int(volumn)).c_str());
      break;
    case 2:
      if (isIncrease) rampUp = min(rampUp + Chn_rampUp, Max_rampUp);
      else rampUp = max(rampUp - Chn_rampUp, Min_rampUp); 
      u8x8.drawString(0,0,"Smooth :");
      u8x8.drawString(4,4,String(int(rampUp)).c_str());
      break;
    case 3:
      soundOn = !soundOn;
      u8x8.drawString(0,0,"Manual :");
      if (soundOn) u8x8.drawString(4,4,"ON");
      else u8x8.drawString(4,4,"OFF");
      digitalWrite(PIN_SOUND_ON, soundOn);
      break;
  }
}

// update frequency screen 
void updateFreqScreen(double freq){
  u8x8.clearLine(3);
  u8x8.clearLine(4);
  u8x8.clearLine(5);
  u8x8.clearLine(6);
  u8x8.clearLine(7);
  u8x8.drawString(4,4,String(int(freq)).c_str());
}
// set frequency registor
void setFreq(double freq){
  SPI.beginTransaction(SPISettings(40000000, MSBFIRST, SPI_MODE2));
  Serial.print("Set Freq : ");
  Serial.println(freq);
  word lsb = getLSB(freq);
  word msb = getMSB(freq);
  Serial.print("LSB :");
  Serial.println(lsb, HEX);
  Serial.print("MSB :");
  Serial.println(msb, HEX);
  // Start Writing
  digitalWrite(PIN_CS_AD9833, LOW);
  SPI.transfer16(reset); // Reset 
  digitalWrite(PIN_CS_AD9833, HIGH);
  digitalWrite(PIN_CS_AD9833, LOW);
  SPI.transfer16(lsb);
  digitalWrite(PIN_CS_AD9833, HIGH);
  digitalWrite(PIN_CS_AD9833, LOW);
  SPI.transfer16(msb);
  digitalWrite(PIN_CS_AD9833, HIGH);
  digitalWrite(PIN_CS_AD9833, LOW);
  SPI.transfer16(phase);
  digitalWrite(PIN_CS_AD9833, HIGH);
  digitalWrite(PIN_CS_AD9833, LOW);
  SPI.transfer16(control);
  digitalWrite(PIN_CS_AD9833, HIGH);
}

// Calculate Frequency setting words
word getLSB(double freq)
{
  int freqReg = int(round(freq*pow(2,28)/CLK));
  return (freqReg & 0b11111111111111) + 0b0100000000000000; 
}
word getMSB(double freq)
{
  int freqReg = int(round(freq*pow(2,28)/CLK));
  return (freqReg >> 14) + 0b0100000000000000;
}

void setVolumn(int volumn){
  byte data = volumn;
  SPI.beginTransaction(SPISettings(4000000, MSBFIRST, SPI_MODE0));
  digitalWrite(PIN_VOLUMN, LOW);
  SPI.transfer(0);
  SPI.transfer(data);
  digitalWrite(PIN_VOLUMN, HIGH);
}
  
