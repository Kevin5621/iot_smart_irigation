#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <WiFi.h>
#include <PubSubClient.h>

#define SOIL_SENSOR_PIN 35
#define RELAY_PIN 5

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// MQTT credentials
const char* mqtt_server = "192.168.18.91";
const int mqtt_port = 1883;
const char* mqtt_user = "user";
const char* mqtt_password = "sehatmu";

WiFiClient espClient;
PubSubClient client(espClient);

LiquidCrystal_I2C lcd(0x27, 16, 2);

// Pengaturan waktu pompa
unsigned long previousMillis = 0;
const unsigned long interval = 5000; // 5 detik
bool pumpState = false;

// Variabel tanaman - sekarang akan diupdate via MQTT
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

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

void callback(char* topic, byte* payload, unsigned int length) {
  String message;
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  Serial.println(message);

  // Update plant type from mobile app AI classification
  if (String(topic) == "plant_type") {
    currentPlantType = message;
    Serial.print("Plant type updated to: ");
    Serial.println(currentPlantType);
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    
    if (client.connect("ESP32Client", mqtt_user, mqtt_password)) {
      Serial.println("connected");
      
      // Subscribe to plant type updates from mobile app
      client.subscribe("plant_type");
      
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void publishSensorData() {
  if (client.connected()) {
    // Baca sensor kelembapan tanah
    int sensorValue = analogRead(SOIL_SENSOR_PIN);
    float moisturePercent = map(sensorValue, 0, 4095, 100, 0);
    moisturePercent = constrain(moisturePercent, 0, 100);
    
    // Publish to MQTT
    client.publish("kelembapan_tanah", String(moisturePercent).c_str());
    client.publish("status", pumpState ? "1" : "0");
  }
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

  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

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

  // Publish sensor data setiap 5 detik
  static unsigned long lastPublish = 0;
  if (currentMillis - lastPublish >= 5000) {
    publishSensorData();
    lastPublish = currentMillis;
  }

  // Debug serial
  Serial.print("Moisture: ");
  Serial.print(moisturePercent);
  Serial.print("% | Threshold: ");
  Serial.print(threshold);
  Serial.print(" | Pompa: ");
  Serial.println(pumpState ? "ON" : "OFF");

  delay(200); // Loop lebih cepat
}
