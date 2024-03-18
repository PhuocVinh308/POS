import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'Order.dart';
import 'TableService.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Table List',
      home: TableListPage(),
    );
  }
}

class TableListPage extends StatefulWidget {
  @override
  _TableListPageState createState() => _TableListPageState();
}

class _TableListPageState extends State<TableListPage> {
  List<dynamic> tables = [];

  @override
  void initState() {
    super.initState();
    fetchTableList();
  }

  Future<void> fetchTableList() async {
    final response = await http.get(Uri.parse('http://localhost:8080/api/table'));

    if (response.statusCode == 200) {
      setState(() {
        tables = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load table list');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách bàn'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: tables.length,
        itemBuilder: (context, index) {
          bool isEmpty = !tables[index]['status'];
          Color cardColor = isEmpty ? Colors.blue : Colors.pink;
          return Card(
            elevation: 3,
            color: cardColor,
            child: InkWell(
              onTap: () {
                isEmpty = !isEmpty;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderPage(tables[index]['id']),
                  ),
                ).then((_) {
                  // Gọi fetchTableList() sau khi quay lại từ OrderPage
                  fetchTableList();
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_chart, size: 20),
                  SizedBox(height: 8),
                  Text(
                    'Bàn ${tables[index]['id']}',
                    style: TextStyle(fontSize: 18),
                  ), // Tên bàn
                  SizedBox(height: 4),
                  Text(
                    'Trạng thái: ${isEmpty ? "Trống" : "Có khách"}',
                    style: TextStyle(fontSize: 14),
                  ), // Trạng thái bàn
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

