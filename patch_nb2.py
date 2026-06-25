import json

path = "C:/Users/Rawda/Downloads/videos4.ipynb"
with open(path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

for cell in nb.get('cells', []):
    if cell['cell_type'] == 'code':
        source = "".join(cell['source'])
        
        if "def simple_predict(data_url):" in source:
            source = source.replace("movement_threshold = 0.005", "movement_threshold = 0.000")
            source = source.replace("if movement > movement_threshold", "if movement >= movement_threshold")
            
            source = source.replace("if confidence >= 0.70:", "if confidence >= 0.65:")
            
            old_else = """                else:
                    return {
                        "prediction": "💡 جاري تجميع الإشارة للوصول لنتيجة دقيقة...",
                        "progress": 100,
                        "tip": "حافظي على حركة يدك لاكتمال الإشارة",
                        "ready": False
                    }"""
            new_else = """                else:
                    if len(buffer) > 0:
                        buffer.popleft()  # لمنع تكرار التوقع اللانهائي لنفس الإطارات
                    return {
                        "prediction": "💡 جاري تجميع الإشارة للوصول لنتيجة دقيقة...",
                        "progress": 100,
                        "tip": "حافظي على وضعية ידك",
                        "ready": False
                    }"""
            source = source.replace(old_else, new_else)
            
            lines = source.splitlines(True)
            cell['source'] = lines

with open(path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=2, ensure_ascii=False)
    
print("Notebook patched 2 successfully.")
