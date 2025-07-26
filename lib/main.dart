import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(BookApp());
}

class BookApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: BookListPage(),
    );
  }
}

class BookListPage extends StatelessWidget {
  final CollectionReference books = FirebaseFirestore.instance.collection('books');

  void _showForm(BuildContext context, [DocumentSnapshot? doc]) {
    final titleController = TextEditingController(text: doc?['title']);
    final volumeController = TextEditingController(text: doc?['volume']);
    final placeController = TextEditingController(text: doc?['place']);
    final priceController = TextEditingController(text: doc?['price']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(doc == null ? 'เพิ่มหนังสือ' : 'แก้ไขหนังสือ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'ชื่อหนังสือ')),
            TextField(controller: volumeController, decoration: InputDecoration(labelText: 'เล่มที่')),
            TextField(controller: placeController, decoration: InputDecoration(labelText: 'ซื้อที่')),
            TextField(controller: priceController, decoration: InputDecoration(labelText: 'ราคาที่ซื้อ'), keyboardType: TextInputType.number),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final data = {
                  'title': titleController.text.trim(),
                  'volume': volumeController.text.trim(),
                  'place': placeController.text.trim(),
                  'price': priceController.text.trim(),
                  'timestamp': FieldValue.serverTimestamp(),
                };
                if (doc == null) {
                  await books.add(data);
                } else {
                  await books.doc(doc.id).update(data);
                }
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.save),
              label: Text(doc == null ? 'บันทึก' : 'อัปเดต'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteBook(String id) {
    FirebaseFirestore.instance.collection('books').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('หนังสือที่เคยซื้อ', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade100,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        label: Text("เพิ่มหนังสือ"),
        icon: Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: books.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('เกิดข้อผิดพลาด'));
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          final bookDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: bookDocs.length,
            itemBuilder: (context, index) {
              final doc = bookDocs[index];
              final book = doc.data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(book['title'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('เล่ม ${book['volume']} | ซื้อที่: ${book['place']} | ราคา: ${book['price']} บาท'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(Icons.edit, color: Colors.orange), onPressed: () => _showForm(context, doc)),
                      IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteBook(doc.id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
