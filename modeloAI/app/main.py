# -*- coding: latin-1 -*-
import os
import numpy as np
import cv2
import base64
from flask import Flask, request, jsonify
import io
from ultralytics import YOLO
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# --- Configuración de rutas ---
BASE_DIR = "./app"

# Rutas de modelos
OREGANO_DETECTOR_PATH = os.path.join(BASE_DIR, "oreganoDetectorYOLOv1.pt")
DISEASE_CLASSIFIER_PATH = os.path.join(BASE_DIR, "DetectorEnfermedadesYOLO.pt")
DISEASE_CLASS_NAMES = ['ALTERNARIA', 'MOSAICO', 'OIDIO', 'ROYA']

# --- Inicialización de modelos ---
oregano_detector = None
disease_classifier = None

def load_models():
    global oregano_detector, disease_classifier
    logger.info("⏳ Creando modelos...")
    try:
        if os.path.exists(OREGANO_DETECTOR_PATH):
            oregano_detector = YOLO(OREGANO_DETECTOR_PATH, task='detect')
            logger.info("✅ Modelo detector de orégano cargado")
        else:
            logger.error(f"❌ Archivo de detector no encontrado: {OREGANO_DETECTOR_PATH}")
    except Exception as e:
        logger.error(f"🚨 Error cargando el detector de orégano: {str(e)}")
    
    try:
        if os.path.exists(DISEASE_CLASSIFIER_PATH):
            disease_classifier = YOLO(DISEASE_CLASSIFIER_PATH, task='classify')
            logger.info("✅ Modelo clasificador de enfermedades cargado")
        else:
            logger.error(f"❌ Archivo de clasificador no encontrado: {DISEASE_CLASSIFIER_PATH}")
    except Exception as e:
        logger.error(f"🚨 Error cargando clasificador de enfermedades: {str(e)}")

# Cargar modelos al iniciar
load_models()

# --- Parámetros ---
OREGANO_CONF_THRESHOLD = 0.6  #0.6
DISEASE_CONF_THRESHOLD = 0.4
MODEL_CLASSIFY_SIZE = (224, 224)
MARGIN = 20  # Margen en píxeles para la imagen

def draw_bounding_boxes(img, boxes, labels, margin=MARGIN):
    # Agregar margen blanco a la imagen
    img_with_margin = cv2.copyMakeBorder(img, margin, margin, margin, margin, cv2.BORDER_CONSTANT, value=(255, 255, 255))
    
    for i, (box, label) in enumerate(zip(boxes, labels), 1):
        # Ajustar coordenadas con el margen
        x1, y1, x2, y2 = map(int, box.xyxy[0])
        x1 += margin
        y1 += margin
        x2 += margin
        y2 += margin
        color = (0, 0, 255)  # Verde
        cv2.rectangle(img_with_margin, (x1, y1), (x2, y2), color, 2)
        
        # Calcular posición de la etiqueta
        text = f"{i}: {label}"
        text_size = cv2.getTextSize(text, cv2.FONT_HERSHEY_SIMPLEX, 0.9, 2)[0]
        text_x = x1
        text_y = y1 - 10 if y1 - 10 > margin else y1 + text_size[1] + 10
        
        # Dibujar la etiqueta
        cv2.putText(img_with_margin, text, (text_x, text_y), cv2.FONT_HERSHEY_SIMPLEX, 0.9, color, 2)
    
    return img_with_margin

@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({"error": "No se proporcionó archivo"}), 400
    
    file = request.files['file']
    if not file or file.filename == '':
        return jsonify({"error": "Nombre de archivo vacío"}), 400
    
    try:
        # Leer imagen con OpenCV (BGR)
        img_bytes = file.read()
        img_array = np.frombuffer(img_bytes, np.uint8)
        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
        if img is None:
            return jsonify({"error": "No se pudo leer la imagen"}), 400
        logger.info(f"Imagen recibida: {file.filename}, tamaño: {img.shape}")
        
        # Verificar si el modelo detector está cargado
        if oregano_detector is None:
            return jsonify({"error": "Modelo detector de orégano no cargado"}), 500
        
        # Detectar orégano
        results = oregano_detector(img)
        
        # Filtrar bounding boxes con confianza >= 0.6
        valid_boxes = []
        for r in results:
            if r.boxes is not None:
                for box in r.boxes:
                    conf = float(box.conf[0])
                    if conf >= OREGANO_CONF_THRESHOLD:
                        valid_boxes.append(box)
                        logger.info(f"Oregano detectado: confianza={conf:.4f}, coords={box.xyxy[0].tolist()}")
        
        # Procesar imagen y respuesta
        labels = []
        if valid_boxes:
            for box in valid_boxes:
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                cropped_img = img[y1:y2, x1:x2]
                if cropped_img.size == 0:
                    logger.warning(f"Region recortada vacía para coords: [{x1}, {y1}, {x2}, {y2}]")
                    labels.append("Oregano sano")
                    continue
                
                # Redimensionar recorte para clasificación
                cropped_img_resized = cv2.resize(cropped_img, MODEL_CLASSIFY_SIZE, interpolation=cv2.INTER_LANCZOS4)
                logger.info(f"Region recortada y redimensionada: tamaño={cropped_img_resized.shape}")
                
                # Clasificar enfermedad
                if disease_classifier:
                    results_disease = disease_classifier(cropped_img_resized)
                    if results_disease and results_disease[0].probs is not None:
                        probs = results_disease[0].probs.data.cpu().numpy()
                        conf_max = np.max(probs)
                        class_id = np.argmax(probs)
                        if conf_max >= DISEASE_CONF_THRESHOLD and class_id < len(DISEASE_CLASS_NAMES):
                            enfermedad = DISEASE_CLASS_NAMES[class_id]
                            labels.append(enfermedad.capitalize())
                            logger.info(f"Enfermedad detectada: {enfermedad}, confianza={conf_max:.4f}")
                        else:
                            labels.append("Oregano sano")
                            logger.info(f"No se detectó enfermedad con confianza suficiente: {conf_max:.4f}")
                    else:
                        labels.append("Oregano sano")
                        logger.info("No se obtuvieron probabilidades válidas para esta región")
                else:
                    labels.append("Oregano sano")
                    logger.info("Modelo de clasificación no disponible")
            
            # Dibujar bounding boxes en la imagen con margen
            img_with_boxes = draw_bounding_boxes(img.copy(), valid_boxes, labels)
        else:
            # Si no hay orégano, usar la imagen original con margen
            logger.info("No se detecta oregano en la imagen o mal enfocada")
            img_with_boxes = cv2.copyMakeBorder(img, MARGIN, MARGIN, MARGIN, MARGIN, cv2.BORDER_CONSTANT, value=(255, 255, 255))
            labels = ["No se detecta oregano"]
        
        # Codificar la imagen en base64
        _, img_encoded = cv2.imencode('.jpg', img_with_boxes)
        img_base64 = base64.b64encode(img_encoded).decode('utf-8')
        
        # Respuesta
        response = {
            "enfermedades": [f"Oregano {i+1}: {label}" for i, label in enumerate(labels)] if valid_boxes else ["No se detecta oregano"],
            "imagen": f"data:image/jpeg;base64,{img_base64}"
        }
        return jsonify(response), 200
    
    except Exception as e:
        logger.exception("Error durante la predicción")
        return jsonify({"error": f"Error interno: {str(e)}"}), 500

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        "status": "ok",
        "oregano_detector_loaded": oregano_detector is not None,
        "disease_classifier_loaded": disease_classifier is not None
    }), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)