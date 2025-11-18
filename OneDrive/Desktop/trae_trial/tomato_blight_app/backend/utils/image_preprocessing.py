from tensorflow.keras.preprocessing.image import img_to_array, load_img

def resize_image(image_path, target_size):
    """
    Loads and resizes an image to the target size.
    """
    image = load_img(image_path, target_size=target_size)
    return img_to_array(image)

def normalize_image(image):
    """
    Normalizes pixel values to the range [0, 1].
    """
    return image / 255.0

def preprocess_image(image_path, target_size=(256, 256)):
    """
    Preprocess an image: resize + normalize.
    Returns a numpy array ready for model prediction.
    """
    image = resize_image(image_path, target_size)
    image = normalize_image(image)
    return image

