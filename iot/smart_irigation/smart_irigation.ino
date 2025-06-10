#include <DHT.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

#define SOIL_SENSOR_PIN 35     // Pin analog untuk sensor kelembapan tanah
#define RELAY_PIN 5            // Pin digital untuk relay
#define MOISTURE_THRESHOLD 40  // Ambang kelembapan (%), di bawah ini pompa menyala

#define DHTPIN 4               // Pin data DHT22
#define DHTTYPE DHT22          // Tipe sensor DHT

DHT dht(DHTPIN, DHTTYPE);

// Inisialisasi LCD I2C di alamat 0x27 dan ukuran 16x2
LiquidCrystal_I2C lcd(0x27, 16, 2);

void setup() {
  Serial.begin(115200);
  analogReadResolution(12);       // Resolusi ADC 12-bit (0 - 4095)

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);   // Pastikan relay OFF saat mulai

  dht.begin();                    // Inisialisasi DHT
  lcd.init();                     // Inisialisasi LCD
  lcd.backlight();                // Nyalakan backlight

  lcd.setCursor(0, 0);
  lcd.print("Sistem Siap...");
  delay(2000);
  lcd.clear();

  Serial.println("Inisialisasi selesai...");
}

void loop() {
  int sensorValue = analogRead(SOIL_SENSOR_PIN);
  float moisturePercent = map(sensorValue, 0, 4095, 100, 0); // 0 = basah, 4095 = kering
  moisturePercent = constrain(moisturePercent, 0, 100);

  float temperature = dht.readTemperature();

  // Serial Monitor
  Serial.print("Soil Moisture (Raw): ");
  Serial.print(sensorValue);
  Serial.print(" | Moisture (%): ");
  Serial.print(moisturePercent);

  lcd.setCursor(0, 0);
  lcd.print("Moist: ");
  lcd.print((int)moisturePercent);
  lcd.print("%    "); // spasi agar membersihkan sisa karakter

  if (isnan(temperature)) {
    Serial.println(" | Temp: Gagal baca 😓");
    lcd.setCursor(0, 1);
    lcd.print("Temp: Error    ");
  } else {
    Serial.print(" | Temp: ");
    Serial.print(temperature);
    Serial.println("°C");

    lcd.setCursor(0, 1);
    lcd.print("Temp: ");
    lcd.print(temperature, 1); // 1 desimal
    lcd.print((char)223);      // simbol derajat
    lcd.print("C   ");
  }

  // Kontrol Relay
  if (moisturePercent < MOISTURE_THRESHOLD) {
    digitalWrite(RELAY_PIN, LOW);
    Serial.println("Status: Penyiraman AKTIF ✅");
  } else {
    digitalWrite(RELAY_PIN, HIGH);
    Serial.println("Status: Penyiraman MATI ❌");
  }

  delay(1000);
}