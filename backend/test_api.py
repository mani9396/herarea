import json
import urllib.request

req = urllib.request.Request("http://127.0.0.1:8000/api/v1/customer/business/stores/", headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())
        if "results" in data:
            for store in data["results"][:2]:
                print(f"Store: {store.get('business_name')} - vendor_id: {store.get('vendor_id')}")
except Exception as e:
    print(f"Error: {e}")
