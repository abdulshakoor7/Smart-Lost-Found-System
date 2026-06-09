import os
import numpy as np
from PIL import Image
import tensorflow as tf
from tensorflow.keras.applications.mobilenet_v2 import MobileNetV2, preprocess_input, \
    decode_predictions
from tensorflow.keras.preprocessing.image import img_to_array

# Load the pre-trained MobileNetV2 model
# This model can recognize 1000 different everyday objects
print("Loading AI Model... (This takes a few seconds)")
model = MobileNetV2(weights='imagenet')


def extract_image_tags(image_path):
    """
    Takes an image path, runs it through TensorFlow,
    and returns a list of human-readable tags (e.g., ['laptop', 'notebook']).
    """
    try:
        # 1. Open and resize the image to exactly 224x224 pixels (Required by MobileNet)
        img = Image.open(image_path).resize((224, 224))

        # Ensure image has 3 color channels (RGB)
        if img.mode != 'RGB':
            img = img.convert('RGB')

        # 2. Convert image to Array and Preprocess
        img_array = img_to_array(img)
        img_array = np.expand_dims(img_array, axis=0)
        img_array = preprocess_input(img_array)

        # 3. Run the AI Prediction
        predictions = model.predict(img_array)

        # 4. Decode the predictions into readable labels (Get top 3 guesses)
        decoded_preds = decode_predictions(predictions, top=3)[0]

        # Extract just the label names and clean them up (e.g., 'cellular_telephone' -> 'cellular telephone')
        tags = [pred[1].replace('_', ' ').lower() for pred in decoded_preds]

        print(f"🤖 AI Image Tags Extracted: {tags}")
        return tags

    except Exception as e:
        print(f"❌ AI Extraction Failed: {e}")
        return []
