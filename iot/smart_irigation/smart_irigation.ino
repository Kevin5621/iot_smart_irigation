#include <Wire.h>
#include <LiquidCrystal_I2C.h>

#define SOIL_SENSOR_PIN 35
#define RELAY_PIN 5

LiquidCrystal_I2C lcd(0x27, 16, 2);

// Pengaturan waktu pompa
unsigned long previousMillis = 0;
const unsigned long interval = 5000; // 5 detik
bool pumpState = false;

// Variabel tanaman
String currentPlantType = "chili";

// Fungsi ambang kelembapan berdasarkan jenis tanaman
int getThresholdByPlantType(String plantType) {
  if (plantType == "cactus") return 20;
  else if (plantType == "chili") return 40;
  else if (plantType == "monstera") return 50;
  else if (plantType == "spinach") return 60;
  else if (plantType == "tomato") return 55;
  else return 40;
}

// Kapitalisasi nama tanaman
String capitalize(String input) {
  if (input.length() == 0) return input;
  input[0] = toupper(input[0]);
  return input;
}

void setup() {
  Serial.begin(115200);
  analogReadResolution(12); // ESP32: 0 - 4095
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH); // Pompa OFF (aktif LOW)

  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Inisialisasi...");
  delay(2000);
  lcd.clear();
}

void loop() {
  unsigned long currentMillis = millis();

  // Baca sensor kelembapan tanah
  int sensorValue = analogRead(SOIL_SENSOR_PIN);
  float moisturePercent = map(sensorValue, 0, 4095, 100, 0);
  moisturePercent = constrain(moisturePercent, 0, 100);

  int threshold = getThresholdByPlantType(currentPlantType);

  // LCD baris 1: nama tanaman
  lcd.setCursor(0, 0);
  lcd.print("Tanaman:");
  String displayPlant = capitalize(currentPlantType);
  lcd.print(displayPlant);
  for (int i = displayPlant.length(); i < 8; i++) lcd.print(" ");

  // LCD baris 2: kelembapan dan status pompa
  lcd.setCursor(0, 1);
  lcd.print("M:");
  lcd.print((int)moisturePercent);
  lcd.print("% ");

  if (moisturePercent < threshold) {
    // Jalankan mode interval ON/OFF
    if (currentMillis - previousMillis >= interval) {
      previousMillis = currentMillis;
      pumpState = !pumpState;
      digitalWrite(RELAY_PIN, pumpState ? LOW : HIGH); // ON = LOW
    }
  } else {
    // Kelembapan cukup → pompa OFF
    pumpState = false;
    digitalWrite(RELAY_PIN, HIGH); // OFF
  }

  lcd.print("P:");
  lcd.print(pumpState ? "ON " : "OFF");

  // Debug serial
  Serial.print("Moisture: ");
  Serial.print(moisturePercent);
  Serial.print("% | Threshold: ");
  Serial.print(threshold);
  Serial.print(" | Pompa: ");
  Serial.println(pumpState ? "ON" : "OFF");

  delay(200); // Loop lebih cepat
}