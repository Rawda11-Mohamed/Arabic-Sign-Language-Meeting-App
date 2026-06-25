from ultralytics import YOLO
import os

model_path = r"c:\Users\Rawda\StudioProjects\meeting2\flask_api\best_arsl_yolo (10).pt"
model = YOLO(model_path)

arabic_letters_map = {
    'Ain': 'ع', 'Al': 'ال', 'Alef': 'أ', 'Beh': 'ب', 'Dad': 'ض', 'Dal': 'د', 
    'Feh': 'ف', 'Ghain': 'غ', 'Hah': 'ح', 'Heh': 'ه', 'Jeem': 'ج', 'Kaf': 'ك', 
    'Khah': 'خ', 'Laa': 'لا', 'Lam': 'ل', 'Meem': 'م', 'Noon': 'ن', 'Qaf': 'ق', 
    'Reh': 'ر', 'Sad': 'ص', 'Seen': 'س', 'Sheen': 'ش', 'Tah': 'ط', 'Teh': 'ت', 
    'Teh_Marbuta': 'ة', 'Thal': 'ذ', 'Theh': 'ث', 'Waw': 'و', 'Yeh': 'ي', 'Zah': 'ظ', 'Zain': 'ز'
}

print("=== YOLO Model Class Mapping Verification ===")
for i, name in model.names.items():
    ar = arabic_letters_map.get(name, "MISSING")
    print(f"Index {i:2d}: {name:15s} -> {ar}")
