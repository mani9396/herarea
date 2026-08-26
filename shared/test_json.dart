import 'dart:convert';
import 'lib/models/store_model.dart';
import 'lib/models/category_model.dart';

void main() {
  final jsonStr = '''{
    "id": "9f25e2c7-5c27-4cd7-b0cd-4b60933cc659", 
    "category": null, 
    "subcategory": null, 
    "business_name": "Aaadhya's Business", 
    "description": null, 
    "address_line_1": "", 
    "address_line_2": null, 
    "area": "", 
    "city": "", 
    "state": "", 
    "country": "India", 
    "postal_code": "", 
    "contact_email": "vendor3@gmail.com", 
    "contact_phone": "9999999123", 
    "latitude": null, 
    "longitude": null, 
    "business_timings": {}, 
    "logo": null, 
    "cover_image": null, 
    "gallery": [], 
    "is_listing_eligible": false, 
    "status": "DRAFT", 
    "admin_remarks": null, 
    "created_at": "2026-08-21T08:27:49.071786Z", 
    "updated_at": "2026-08-21T08:27:49.072068Z", 
    "rating": 0.0, 
    "review_count": 0
  }''';
  
  final json = jsonDecode(jsonStr);
  try {
    final store = StoreModel.fromJson(json);
    print('Success: \${store.name}');
  } catch(e, s) {
    print('Error: \$e');
    print(s);
  }
}
