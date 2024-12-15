#include <LiquidCrystal_I2C.h>
#include <ESP8266WiFi.h>
#include <PubSubClient.h>

// Konfigurasi WiFi
const char* ssid = "zenix";
const char* password = "rakretiaku";

// Konfigurasi MQTT
const char* mqtt_broker = "broker.hivemq.com";
const int mqtt_port = 1883;
const char* client_id = "smart_irrigation_device";

// Topik MQTT
const char* moisture_topic = "smart_irrigation/moisture";
const char* pump_control_topic = "smart_irrigation/pump_control";
const char* pump_status_topic = "smart_irrigation/pump_status";

// Inisialisasi LCD
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Inisialisasi WiFi dan MQTT client
WiFiClient espClient;
PubSubClient client(espClient);

// Definisi pin
#define sensor A0
#define waterPump D3

// Variabel global
unsigned long lastMoisturePublish = 0;
const long moisturePublishInterval = 5000; // Publish data moisture setiap 5 detik

void setup() {
  Serial.begin(9600);
  
  // Inisialisasi pin
  pinMode(waterPump, OUTPUT);
  digitalWrite(waterPump, HIGH); // Pompa awalnya mati
  
  // Inisialisasi LCD
  lcd.init();
  lcd.backlight();
  
  // Koneksi WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nTerhubung ke WiFi");
  
  // Konfigurasi MQTT
  client.setServer(mqtt_broker, mqtt_port);
  client.setCallback(callback);
  
  // Tampilan loading di LCD
  lcd.setCursor(1, 0);
  lcd.print("System Loading");
  for (int a = 0; a <= 15; a++) {
    lcd.setCursor(a, 1);
    lcd.print(".");
    delay(500);
  }
  lcd.clear();
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Mencoba koneksi MQTT...");
    if (client.connect(client_id)) {
      Serial.println("Terhubung");
      
      // Subscribe ke topik kontrol pompa
      client.subscribe(pump_control_topic);
      
      // Publikasi status awal
      client.publish(pump_status_topic, "OFF");
    } else {
      Serial.print("Gagal, rc=");
      Serial.print(client.state());
      Serial.println(" Coba lagi dalam 5 detik");
      delay(5000);
    }
  }
}

void callback(char* topic, byte* payload, unsigned int length) {
  // Konversi payload ke string
  String message;
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  // Cek topik pump control
  if (String(topic) == pump_control_topic) {
    if (message == "ON") {
      digitalWrite(waterPump, LOW);
      lcd.setCursor(0, 1);
      lcd.print("Motor is ON ");
      client.publish(pump_status_topic, "ON");
    } else if (message == "OFF") {
      digitalWrite(waterPump, HIGH);
      lcd.setCursor(0, 1);
      lcd.print("Motor is OFF");
      client.publish(pump_status_topic, "OFF");
    }
  }
}

void publishMoistureLevel() {
  int value = analogRead(sensor);
  value = map(value, 0, 1024, 0, 100);
  value = (value - 100) * -1;
  
  // Tampilkan di LCD
  lcd.setCursor(0, 0);
  lcd.print("Moisture :");
  lcd.print(value);
  lcd.print(" ");
  
  // Publikasi ke MQTT
  char moistureStr[10];
  snprintf(moistureStr, sizeof(moistureStr), "%d", value);
  client.publish(moisture_topic, moistureStr);
}

void loop() {
  // Pastikan tetap terhubung ke MQTT
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
  
  // Publikasi moisture level secara berkala
  unsigned long currentMillis = millis();
  if (currentMillis - lastMoisturePublish >= moisturePublishInterval) {
    publishMoistureLevel();
    lastMoisturePublish = currentMillis;
  }
}