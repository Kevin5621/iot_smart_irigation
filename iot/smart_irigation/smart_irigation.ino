#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// WiFi Credentials
const char* WIFI_SSID = "redmi";        // Pastikan nama SSID benar
const char* WIFI_PASSWORD = "wikepin05"; // Pastikan password benar

// MQTT Broker Settings
const char* MQTT_BROKER = "broker.hivemq.io";
const int MQTT_PORT = 1883;
const char* CLIENT_ID = "smart_irrigation_device";

// Pin Definitions
const int MOISTURE_SENSOR_PIN = A0;   // Analog pin for moisture sensor
const int PUMP_CONTROL_PIN = D1;      // Digital pin for pump control

// LCD Configuration
const int LCD_ADDRESS = 0x27;  // Typical I2C address for LCD modules
const int LCD_COLUMNS = 16;    // Number of columns on LCD
const int LCD_ROWS = 2;        // Number of rows on LCD

// MQTT Topics
const char* MOISTURE_TOPIC = "smart_irrigation/moisture";
const char* PUMP_STATUS_TOPIC = "smart_irrigation/pump_status";
const char* PUMP_CONTROL_TOPIC = "smart_irrigation/pump_control";
const char* PUMP_SETTINGS_TOPIC = "smart_irrigation/pump_settings";

// Global Variables
WiFiClient espClient;
PubSubClient mqttClient(espClient);
LiquidCrystal_I2C lcd(LCD_ADDRESS, LCD_COLUMNS, LCD_ROWS);

bool wifiConnected = false;
bool mqttConnected = false;

void setup() {
  Serial.begin(115200);

  // Initialize LCD
  Wire.begin(D2, D1);  // SDA, SCL for ESP8266
  lcd.init();
  lcd.backlight();
  lcd.clear();

  // Display startup message
  lcd.setCursor(0, 0);
  lcd.print("Smart Irrigation");
  lcd.setCursor(0, 1);
  lcd.print("Initializing...");
  delay(1000);

  // Setup Pins
  pinMode(MOISTURE_SENSOR_PIN, INPUT);
  pinMode(PUMP_CONTROL_PIN, OUTPUT);
  digitalWrite(PUMP_CONTROL_PIN, LOW);

  // Connect to WiFi
  connectToWiFi();

  // Setup MQTT
  mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
  mqttClient.setCallback(mqttCallback);
}

void loop() {
  // Check WiFi connection
  if (WiFi.status() != WL_CONNECTED) {
    connectToWiFi();
  }

  // Check MQTT connection
  if (!mqttClient.connected()) {
    reconnectMQTT();
  }
  mqttClient.loop();
}

void connectToWiFi() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Connecting WiFi");

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int maxRetries = 30;  // Maximum retries for WiFi connection
  int attempt = 0;

  while (WiFi.status() != WL_CONNECTED && attempt < maxRetries) {
    delay(500);
    Serial.print(".");
    lcd.setCursor(0, 1);
    lcd.print("Retry ");
    lcd.print(attempt + 1);
    attempt++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    Serial.println("\nWiFi Connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("WiFi Connected");
    lcd.setCursor(0, 1);
    lcd.print(WiFi.localIP());
    delay(2000);
  } else {
    wifiConnected = false;
    Serial.println("\nWiFi Connection Failed!");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("WiFi Failed!");
    lcd.setCursor(0, 1);
    lcd.print("Restarting...");
    delay(3000);
    ESP.restart();
  }
}

void reconnectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("Attempting MQTT connection...");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("MQTT Connecting");

    if (mqttClient.connect(CLIENT_ID)) {
      Serial.println("MQTT Connected!");
      mqttConnected = true;

      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("MQTT Connected");

      // Subscribe to topics
      mqttClient.subscribe(PUMP_CONTROL_TOPIC);
      mqttClient.subscribe(PUMP_SETTINGS_TOPIC);
    } else {
      mqttConnected = false;
      Serial.print("MQTT Connect Failed, rc=");
      Serial.println(mqttClient.state());
      lcd.setCursor(0, 1);
      lcd.print("Retry in 5 sec");
      delay(5000);
    }
  }
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  // Convert payload to string
  String message = "";
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  Serial.print("Message received on topic: ");
  Serial.println(topic);
  Serial.print("Message: ");
  Serial.println(message);

  // Handle pump control
  if (String(topic) == PUMP_CONTROL_TOPIC) {
    if (message == "ON") {
      digitalWrite(PUMP_CONTROL_PIN, HIGH);
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Pump: ON");
      mqttClient.publish(PUMP_STATUS_TOPIC, "Pump Activated");
    } else if (message == "OFF") {
      digitalWrite(PUMP_CONTROL_PIN, LOW);
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Pump: OFF");
      mqttClient.publish(PUMP_STATUS_TOPIC, "Pump Deactivated");
    }
  }

  // Handle pump settings (e.g., moisture threshold)
  if (String(topic) == PUMP_SETTINGS_TOPIC) {
    // Example: Parse JSON settings
    StaticJsonDocument<200> doc;
    DeserializationError error = deserializeJson(doc, message);
    
    if (!error) {
      int moistureThreshold = doc["moisture_threshold"] | 50; // Default 50 if not specified
      
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Moisture Threshold:");
      lcd.setCursor(0, 1);
      lcd.print(moistureThreshold);
      delay(2000);
    }
  }
}