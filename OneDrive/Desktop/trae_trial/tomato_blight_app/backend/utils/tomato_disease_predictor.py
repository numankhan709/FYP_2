import json
import sys
import os
import numpy as np

try:
    import tensorflow as tf  # type: ignore
except Exception as e:
    print(json.dumps({'error': 'tensorflow_not_available', 'message': str(e)}))
    sys.exit(1)

try:
    from PIL import Image, ImageOps  # type: ignore
except Exception as e:
    print(json.dumps({'error': 'pillow_not_available', 'message': str(e)}))
    sys.exit(1)

try:
    from tensorflow.keras.preprocessing import image as keras_image  # type: ignore
except Exception:
    keras_image = None


DEFAULT_CLASSES = [
    'healthy',
    'early_blight',
    'late_blight',
    'bacterial_spot',
    'mosaic_virus',
    'yellow_virus',
    'leaf_mold',
    'septoria_leaf_spot',
]


def load_classes():
    path = os.environ.get('TOMATO_CLASSES_PATH') or os.environ.get('TOMATO_CLASS_INDICES_JSON')
    if path and os.path.exists(path):
        try:
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
                import json as _json
                try:
                    obj = _json.loads(content)
                    if isinstance(obj, dict):
                        # name -> index mapping
                        inv = {int(v): str(k) for k, v in obj.items()}
                        classes = [inv[i] for i in sorted(inv.keys())]
                        return classes
                    if isinstance(obj, list):
                        return [str(x) for x in obj]
                except Exception:
                    lines = [ln.strip() for ln in content.splitlines()]
                    return [ln for ln in lines if ln]
        except Exception:
            pass
    classes_env = os.environ.get('TOMATO_CLASSES')
    if classes_env:
        return [c.strip() for c in classes_env.split(',') if c.strip()]
    return DEFAULT_CLASSES


def load_model(model_path: str | None):
    if model_path and os.path.exists(model_path):
        return tf.keras.models.load_model(model_path)
    raise FileNotFoundError('Model file not found: provide TOMATO_MODEL_PATH')


def preprocess(image_path: str):
    size = int(os.environ.get('TOMATO_IMAGE_SIZE', '224'))
    use_keras_loader = os.environ.get('TOMATO_USE_KERAS_LOADER', 'true').lower() in ('1', 'true', 'yes') and keras_image is not None
    if use_keras_loader:
        img = keras_image.load_img(image_path, target_size=(size, size))
        arr = keras_image.img_to_array(img).astype('float32') / 255.0
        arr = np.expand_dims(arr, axis=0)
        return arr
    # PIL path
    img = Image.open(image_path).convert('RGB')
    img = ImageOps.exif_transpose(img)
    # optional leaf-centric crop based on green channel dominance
    try:
        if os.environ.get('TOMATO_AUTO_LEAF_CROP', 'false').lower() in ('1', 'true', 'yes'):
            np_img = np.array(img)
            r = np_img[:, :, 0].astype(np.int16)
            g = np_img[:, :, 1].astype(np.int16)
            b = np_img[:, :, 2].astype(np.int16)
            mask = (g > r + 10) & (g > b + 10) & (g > 40)
            if mask.sum() > 0.01 * mask.size:
                ys, xs = np.where(mask)
                y0, y1 = int(ys.min()), int(ys.max())
                x0, x1 = int(xs.min()), int(xs.max())
                pad_y = int(0.05 * (y1 - y0 + 1))
                pad_x = int(0.05 * (x1 - x0 + 1))
                left = max(0, x0 - pad_x)
                top = max(0, y0 - pad_y)
                right = min(img.width, x1 + pad_x)
                bottom = min(img.height, y1 + pad_y)
                if right > left and bottom > top:
                    img = img.crop((left, top, right, bottom))
    except Exception:
        pass
    do_crop = os.environ.get('TOMATO_CENTER_CROP', 'true').lower() in ('1', 'true', 'yes')
    if do_crop:
        w, h = img.size
        m = min(w, h)
        left = (w - m) // 2
        top = (h - m) // 2
        img = img.crop((left, top, left + m, top + m))
    img = img.resize((size, size))
    arr = np.array(img).astype('float32')
    mode = os.environ.get('TOMATO_PREPROCESS', 'none').lower()
    try:
        if mode == 'efficientnet':
            from tensorflow.keras.applications.efficientnet import preprocess_input
            arr = preprocess_input(arr)
        elif mode == 'resnet50':
            from tensorflow.keras.applications.resnet50 import preprocess_input
            arr = preprocess_input(arr)
        elif mode == 'mobilenet_v2':
            from tensorflow.keras.applications.mobilenet_v2 import preprocess_input
            arr = preprocess_input(arr)
        else:
            arr = arr / 255.0
    except Exception:
        arr = arr / 255.0
    arr = np.expand_dims(arr, axis=0)
    return arr


def main():
    # Args: image_path [model_path]
    if len(sys.argv) < 2:
        print(json.dumps({'error': 'missing_image_path'}))
        return
    image_path = sys.argv[1]
    model_path = None
    if len(sys.argv) >= 3:
        model_path = sys.argv[2]
    else:
        model_path = os.environ.get('TOMATO_MODEL_PATH')

    try:
        model = load_model(model_path)
        x = preprocess(image_path)
        preds = model.predict(x)
        # Determine activation automatically or via env
        activation = os.environ.get('TOMATO_ACTIVATION', 'auto').lower()
        if preds.ndim == 2:
            vec = preds[0]
        else:
            vec = preds
        vec = np.array(vec, dtype=np.float32).reshape(-1)

        def softmax(v: np.ndarray) -> np.ndarray:
            v = v - np.max(v)
            e = np.exp(v)
            s = e.sum()
            return e / s if s > 0 else np.ones_like(v) / len(v)

        def sigmoid(v: np.ndarray) -> np.ndarray:
            return 1.0 / (1.0 + np.exp(-v))

        if activation == 'softmax':
            probs = softmax(vec)
        elif activation == 'sigmoid':
            probs = sigmoid(vec)
        else:  # auto
            # If values already in [0,1] and sum ~ 1, treat as probabilities
            if np.all(vec >= 0.0) and np.all(vec <= 1.0):
                s = float(vec.sum())
                if 0.9 <= s <= 1.1:
                    probs = vec
                else:
                    # Multi-label style outputs in [0,1]; use as-is
                    probs = vec
            else:
                # Likely logits; apply softmax
                probs = softmax(vec)
        # Map to classes and build top-k
        idx = int(np.argmax(probs))
        classes = load_classes()
        label = classes[idx] if idx < len(classes) else 'healthy'
        confidence = float(np.clip(probs[idx], 0.0, 1.0))
        order = list(np.argsort(-probs))
        topk = []
        for i in order[:min(5, len(order))]:
            name = classes[int(i)] if int(i) < len(classes) else f'class_{int(i)}'
            topk.append({'label': name, 'prob': float(np.clip(probs[int(i)], 0.0, 1.0))})
        print(json.dumps({
            'predicted_class': label,
            'confidence': confidence,
            'top3': topk[:3],
            'top5': topk
        }))
    except Exception as e:
        print(json.dumps({'error': 'prediction_failed', 'message': str(e)}))


if __name__ == '__main__':
    main()