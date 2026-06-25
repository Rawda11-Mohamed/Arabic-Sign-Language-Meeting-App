#!/usr/bin/env python3
"""
Quick connection test script for Flask API
Run this to verify the Flask server is accessible
"""
import requests
import sys

def test_connection(ip_address="write your ip address", port=5000):
    """Test if Flask API is reachable"""
    url = f"http://{ip_address}:{port}"
    
    print("=" * 60)
    print("Flask API Connection Test")
    print("=" * 60)
    print(f"Testing connection to: {url}")
    print()
    
    # Test 1: Simple test endpoint
    print("Test 1: Testing /test endpoint...")
    try:
        response = requests.get(f"{url}/test", timeout=5)
        if response.status_code == 200:
            print(f"[OK] SUCCESS: {response.json()}")
        else:
            print(f"[FAIL] FAILED: Status code {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("[FAIL] FAILED: Cannot connect to server")
        print("  -> Flask server is not running or not reachable")
        print("  -> Start Flask: python flask_api/app.py")
        return False
    except requests.exceptions.Timeout:
        print("[FAIL] FAILED: Connection timeout")
        print("  -> Server is not responding")
        return False
    except Exception as e:
        print(f"[FAIL] FAILED: {e}")
        return False
    
    print()
    
    # Test 2: Health endpoint
    print("Test 2: Testing /health endpoint...")
    try:
        response = requests.get(f"{url}/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"[OK] SUCCESS: Server is healthy")
            print(f"  Model loaded: {data.get('model_loaded', 'Unknown')}")
            print(f"  Model exists: {data.get('model_exists', 'Unknown')}")
        else:
            print(f"[FAIL] FAILED: Status code {response.status_code}")
            return False
    except Exception as e:
        print(f"[FAIL] FAILED: {e}")
        return False
    
    print()
    print("=" * 60)
    print("[OK] All tests passed! Flask API is reachable.")
    print("=" * 60)
    return True

if __name__ == "__main__":
    # Get IP from command line or use default
    ip = sys.argv[1] if len(sys.argv) > 1 else "write your ip address"
    
    print(f"Using IP address: {ip}")
    print("To test a different IP, run: python test_connection.py YOUR_IP")
    print()
    
    if not test_connection(ip):
        print()
        print("=" * 60)
        print("TROUBLESHOOTING:")
        print("=" * 60)
        print("1. Is Flask server running?")
        print("   -> cd flask_api")
        print("   -> python app.py")
        print()
        print("2. Is the IP address correct?")
        print("   -> Windows: ipconfig (look for IPv4 Address)")
        print("   -> Mac/Linux: ifconfig (look for inet address)")
        print()
        print("3. Are both devices on the same WiFi?")
        print()
        print("4. Is the firewall blocking port 5000?")
        print("   -> Check Windows Firewall settings")
        print()
        print("5. Test in browser:")
        print(f"   -> http://{ip}:5000/test")
        print("=" * 60)
        sys.exit(1)
    
    sys.exit(0)
