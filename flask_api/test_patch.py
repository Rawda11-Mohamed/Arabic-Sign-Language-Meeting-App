import sys
import os

# First, install the newer protobuf again to reproduce the environment
# Actually, I'll just check if the current (downgraded) one has GetPrototype
# Then I'll try to simulate the missing attribute.

def test_monkeypatch():
    try:
        import google.protobuf.symbol_database as sdb
        from google.protobuf import message_factory
        
        # Check if it has GetPrototype
        has_it = hasattr(sdb.SymbolDatabase, 'GetPrototype')
        print(f"Original Has GetPrototype: {has_it}")
        
        if not has_it:
            print("Monkey-patching SymbolDatabase.GetPrototype...")
            def GetPrototype(self, descriptor):
                return message_factory.GetMessageClass(descriptor)
            sdb.SymbolDatabase.GetPrototype = GetPrototype
            print("Patch applied.")
            
        print(f"After Patch Has GetPrototype: {hasattr(sdb.SymbolDatabase, 'GetPrototype')}")
        
        import mediapipe as mp
        print("Imported mediapipe successfully after patch.")
        
        # Try to initialize hands
        hands = mp.solutions.hands.Hands(static_image_mode=True)
        print("MediaPipe Hands initialized after patch.")
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_monkeypatch()
