import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './TableService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderPage extends StatefulWidget {
  final int tableId;

  OrderPage(this.tableId);

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<dynamic> products = [];
  Map<int, int> orderedItems = {};

  @override
  void dispose() {
    saveTemporaryOrderToLocalStorage();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadTemporaryOrderFromLocalStorage();
    fetchProducts();
  }

  double calculateTotalAmount() {
    double total = 0;
    for (int productId in orderedItems.keys) {
      dynamic product = products.firstWhere((element) => element['id'] == productId, orElse: () => null);
      if (product != null) {
        total += product['price'] * orderedItems[productId]!;
      }
    }
    return total;
  }
  Future<void> saveTemporaryOrderToLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('temporary_order_${widget.tableId}', orderedItems.entries.map((entry) => '${entry.key}:${entry.value}').toList());
  }
  Future<void> loadTemporaryOrderFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? temporaryOrder = prefs.getStringList('temporary_order_${widget.tableId}');
    if (temporaryOrder != null) {
      setState(() {
        orderedItems = Map.fromEntries(temporaryOrder.map((entry) {
          List<String> splitEntry = entry.split(':');
          return MapEntry(int.parse(splitEntry[0]), int.parse(splitEntry[1]));
        }));
      });
    }
  }

  Future<void> fetchProducts() async {
    final response = await http.get(Uri.parse('http://localhost:8080/api/products'));

    if (response.statusCode == 200) {
      setState(() {
        products = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load products');
    }
  }

  void orderProduct(int productId) {
    setState(() {
      if (orderedItems.containsKey(productId)) {
        orderedItems[productId] = (orderedItems[productId] ?? 0) + 1;
      } else {
        orderedItems[productId] = 1;
      }
    });
  }




  void removeProduct(int productId) {
    setState(() {
      orderedItems.remove(productId);
    });
  }

  void updateQuantity(int productId, int newQuantity) {
    setState(() {
      if (newQuantity > 0) {
        orderedItems[productId] = newQuantity;
      } else {
        orderedItems.remove(productId);
      }
    });
  }
  Future<void> clearOrderAndSetTableStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('order_${widget.tableId}');
    await TableService.updateTableStatus(widget.tableId, false); // Set trạng thái của bàn thành trống
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          int productId = products[index]['id'];
          int quantity = orderedItems.containsKey(productId) ? orderedItems[productId]! : 0;

          return Card(
            child: InkWell(
              onTap: () {
                orderProduct(productId);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Image.network(
                      products[index]['linkImage'],
                      fit: BoxFit.fitHeight,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          products[index]['productName'],
                          style: GoogleFonts.getFont('Lato'),
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () {
                                removeProduct(productId);
                              },
                            ),
                            InkWell(
                              onTap: () {
                                int newQuantity = orderedItems.containsKey(productId) ? orderedItems[productId]! : 0;
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Nhập số lượng'),
                                    content: TextFormField(
                                      initialValue: newQuantity.toString(),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        newQuantity = int.tryParse(value) ?? 0;
                                      },
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          updateQuantity(productId, newQuantity);
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Text(
                                '$quantity',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                orderProduct(productId);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '${products[index]['price'].round() }K',
                      style: TextStyle(color: Colors.black87,fontSize: 15),
                      textAlign: TextAlign.center ,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      endDrawer: Drawer(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40.0),
                        bottomRight: Radius.circular(40.0),
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Hoá đơn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                        ),
                      ),
                    ),
                  ),

                  for (int productId in orderedItems.keys)
                    ListTile(
                      title: Text(products.firstWhere((element) => element['id'] == productId)['productName']),
                      subtitle: Text('Số lượng: ${orderedItems[productId]}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          removeProduct(productId);
                        },
                      ),
                    ),
                  ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tổng hóa đơn: '),
                        Text(calculateTotalAmount().round().toString()),
                      ],
                    ),
                  ),
                ],
              ),
              ListTile(
                title: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Chọn hình thức thanh toán'),
                        content: Text('Tiền mặt'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await clearOrderAndSetTableStatus();
                              setState(() {
                                orderedItems.clear();
                              });
                              Navigator.of(context).pop();
                            },
                            child: Text('Thanh toán'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text('Thanh toán'),
                ),
              ),
            ],
          ),
        ),
      ),


    );

  }
}
