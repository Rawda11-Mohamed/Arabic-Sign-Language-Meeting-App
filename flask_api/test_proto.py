import google.protobuf
from google.protobuf import message_factory
import os

print(f"Protobuf Version: {google.protobuf.__version__}")
print(f"Implementation: {os.environ.get('PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION', 'default')}")

try:
    mf = message_factory.MessageFactory()
    print(f"Has GetPrototype: {hasattr(mf, 'GetPrototype')}")
    print(f"Has CreatePrototype: {hasattr(mf, 'CreatePrototype')}")
    print(f"Dir(mf): {dir(mf)}")
except Exception as e:
    print(f"Error: {e}")
