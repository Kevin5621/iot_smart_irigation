from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import numpy as np
import tensorflow as tf
from PIL import Image
import io
from lime import lime_image
from skimage.segmentation import mark_boundaries
import shap
import matplotlib.pyplot as plt
import cv2
import os

app = FastAPI()

# Enable CORS for Flutter dev access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model
model_path = os.getenv("MODEL_FILE", "mobilenetv2_model.h5")
model = tf.keras.models.load_model(model_path)
IMG_SIZE = (224, 224)

@app.get("/")
def home():
    return {"message": "Model server running"}

def preprocess_image(image_bytes):
    image = Image.open(io.BytesIO(image_bytes)).resize(IMG_SIZE)
    return np.expand_dims(np.array(image) / 255.0, axis=0)

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

@app.post("/explain/lime")
async def explain_lime(file: UploadFile = File(...)):
    img_bytes = await file.read()
    image_np = np.array(Image.open(io.BytesIO(img_bytes)).resize(IMG_SIZE))

    explainer = lime_image.LimeImageExplainer()

    def predict_fn(images):
        return model.predict(np.array(images) / 255.0)

    explanation = explainer.explain_instance(
        image_np,
        predict_fn,
        top_labels=1,
        hide_color=0,
        num_samples=1000
    )

    label = np.argmax(model.predict(np.expand_dims(image_np / 255.0, axis=0)))
    temp, mask = explanation.get_image_and_mask(label, positive_only=True, num_features=5, hide_rest=True)

    plt.imshow(mark_boundaries(temp, mask))
    plt.title(f"LIME for label {label}")
    plt.axis('off')
    plt.savefig("lime_result.png")

    return {"message": "LIME image saved as lime_result.png", "label": int(label)}

@app.post("/explain/shap")
async def explain_shap(file: UploadFile = File(...)):
    try:
        img_bytes = await file.read()
        sample_img = np.array(Image.open(io.BytesIO(img_bytes)).resize(IMG_SIZE)) / 255.0
        sample_img = np.expand_dims(sample_img, axis=0)

        # Use dummy background if no training data on server
        background = np.random.rand(10, 224, 224, 3)

        explainer = shap.DeepExplainer(model, background)
        shap_values = explainer.shap_values(sample_img)

        label = np.argmax(model.predict(sample_img))
        shap.image_plot(shap_values, -sample_img, show=False)

        plt.savefig("shap_result.png")
        return {"message": "SHAP image saved as shap_result.png", "label": int(label)}
    except Exception as e:
        return {"error": str(e)}
