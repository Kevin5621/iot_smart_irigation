# Smart Irrigation System - IoT Based Plant Care

## Deskripsi Project
Sistem irigasi pintar berbasis IoT yang mengintegrasikan Arduino ESP32, aplikasi mobile Flutter, dan AI untuk klasifikasi tanaman. Sistem ini dapat mengontrol penyiraman tanaman secara otomatis berdasarkan jenis tanaman dan kelembapan tanah.

## Struktur Project
```
iot_smart_irigation/
├── iot/smart_irigation/           # Arduino ESP32 Code
│   ├── arduino_mqtt_integration.ino
│   └── smart_irigation.ino
├── mobile_app/                    # Flutter Mobile App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── entities/
│   │   ├── models/
│   │   ├── presentation/
│   │   ├── providers/
│   │   ├── service/
│   │   └── utils/
│   └── pubspec.yaml
└── plant_classification_api/      # FastAPI AI Server
    ├── app.py
    ├── requirements.txt
    └── README.md
```

---

## 1. Arduino ESP32 Code (IoT Hardware)

### 1.1 Import Library
```cpp
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <WiFi.h>
#include <PubSubClient.h>
```
- **Wire.h** → untuk komunikasi I2C dengan LCD
- **LiquidCrystal_I2C.h** → untuk menampilkan data di LCD 16x2
- **WiFi.h** → untuk koneksi ESP32 ke WiFi
- **PubSubClient.h** → untuk komunikasi MQTT dengan aplikasi mobile

### 1.2 Konfigurasi Pin & Hardware
```cpp
#define SOIL_SENSOR_PIN 35
#define RELAY_PIN 5

LiquidCrystal_I2C lcd(0x27, 16, 2);
```
- **SOIL_SENSOR_PIN** → GPIO 35 untuk sensor kelembapan tanah
- **RELAY_PIN** → GPIO 5 untuk mengontrol relay pompa air
- **LCD** → alamat I2C 0x27, ukuran 16x2 karakter

### 1.3 Konfigurasi WiFi & MQTT
```cpp
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

const char* mqtt_server = "192.168.18.91";
const int mqtt_port = 1883;
const char* mqtt_user = "user";
const char* mqtt_password = "sehatmu";
```
- **SSID dan password** → kredensial WiFi untuk koneksi internet
- **MQTT broker** → server MQTT untuk komunikasi dengan aplikasi mobile
- **Port 1883** → port standar MQTT
- **Credentials** → username dan password untuk autentikasi MQTT

### 1.4 MQTT Topics
```cpp
// Topic untuk subscribe
client.subscribe("plant_type");

// Topic untuk publish
client.publish("kelembapan_tanah", String(moisturePercent).c_str());
client.publish("status", pumpState ? "1" : "0");
```
- **plant_type** → menerima jenis tanaman dari AI classification
- **kelembapan_tanah** → mengirim data kelembapan ke aplikasi mobile
- **status** → mengirim status pompa (ON/OFF)

### 1.5 Fungsi Threshold Berdasarkan Tanaman
```cpp
int getThresholdByPlantType(String plantType) {
  if (plantType == "cactus") return 20;
  else if (plantType == "chili") return 40;
  else if (plantType == "monstera") return 50;
  else if (plantType == "spinach") return 60;
  else if (plantType == "tomato") return 55;
  else return 40;
}
```
- **Dynamic threshold** → ambang batas kelembapan berbeda untuk setiap jenis tanaman
- **Cactus** → 20% (tanaman gurun, butuh sedikit air)
- **Chili** → 40% (tanaman tropis)
- **Monstera** → 50% (tanaman hias)
- **Spinach** → 60% (sayuran daun)
- **Tomato** → 55% (tanaman buah)

### 1.6 Fungsi Setup WiFi
```cpp
void setup_wifi() {
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi connected");
}
```
- **WiFi.begin()** → memulai koneksi WiFi
- **Loop** → menunggu hingga terkoneksi
- **Status feedback** → tampilkan IP address setelah terhubung

### 1.7 Fungsi MQTT Callback
```cpp
void callback(char* topic, byte* payload, unsigned int length) {
  String message;
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  if (String(topic) == "plant_type") {
    currentPlantType = message;
    Serial.print("Plant type updated to: ");
    Serial.println(currentPlantType);
  }
}
```
- **Callback function** → dipanggil saat ada pesan MQTT masuk
- **Parse payload** → konversi byte array ke string
- **Update plant type** → ubah jenis tanaman berdasarkan AI classification

### 1.8 Fungsi Setup()
```cpp
void setup() {
  Serial.begin(115200);
  analogReadResolution(12);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH);
  
  lcd.init();
  lcd.backlight();
  
  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}
```
- **Serial.begin()** → inisialisasi komunikasi serial 115200 baud
- **analogReadResolution()** → set resolusi ADC ESP32 12-bit (0-4095)
- **pinMode()** → set relay pin sebagai output
- **LCD init** → inisialisasi dan nyalakan backlight LCD
- **WiFi dan MQTT** → setup koneksi dan callback

### 1.9 Fungsi Loop() - Main Program
```cpp
void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
  
  // Baca sensor kelembapan tanah
  int sensorValue = analogRead(SOIL_SENSOR_PIN);
  float moisturePercent = map(sensorValue, 0, 4095, 100, 0);
  moisturePercent = constrain(moisturePercent, 0, 100);
  
  int threshold = getThresholdByPlantType(currentPlantType);
  
  // Kontrol pompa berdasarkan threshold
  if (moisturePercent < threshold) {
    if (currentMillis - previousMillis >= interval) {
      previousMillis = currentMillis;
      pumpState = !pumpState;
      digitalWrite(RELAY_PIN, pumpState ? LOW : HIGH);
    }
  } else {
    pumpState = false;
    digitalWrite(RELAY_PIN, HIGH);
  }
  
  // Publish data ke MQTT
  client.publish("kelembapan_tanah", String(moisturePercent).c_str());
  client.publish("status", pumpState ? "1" : "0");
}
```
- **MQTT maintenance** → jaga koneksi MQTT tetap aktif
- **Sensor reading** → baca nilai analog dari sensor kelembapan
- **Data mapping** → konversi nilai ADC (0-4095) ke persentase (0-100%)
- **Smart control** → pompa ON/OFF berdasarkan threshold tanaman
- **Interval pumping** → pompa beroperasi dengan interval 5 detik ON/OFF
- **Data transmission** → kirim data ke aplikasi mobile via MQTT

---

## 2. Flutter Mobile App (Android/iOS)

### 2.1 Main Entry Point
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_irigation/providers/app_provider.dart';
import 'package:smart_irigation/presentation/home/home_page.dart';

void main() {
  runApp(const MyApp());
}
```
- **Provider pattern** → state management untuk aplikasi
- **Material Design** → UI framework Android/iOS
- **HomePage** → halaman utama aplikasi

### 2.2 App Provider (State Management)
```dart
class AppProvider extends ChangeNotifier {
  final IoTService _iotService = IoTService();
  final PlantClassificationService _plantService = PlantClassificationService();
  
  bool _isConnected = false;
  PlantEntity? _currentPlant;
  double _currentMoisture = 0.0;
  bool _pumpStatus = false;
}
```
- **ChangeNotifier** → notifikasi perubahan state ke UI
- **IoTService** → komunikasi MQTT dengan Arduino
- **PlantClassificationService** → komunikasi dengan AI server
- **State variables** → menyimpan data sensor dan status

### 2.3 IoT Service (MQTT Communication)
```dart
class IoTService {
  String _broker = '192.168.18.91';
  int _port = 1883;
  String _username = 'user';
  String _password = 'sehatmu';
  
  Future<void> connect() async {
    final status = await _client.connect(_username, _password);
    if (status?.state == MqttConnectionState.connected) {
      _client.subscribe('kelembapan_tanah', MqttQos.atMostOnce);
      _client.subscribe('status', MqttQos.atMostOnce);
    }
  }
}
```
- **MQTT Client** → koneksi ke broker MQTT
- **Subscribe topics** → dengarkan data dari Arduino
- **Publish topics** → kirim perintah ke Arduino
- **Stream data** → real-time data sensor

### 2.4 Plant Classification Service (AI Integration)
```dart
class PlantClassificationService {
  static const String _defaultBaseUrl = 'http://192.168.94.247:8000';
  
  Future<PlantEntity?> classifyPlant(dynamic imageData) async {
    final uri = Uri.parse('$baseUrl/predict');
    final request = http.MultipartRequest('POST', uri);
    
    // Upload image file
    final multipartFile = await http.MultipartFile.fromPath('file', imageData.path);
    request.files.add(multipartFile);
    
    final response = await http.Response.fromStream(await request.send());
    final data = json.decode(response.body);
    
    return PlantEntity(
      id: _uuid.v4(),
      name: data['prediction'],
      confidence: data['confidence'],
      detectedAt: DateTime.now(),
    );
  }
}
```
- **HTTP multipart** → upload foto tanaman ke AI server
- **JSON response** → terima hasil klasifikasi dari AI
- **PlantEntity** → model data tanaman dengan confidence score
- **UUID** → generate unique ID untuk setiap deteksi

### 2.5 Home Page UI
```dart
class HomePage extends StatefulWidget {
  Future<void> _takePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final imageFile = File(image.path);
      await context.read<AppProvider>().classifyPlant(imageFile);
    }
  }
}
```
- **Camera integration** → ambil foto tanaman
- **Image picker** → pilih foto dari kamera atau galeri
- **AI classification** → kirim foto ke AI server
- **Real-time UI** → tampilkan hasil klasifikasi

### 2.6 Sensor Data Display
```dart
// Sensor Data Cards
const SensorCard(),
const PumpControlCard(),
const SettingsCard(),
```
- **SensorCard** → tampilkan data kelembapan tanah
- **PumpControlCard** → kontrol manual pompa air
- **SettingsCard** → pengaturan threshold dan mode otomatis

---

## 3. FastAPI AI Server (Plant Classification)

### 3.1 FastAPI Setup
```python
from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import tensorflow as tf
from PIL import Image
import numpy as np

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
```
- **FastAPI** → modern Python web framework
- **CORS middleware** → izinkan akses dari Flutter app
- **TensorFlow** → machine learning framework
- **PIL** → image processing library

### 3.2 Model Loading
```python
model_path = os.getenv("MODEL_FILE", "mobilenetv2_model.h5")
IMG_SIZE = (224, 224)

try:
    model = tf.keras.models.load_model(model_path)
    print(f"Model loaded successfully from {model_path}")
except Exception as e:
    print(f"Model file not found: {e}")
    # Create mock model for testing
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(224, 224, 3)),
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dense(5, activation='softmax')
    ])
```
- **Model loading** → load pre-trained MobileNetV2 model
- **Error handling** → fallback ke mock model jika file tidak ada
- **Image size** → resize foto ke 224x224 pixel
- **5 classes** → cactus, chili, monstera, spinach, tomato

### 3.3 Prediction Endpoint
```python
@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    img_bytes = await file.read()
    input_tensor = preprocess_image(img_bytes)
    prediction = model.predict(input_tensor)
    label = int(np.argmax(prediction))
    
    label_mapping = {
        0: "cactus",
        1: "chili", 
        2: "monstera",
        3: "spinach",
        4: "tomato"
    }
    
    return {
        "prediction": label_mapping.get(label, "unknown"),
        "confidence": float(np.max(prediction))
    }
```
- **File upload** → terima foto dari Flutter app
- **Image preprocessing** → resize dan normalisasi gambar
- **Model prediction** → klasifikasi menggunakan neural network
- **Label mapping** → konversi index ke nama tanaman
- **JSON response** → kirim hasil ke mobile app

### 3.4 Image Preprocessing
```python
def preprocess_image(image_bytes):
    image = Image.open(io.BytesIO(image_bytes)).resize(IMG_SIZE)
    return np.expand_dims(np.array(image) / 255.0, axis=0)
```
- **PIL Image** → load gambar dari bytes
- **Resize** → ubah ukuran ke 224x224
- **Normalization** → nilai pixel 0-1 (dibagi 255)
- **Batch dimension** → tambah dimensi batch untuk model

---

## 4. Sistem Terintegrasi

### 4.1 Workflow Sistem
1. **Plant Detection** → User foto tanaman dengan mobile app
2. **AI Classification** → Foto dikirim ke FastAPI server untuk klasifikasi
3. **MQTT Communication** → Hasil klasifikasi dikirim ke Arduino via MQTT
4. **Smart Irrigation** → Arduino adjust threshold berdasarkan jenis tanaman
5. **Sensor Monitoring** → Real-time monitoring kelembapan dan status pompa
6. **Automatic Control** → Pompa otomatis ON/OFF berdasarkan threshold

### 4.2 Komunikasi Antar Komponen
```
[Mobile App] ←→ [FastAPI Server] (HTTP/REST)
     ↓
[Mobile App] ←→ [Arduino ESP32] (MQTT)
     ↓
[Arduino ESP32] ←→ [Sensors & Pump] (GPIO)
```

### 4.3 Data Flow
```
1. Image → FastAPI → Plant Classification
2. Plant Type → MQTT → Arduino
3. Sensor Data → Arduino → MQTT → Mobile App
4. Pump Control → Mobile App → MQTT → Arduino
```

---

## 5. Teknologi yang Digunakan

### 5.1 Hardware
- **ESP32** → microcontroller dengan WiFi built-in
- **Soil Moisture Sensor** → sensor kelembapan tanah
- **Relay Module** → kontroler pompa air
- **LCD 16x2** → display informasi
- **Water Pump** → pompa air untuk irigasi

### 5.2 Software
- **Arduino IDE** → development environment untuk ESP32
- **Flutter** → cross-platform mobile app development
- **FastAPI** → Python web framework untuk AI server
- **TensorFlow** → machine learning framework
- **MQTT** → lightweight messaging protocol untuk IoT

### 5.3 AI & Machine Learning
- **MobileNetV2** → efficient neural network untuk mobile devices
- **Transfer Learning** → fine-tuning pre-trained model
- **Image Classification** → 5 classes plant recognition
- **LIME & SHAP** → explainable AI untuk interpretasi hasil

---

## 6. Cara Menjalankan Sistem

### 6.1 Setup Hardware
1. Rangkai ESP32 dengan sensor dan LCD
2. Upload kode Arduino ke ESP32
3. Konfigurasi WiFi dan MQTT credentials

### 6.2 Setup AI Server
```bash
cd plant_classification_api
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app:app --reload
```

### 6.3 Setup Mobile App
```bash
cd mobile_app
flutter pub get
flutter run
```

### 6.4 Konfigurasi Koneksi
1. Buka aplikasi mobile
2. Masuk ke Settings > Connection Config
3. Masukkan IP address MQTT broker dan FastAPI server
4. Test koneksi sebelum digunakan

---

## 7. Fitur Utama

### 7.1 Smart Plant Recognition
- **AI-powered** → deteksi otomatis jenis tanaman dari foto
- **5 plant types** → cactus, chili, monstera, spinach, tomato
- **High accuracy** → confidence score untuk setiap prediksi
- **Real-time** → hasil klasifikasi langsung ditampilkan

### 7.2 Adaptive Irrigation
- **Dynamic threshold** → ambang batas berbeda untuk setiap tanaman
- **Automatic mode** → penyiraman otomatis berdasarkan sensor
- **Manual control** → kontrol manual pompa dari aplikasi
- **Timer function** → pompa dengan durasi tertentu

### 7.3 Real-time Monitoring
- **Live data** → monitoring kelembapan tanah secara real-time
- **Pump status** → status pompa (ON/OFF) ditampilkan
- **Connection status** → indikator koneksi IoT device
- **Historical data** → riwayat data sensor dan aktivitas pompa

### 7.4 User-friendly Interface
- **Modern UI** → desain aplikasi mobile yang menarik
- **Easy setup** → konfigurasi koneksi yang mudah
- **Responsive** → aplikasi berjalan di Android dan iOS
- **Offline capability** → beberapa fitur tetap berfungsi tanpa internet

---

## Kesimpulan

Sistem Smart Irrigation ini mengintegrasikan teknologi IoT, AI, dan mobile app untuk menciptakan solusi penyiraman tanaman yang cerdas dan efisien. Dengan menggunakan AI untuk mengidentifikasi jenis tanaman, sistem dapat secara otomatis menyesuaikan kebutuhan air yang optimal untuk setiap tanaman, sehingga menghemat air dan meningkatkan hasil pertanian.

**Keunggulan Sistem:**
- **Otomatis** → mengurangi intervensi manual
- **Efisien** → menghemat air dengan penyiraman yang tepat
- **Scalable** → dapat dikembangkan untuk berbagai jenis tanaman
- **Real-time** → monitoring dan kontrol secara langsung
- **AI-powered** → menggunakan teknologi machine learning terdepan
