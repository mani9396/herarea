import urllib.request
import json
try:
    req = urllib.request.Request('http://127.0.0.1:8000/api/v1/stores/')
    resp = urllib.request.urlopen(req)
    data = json.loads(resp.read().decode())
    print(json.dumps(data, indent=2))
except Exception as e:
    print(e)
