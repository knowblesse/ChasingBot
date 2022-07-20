/* RatSinger
 * @Knowblesse 2022
 * Tone Generator using Direct Digital Synthesis (DDS) with AD9833 chip and arduino nano iot 33
 */
#include <Arduino.h>
#include <U8x8lib.h>
#include <SPI.h>
// +---------------------------------------------------------------------------------+
// |                         Encoder Switch Configuration                            |
// +---------------------------------------------------------------------------------+
#define PIN_ENCODER1 4
#define PIN_ENCODER2 5
#define PIN_BUTTON 6

// +---------------------------------------------------------------------------------+
// |                        Variable Registor Configuration                          |
// +---------------------------------------------------------------------------------+
#define PIN_CS_VR 8

// +---------------------------------------------------------------------------------+
// |                            Optoswitch Configuration                             |
// +---------------------------------------------------------------------------------+
#define PIN_OPTO 9

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
void updateFreq(double freq);
void setFreq(double freq);

// Button states
bool buttonStatus = false;
bool waitForL1 = false;
bool waitForL2 = false;

// Freq state
bool changeFreq = false;
int freq = 2000;


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
  pinMode(PIN_OPTO, OUTPUT);
  digitalWrite(PIN_OPTO, LOW);
  pinMode(PIN_CS_VR, OUTPUT);
  digitalWrite(PIN_CS_VR, HIGH);

  // Screen Init.
  u8x8.begin();
  u8x8.setPowerSave(0);
  u8x8.setFont(u8x8_font_profont29_2x3_f);
  u8x8.drawString(0,0,"Freq :");
  u8x8.drawString(4,4,String(int(freq)).c_str());
}

void loop() {

  if (Serial.available()){
    int a = Serial.parseInt();
    if (a == 1){
      digitalWrite(PIN_OPTO, HIGH);
    }
    else if (a==0) {
      digitalWrite(PIN_OPTO, LOW);
    }
    else {
      byte data = a;
      Serial.println("data transferred");
      SPI.beginTransaction(SPISettings(4000000, MSBFIRST, SPI_MODE0));
      digitalWrite(PIN_CS_VR, LOW);
      SPI.transfer(0);
      SPI.transfer(data);
      digitalWrite(PIN_CS_VR, HIGH);
    }
  }
  
  // Check Button
  if (digitalRead(PIN_BUTTON)==LOW){ // LOW on press
    if(buttonStatus == false){
      if (!changeFreq){
        u8x8.clearLine(0);
        u8x8.clearLine(1);
        u8x8.clearLine(2);
        u8x8.drawString(0,0,"Set Freq");
        changeFreq = true;
      }
      else {
        setFreq(freq);
        u8x8.clearLine(0);
        u8x8.clearLine(1);
        u8x8.clearLine(2);
        u8x8.drawString(0,0,"Freq :");
        changeFreq = false;
      }      
      Serial.println("Button Clicked");
      buttonStatus = true;
    }
  }
  else {
    buttonStatus = false;
  }

  bool L1 = !digitalRead(PIN_ENCODER1);
  bool L2 = !digitalRead(PIN_ENCODER2);

  if(L1 || L2){
    if(L1 && !L2){ 
      if(waitForL2 == false){
        waitForL2 = true;  
      }
      if(waitForL1 == true) {
        if (changeFreq){
          freq = min(20000, freq+500);
          updateFreqScreen(freq);
        }
        Serial.println("L1");
        waitForL1 = false;
      }
    }
  
    if(!L1 && L2) {
      if(waitForL1 == false) {
        waitForL1 = true;
      }
      if(waitForL2 == true) {
        if (changeFreq){
          freq = max(500, freq-500);
          updateFreqScreen(freq); 
        }
        Serial.println("L2");
        waitForL2 = false;
      }
    }
  }
  else {
    waitForL1 = false;
    waitForL2 = false;
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
