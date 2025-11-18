import json
import sys
import os

try:
    import joblib  # type: ignore
    HAS_JOBLIB = True
except Exception:
    HAS_JOBLIB = False


def load_model():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    # Prefer pkl (pickle/joblib) if available
    pkl_path = os.path.join(base_dir, 'weather_model.pkl')
    if HAS_JOBLIB and os.path.exists(pkl_path):
        try:
            return joblib.load(pkl_path)
        except Exception:
            pass
    # Fallback: try loading a pickled object stored inside an HDF5 file
    h5_path = os.path.join(base_dir, 'models', 'random_forest_model.h5')
    if os.path.exists(h5_path):
        try:
            import h5py  # type: ignore
            with h5py.File(h5_path, 'r') as f:
                if 'model_pickle' in f:
                    import pickle
                    blob = f['model_pickle'][()]
                    return pickle.loads(blob.tobytes() if hasattr(blob, 'tobytes') else blob)
        except Exception:
            pass
    return None


def map_to_risk(prob_or_class):
    try:
        if isinstance(prob_or_class, (list, tuple)):
            p = float(prob_or_class[0])
        else:
            p = float(prob_or_class)
    except Exception:
        return 'Medium'
    if p >= 0.7:
        return 'High'
    if p >= 0.5:
        return 'Medium'
    return 'Low'


def main():
    try:
        payload = json.loads(sys.stdin.read())
    except Exception:
        print(json.dumps({
            'success': False,
            'error': 'invalid_input'
        }))
        return

    temperature = float(payload.get('temperature', 20.0))
    humidity = float(payload.get('humidity', 60.0))
    rain = float(payload.get('rain', 0.0))
    wind_speed = float(payload.get('wind_speed', 2.0))
    cloudiness = float(payload.get('cloudiness', 20.0))

    model = load_model()
    if model is None:
        # Heuristic fallback
        risk = 'High' if (humidity > 70 and 15 <= temperature <= 30) or rain > 0 else (
            'Medium' if (60 < humidity <= 70 or 10 <= temperature < 15 or 30 < temperature <= 35) else 'Low'
        )
        print(json.dumps({
            'success': True,
            'risk_level': risk,
            'source': 'heuristic'
        }))
        return

    # Build feature vector in fixed order; many models are trained on raw values or pipelines
    X = [[temperature, humidity, rain, wind_speed, cloudiness]]
    try:
        if hasattr(model, 'predict_proba'):
            proba = model.predict_proba(X)
            if isinstance(proba, list):
                prob = proba[0][-1] if hasattr(proba[0], '__getitem__') else 0.5
            else:
                prob = float(proba[0][-1])
            risk = map_to_risk(prob)
            print(json.dumps({
                'success': True,
                'risk_level': risk,
                'probability': prob,
                'source': 'model'
            }))
            return
        pred = model.predict(X)
        cls = pred[0] if hasattr(pred, '__getitem__') else pred
        try:
            prob = 0.7 if int(cls) == 1 else 0.3
        except Exception:
            prob = 0.5
        risk = map_to_risk(prob)
        print(json.dumps({
            'success': True,
            'risk_level': risk,
            'probability': prob,
            'source': 'model'
        }))
    except Exception:
        # Final safety fallback
        risk = 'High' if (humidity > 70 and 15 <= temperature <= 30) or rain > 0 else (
            'Medium' if (60 < humidity <= 70 or 10 <= temperature < 15 or 30 < temperature <= 35) else 'Low'
        )
        print(json.dumps({
            'success': True,
            'risk_level': risk,
            'source': 'heuristic'
        }))


if __name__ == '__main__':
    main()