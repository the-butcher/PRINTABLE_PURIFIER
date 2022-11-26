#include "U8glib.h" // display
#include "DHT.h" // temperature and humidity
#include <SoftwareSerial.h>

// port of dht sensor (digital)
#define PORT_____SENSOR_DHT 4

// port of potentiometer (analog)
#define PORT__POTENTIOMETER A0
// port of vibration sensor (analog)
#define PORT______VIBRATION A1

// ports of dust sensor (digital)
#define PORT_SENSOR_DUST_RX 3
#define PORT_SENSOR_DUST_TX 2

// ports of motor controller (digital, 9 is pwm)
// ports 9 and 10 appear to be connected by the underlying timer, so 10 should probably be left alone
#define PORT____MOTOR_SPEED 9
#define PORT____MOTOR_DIR_1 8
#define PORT____MOTOR_DIR_2 7

// initialize display (see documentation at https://www.velleman.eu/products/view/?id=460516)
U8GLIB_SSD1306_128X64 u8g(U8G_I2C_OPT_NO_ACK);

// initialize dust sensor
SoftwareSerial SENSOR_DUST = SoftwareSerial(PORT_SENSOR_DUST_RX, PORT_SENSOR_DUST_TX);
char BUFFER_SENSOR_DUST[128];

// initialize dht sensor
DHT SENSOR_DHT(PORT_____SENSOR_DHT, DHT22); // DHT22 is a global coming with DHT.h include

// vertical position of PM2.5 value on display
const int DISPLAY_TEXT_A = 19;
// vertical position of °C and %RH value on display
const int DISPLAY_TEXT_B = 63;

const int DISPLAY_LINE_A = 33;
const int DISPLAY_LINE_B = 39;
const int DISPLAY_LINE_C = 45;

// used for formatting strings with leading zeros
const String STRING_PAD_BLANK_4 = "   ";
const String STRING_PAD_BRACK_4 = "          ";
char CHAR_BUF[32];

// current value of the potentiometer (on a range from 0-1023)
int valuePoti = 0;

// current PM2.5 sensor value
int valueIndexPm25 = 0;
int valuePm25 = 0;
int valueArrayPm25[10];

// current DHT sensor values
int valueHumidity = 0;
float valueTemperature = 0;

int valueMotorMin = 310;
int valueMotorMax = 511;

// current motor value (on a range from 0-1023), needs to be mapped to valueMotorMin (as of calibration) and valueMotorMax
int valueMotor = 0;

// current vibration value
int valueIndexVibr = 0;
int valueVibr = 0;
int valueArrayVibr[10];

void setup(void) {

  // set baud rate for serial monitor (for development)
  Serial.begin(9600);

  // does nothing
  setupPotentionmeter(); 
  // does nothing
  setupSensorVibration(); 

  // have the display ready to show calibration info
  setupDisplay();

  // get the dust sensor up
  setupSensorDust();
  setupSensorDht();

  // setup and calibrate motor by measuring vibration
  setupMotor();
  
}

/*
 * setup anything potentiometer related (nothing currently)
 */
void setupPotentionmeter() {
  // do nothing
}

/*
 * setup anything vibration related (nothing currently)
 */
void setupSensorVibration() {
  // do nothing
}

/*
 * start the display
 */
void setupDisplay() {
  u8g.setRot180(); // flip screen
  u8g.setColorIndex(1); // u8g.getMode() = U8G_MODE_BW 
}

void setupMotor() {

  // Mehr Infos: https://arduino-projekte.webnode.at/registerprogrammierung/fast-pwm/  
  // Löschen der Timer/Counter Control Register A und B
  TCCR1A = 0;
  TCCR1B = 0;

  // TODO :: re-check values from documentation
  TCCR1A |= (1 << WGM11); 
  TCCR1B |= (1 << WGM12);

  // Vorteiler auf 1 setzen (?)
  TCCR1B |= (1 << CS10);
  
  // Nichtinvertiertes PWM-Signal setzen
  TCCR1A |= (1 << COM1A1);

   // PWM-Pin 9 als Ausgang definieren
  DDRB |= (1 << DDB1);
    
  // set pin modes for motor ports
  pinMode(PORT____MOTOR_SPEED, OUTPUT);
  pinMode(PORT____MOTOR_DIR_1, OUTPUT);
  pinMode(PORT____MOTOR_DIR_2, OUTPUT);

  // set motor direction
  digitalWrite(PORT____MOTOR_DIR_1, LOW);
  digitalWrite(PORT____MOTOR_DIR_2, HIGH);

}

/**
  * start the dust sensor (port modes and actual start by baud rate)
  */
void setupSensorDust() {
  pinMode(PORT_SENSOR_DUST_RX, INPUT);
  pinMode(PORT_SENSOR_DUST_TX, OUTPUT);
  SENSOR_DUST.begin(9600);
}

/**
  * start the dht sensor (by calling api method)
  */
void setupSensorDht() {
  SENSOR_DHT.begin();
}

/**
  * maps the motor value (0-1023) into the valid motor power range (valueMotorMin -> valueMotorMax)
  */
void applyMotorSpeed() {
  OCR1A = map(valueMotor, 0, 1023, valueMotorMin, valueMotorMax);
}

void loop(void) {

  readPotentiometer();
  readSensorVibration();

  if (millis() > 2000 && valueMotorMin > 290) {
    valueMotorMin = 290;
  }

  // read dust sensor value
  readSensorDust();
  // read temperature and humidity
  readSensorDht();

  calculateMotorValue();
  applyMotorSpeed();

  u8g.firstPage();
  do {
    redrawDisplayLoop();
  } while (u8g.nextPage());

  delay(1000);

}

/**
  * read (and invert) the potentiometer value, so 0 is on the very ccw position
  */ 
void readPotentiometer() {
  valuePoti = 1023 - analogRead(PORT__POTENTIOMETER);
}

/**
  * from dust sensor and potentiometer value calculate motor value
  */
void calculateMotorValue() {
    if (valueVibr >= 1023) {
    valueMotor = max(0, valueMotor - 24);
  } else {
    float p = 1000.0f / map(valuePoti, 0, 1023, 500, 2000); // map potentiometer to 1/0.5 -> 1/2.0 (2 -> 0.5)
    float b = min(valuePm25, 250.0f) / 250.0f; // convert sensor value to 0 -> 1 (mapping 0 to 0, 250 to 1)
    int _valueMotor = pow(b, p) * 1023;
    // increment motor value in small steps to get smooth increase of motor power
    if (_valueMotor > valueMotor) {
      valueMotor = min(valueMotor + 3, _valueMotor);
    } else if (_valueMotor < valueMotor) {
      valueMotor = max(valueMotor - 6, _valueMotor);
    }
  }

}

/**
  * read a sample from the dust sensor and store into value buffer
  * @return true if the sensor value changed with this call
  */
void readSensorDust() {

  if (SENSOR_DUST.available()) {

    SENSOR_DUST.readBytes(BUFFER_SENSOR_DUST, SENSOR_DUST.available());

    int samplePm25 = int((unsigned char)(BUFFER_SENSOR_DUST[12]) << 8 | (unsigned char)(BUFFER_SENSOR_DUST[13]));
    if (!isnan(samplePm25) && samplePm25 >= 0 && samplePm25 < 500) {

      valueIndexPm25 = ++valueIndexPm25 % 10;
      // store at current position
      valueArrayPm25[valueIndexPm25] = samplePm25;

      // clone value array
      int _valueArrayPm25[10];
      for (int i = 0; i < 10; i++) {
        _valueArrayPm25[i] = valueArrayPm25[i];
      }

      // sort the cloned array
      for (int i = 0; i < 9; i++) {
        for (int j = i + 1; j < 10; j++) {
          if (_valueArrayPm25[i] > _valueArrayPm25[j]) {
            int swap = _valueArrayPm25[i];
            _valueArrayPm25[i] = _valueArrayPm25[j];
            _valueArrayPm25[j] = swap;
          }
        }
      }      

      // reassign current value (dropping 2 smallest and 2 largest readings)
      valuePm25 = 0;
      for (int i = 2; i < 8; i++) {
        valuePm25 += valueArrayPm25[i];
      }
      valuePm25 = valuePm25 / 6;      

    }

  } 

}

/**
  * read a vibration value
  * due to difficulty with obtaining good values a lot of samples are taken
  * the max value of 1000 samples is obtained 10 times, and an average is built from those 10 values
  */
void readSensorVibration() {

  int _valueVibr = 0;
  for (int i = 0; i < 10; i++) {
    int loopValueVibr = 0;
    for (int j = 0; j < 100; j++) {
      loopValueVibr = max(loopValueVibr, analogRead(PORT______VIBRATION) * 40);
    }
    _valueVibr += loopValueVibr;
  }
  _valueVibr /= 10;

  // store at current position
  valueArrayVibr[valueIndexVibr++ % 10] = _valueVibr;

  // calculate average of last readings
  valueVibr = 0;
  for (int i = 0; i < 10; i++) {
    valueVibr += valueArrayVibr[i];
  }
  valueVibr /= 10;     

}

/**
  * read and store temperature and humidity
  */
void readSensorDht() {
  float sampleHumidity = SENSOR_DHT.readHumidity();
  float sampleTemperature = SENSOR_DHT.readTemperature();
  if (!isnan(sampleHumidity)) {
    valueHumidity = sampleHumidity;
  }
  if (!isnan(sampleTemperature)) {
    valueTemperature = sampleTemperature;
  }
}



/**
  * pad a fixed number into a 4 character long string stored in CHAR_BUF
  */
void padSpace4(int number) {
  int noPadChars = floor(log10(number));
  String padded = STRING_PAD_BLANK_4.substring(noPadChars);
  padded += number;
  padded.toCharArray(CHAR_BUF, 32);
}

void padBrack4(String prefix, int number) {
  int noPadChars = (number == 0 ? 0 : floor(log10(number))) + prefix.length();
  String padded = prefix;
  padded += STRING_PAD_BRACK_4.substring(noPadChars);
  padded += number;
  padded.toCharArray(CHAR_BUF, 32);
}

void padFloat(float number) {
  dtostrf(number, 4, 1, CHAR_BUF);
}

void redrawDisplayLoop() {

  u8g.setFont(u8g_font_profont29);

  padSpace4(valuePm25);
  u8g.drawStr(24, DISPLAY_TEXT_A, CHAR_BUF);

  // switch to smaller font
  u8g.setFont(u8g_font_profont15);
  u8g.drawStr(95, DISPLAY_TEXT_A, "\xb5g/m\xb3");

  padFloat(valueTemperature);
  u8g.drawStr(47, DISPLAY_TEXT_B, CHAR_BUF);  
  u8g.drawStr(76, DISPLAY_TEXT_B, "\xb0");  
  u8g.drawStr(83, DISPLAY_TEXT_B, "C");  

  padSpace4(valueHumidity);
  u8g.drawStr(89, DISPLAY_TEXT_B, CHAR_BUF);  
  u8g.drawStr(119, DISPLAY_TEXT_B, "%");  

  float lineWidthBase = 83.0f;

  int lineWidthA = valuePoti * lineWidthBase / 1023;
  int lineWidthB = valueMotor * lineWidthBase / 1023;
  int lineWidthC = valueVibr * lineWidthBase / 1023;

  u8g.drawFrame(45, DISPLAY_LINE_A - 4, lineWidthBase, 5);
  u8g.drawBox(45, DISPLAY_LINE_A - 4, lineWidthA, 5);
  u8g.drawFrame(45, DISPLAY_LINE_B - 4, lineWidthBase, 5);
  u8g.drawBox(45, DISPLAY_LINE_B - 4, lineWidthB, 5);
  u8g.drawFrame(45, DISPLAY_LINE_C - 4, lineWidthBase, 5);
  u8g.drawBox(45, DISPLAY_LINE_C - 4, lineWidthC, 5);
 
  u8g.setFont(u8g_font_micro);

  padBrack4("GAIN", valuePoti);
  u8g.drawStr(0, DISPLAY_LINE_A + 1, CHAR_BUF);  

  padBrack4("MOTOR", valueMotor);
  u8g.drawStr(0, DISPLAY_LINE_B + 1, CHAR_BUF);  

  padBrack4("VIBR", valueVibr);
  u8g.drawStr(0, DISPLAY_LINE_C + 1, CHAR_BUF);  

  u8g.drawStr(0, 5, "PM 2.5"); 
  String(valueArrayPm25[valueIndexPm25]).toCharArray(CHAR_BUF, 32);
  u8g.drawStr(94, 5, CHAR_BUF);  

}
