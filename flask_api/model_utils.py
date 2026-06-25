import numpy as np
import time
try:
    import keras
except ImportError:
    import tensorflow.keras as keras

# ============================================
# TRAIN-TIME AUGMENTATION HELPERS
# ============================================
def advanced_augment_sequence(sequence, sigma=0.05, scale_factor=0.1):
    """
    Apply augmentation to a sequence of landmarks.
    Adds Gaussian noise and optional scaling.
    """
    augmented = sequence.copy()
    
    # 1. Jittering (Gaussian Noise)
    noise = np.random.normal(0, sigma, augmented.shape)
    augmented += noise
    
    # 2. Scaling (resizing the gesture in space)
    # Scale x, y, z coordinates around their center
    # Assuming standard feature layout: [x, y, z, vis, ...] or similar
    # We will just scale the whole feature vector for simplicity if it's raw coordinates
    # But often features are more complex. 
    # For robust valid augmentation on flattened features, we apply mild random scaling.
    scale = np.random.uniform(1.0 - scale_factor, 1.0 + scale_factor)
    augmented *= scale
    
    return augmented

# ============================================
# TTA (TEST-TIME AUGMENTATION)
# ============================================
def predict_with_tta(model, sequence, class_to_id, n_augmentations=5):
    """
    Ensemble predictions with test-time augmentation
    """
    predictions = []
    
    # Base prediction (no augmentation)
    pred_base = model.predict(sequence.reshape(1, *sequence.shape), verbose=0)
    if isinstance(pred_base, list):
        for output in pred_base:
            if output.shape[-1] == len(class_to_id):
                pred_base = output
                break
    predictions.append(pred_base[0])

    # Augmented predictions
    for _ in range(n_augmentations):
        # Create augmented version
        augmented = advanced_augment_sequence(sequence)
        augmented = augmented.reshape(1, *augmented.shape)

        # Get prediction
        pred = model.predict(augmented, verbose=0)

        # If hierarchical model with multiple outputs, use main output
        if isinstance(pred, list):
            # Find the main output (softmax with num_classes)
            for output in pred:
                if output.shape[-1] == len(class_to_id):
                    pred = output
                    break
        
        predictions.append(pred[0])

    # Ensemble: average predictions
    predictions = np.array(predictions)
    avg_pred = np.mean(predictions, axis=0)

    return np.argmax(avg_pred), np.max(avg_pred)

# ============================================
# FEEDBACK COLLECTOR
# ============================================
class FeedbackCollector:
    """Collect and learn from user feedback"""
    def __init__(self, model, class_mapping):
        self.model = model
        self.class_mapping = class_mapping
        self.reverse_mapping = {v: k for k, v in class_mapping.items()}
        
        # Feedback storage
        self.feedback_buffer = []
        self.misclassification_log = []
        self.confidence_history = []
        
        # Adaptive thresholds
        self.confidence_threshold = 0.7
        self.stability_threshold = 5
        
    def record_prediction(self, sequence, predicted_class, confidence, actual_class=None):
        """Record a prediction with optional feedback"""
        record = {
            'sequence': sequence.copy(),
            'predicted': predicted_class,
            'confidence': confidence,
            'actual': actual_class,
            'timestamp': time.time(),
            'is_correct': actual_class == predicted_class if actual_class else None
        }
        
        self.feedback_buffer.append(record)
        
        # Log misclassifications
        if actual_class and actual_class != predicted_class:
            self.misclassification_log.append(record)
            print(f"📝 Misclassification logged: {predicted_class} → {actual_class}")
            
            # Adjust threshold if confidence was high but wrong
            if confidence > 0.8:
                self.confidence_threshold = min(0.9, self.confidence_threshold + 0.02)
        
        # Keep buffer size manageable
        if len(self.feedback_buffer) > 100:
            self.feedback_buffer = self.feedback_buffer[-100:]
    
    def get_retraining_data(self, min_samples=20):
        """Prepare data for retraining from feedback"""
        if len(self.misclassification_log) < min_samples:
            return None, None
        
        X_retrain, y_retrain = [], []
        
        for record in self.misclassification_log:
            if record['actual'] and record['is_correct'] == False:
                X_retrain.append(record['sequence'])
                y_retrain.append(self.class_mapping[record['actual']])
        
        if len(X_retrain) >= min_samples:
            return np.array(X_retrain), np.array(y_retrain)
        
        return None, None
    
    def adaptive_confidence_threshold(self):
        """Dynamically adjust confidence threshold"""
        if len(self.confidence_history) > 20:
            recent_confidences = self.confidence_history[-20:]
            avg_confidence = np.mean(recent_confidences)
            
            # Adjust threshold based on recent performance
            if avg_confidence > 0.8:
                self.confidence_threshold = max(0.6, self.confidence_threshold - 0.01)
            elif avg_confidence < 0.5:
                self.confidence_threshold = min(0.85, self.confidence_threshold + 0.02)
        
        return self.confidence_threshold
