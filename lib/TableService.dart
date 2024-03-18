import 'package:http/http.dart' as http;
import 'dart:convert';

class TableService {
  static Future<void> updateTableStatus(int tableId, bool status) async {
    final response = await http.put(
      Uri.parse('http://localhost:8080/api/table/$tableId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, bool>{'status': status}),
    );

    if (response.statusCode == 200) {
      print('Table status updated successfully');
    } else {
      throw Exception('Failed to update table status');
    }
  }
}
