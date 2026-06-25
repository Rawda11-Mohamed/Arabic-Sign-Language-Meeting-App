import json

path = "C:/Users/Rawda/Downloads/videos4.ipynb"
with open(path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

for cell in nb.get('cells', []):
    if cell['cell_type'] == 'code':
        source = "".join(cell['source'])
        
        # Modification 1 (VideoProcessor)
        if "processed_count < total_frames" in source:
            source = source.replace("while cap.isOpened() and processed_count < total_frames:", "while cap.isOpened() and len(sequences) < self.sequence_length:")
            source = source.replace("sequences.append(landmarks[0])\n                    processed_count += 1", "sequences.append(landmarks[0])")
            source = source.replace("processed_count = 0\n", "")
            
            old_pad = "if len(sequences) < self.sequence_length:"
            new_pad = "if len(sequences) == 0:\n            return np.zeros((self.sequence_length, 100))\n\n        if len(sequences) < self.sequence_length:"
            source = source.replace(old_pad, new_pad)
        
        # Modification 2 (simple_predict)
        if "def simple_predict(data_url):" in source:
            source = source.replace("current_time - last_frame_time < 0.1", "current_time - last_frame_time < 0.06")
            source = source.replace("movement_threshold = 0.02", "movement_threshold = 0.005")
            
            old_buf = """                if confidence < 0.6:
                    print("💡 ملاحظة: الثقة منخفضة - جرب إشارة أكثر وضوحاً")

                # إفراغ البافر
                buffer.clear()
                last_landmarks = None

                return {
                    "prediction": sign,
                    "confidence": float(confidence),
                    "top5": top5_predictions,
                    "ready": True
                }"""
            new_buf = """                if confidence >= 0.70:
                    buffer.clear()
                    last_landmarks = None
                    return {
                        "prediction": sign,
                        "confidence": float(confidence),
                        "top5": top5_predictions,
                        "ready": True
                    }
                else:
                    return {
                        "prediction": "💡 جاري تجميع الإشارة للوصول لنتيجة دقيقة...",
                        "progress": 100,
                        "tip": "حافظي على حركة يدك لاكتمال الإشارة",
                        "ready": False
                    }"""
            source = source.replace(old_buf, new_buf)
            
        # Write back source
        lines = source.splitlines(True)
        cell['source'] = lines

with open(path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=2, ensure_ascii=False)
    
print("Notebook modified successfully.")
