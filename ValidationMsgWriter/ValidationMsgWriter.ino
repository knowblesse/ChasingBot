#include <EEPROM.h>

String msg = 
  "  ___ _            _           ___      _   \n"
  " / __| |_  __ _ __(_)_ _  __ _| _ ) ___| |_ \n"
  "| (__| ' \\/ _` (_-< | ' \\/ _` | _ \\/ _ \\  _|\n"
  " \\___|_||_\\__,_/__/_|_||_\\__, |___/\\___/\\__|\n"
  "                         |___/              \n"
  " Version : 1.0\n"
  " Date : 22Feb10\n"
  " Validated!\n"
  " Initialization Complete\n";

void setup() {

  Serial.begin(9600);
  unsigned int msg_size = msg.length();
  for(int i = 0; i < msg_size; i++)
  {
    EEPROM.write(i, msg[i]);
  }
  Serial.println("writing complete");
  Serial.println("Read Msg");
  char temp[msg_size];
  for(int i = 0; i < msg_size; i++)
  {
    temp[i] = EEPROM.read(i);
  }
  Serial.println(String(temp));
  Serial.println(msg_size);  

  for(int i = 0; i < msg_size; i++)
  {
    Serial.print(char(EEPROM.read(i)));
  }
}

void loop() {
  // put your main code here, to run repeatedly:

}
