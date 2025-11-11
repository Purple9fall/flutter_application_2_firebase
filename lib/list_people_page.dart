import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListPeoplePage extends StatelessWidget {
  const ListPeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Thiết lập Real-time Listener (Stream)
    final Stream<QuerySnapshot> studentsStream = 
        FirebaseFirestore.instance.collection('SinhVien').snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Sinh Viên (Real-time)'),
        
      ),
      body: 
      // 2. Sử dụng StreamBuilder để xử lý Stream dữ liệu
      StreamBuilder<QuerySnapshot>(
        stream: studentsStream, // Kết nối với listener
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          
          // Trạng thái chờ: Đang tải dữ liệu ban đầu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Trạng thái lỗi
          if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
          }

          // 3. Dữ liệu đã sẵn sàng: Xây dựng danh sách
          final documents = snapshot.data!.docs;

          if (documents.isEmpty) {
            return const Center(
              child: Text('Chưa có sinh viên nào được thêm.', style: TextStyle(fontSize: 16)),
            );
          }
          
          // === PHẦN THÊM MỚI ĐỂ HIỂN THỊ TỔNG SỐ ===
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Tổng số sinh viên: ${documents.length}', // <-- Hiển thị tổng số
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              const Divider(height: 1),
              
              // ListView mở rộng để chiếm hết không gian còn lại
              Expanded(
                child: ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final data = documents[index].data() as Map<String, dynamic>;
                    
                    final name = data['name'] ?? 'Không tên';
                    final email = data['email'] ?? 'Không email';
                    
                    final schoolList = data['school'] as List<dynamic>? ?? [];
                    String schoolName = schoolList.isNotEmpty 
                        ? schoolList[0]['name'] : 'Chưa cập nhật trường';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$email\nHọc tại: $schoolName'),
                        isThreeLine: true,
                        trailing: Text(documents[index].id.substring(0, 5) + '...'), 
                      ),
                    );
                  },
                ),
              ),
            ],
          );
          // ===========================================
        },
      ),
    );
  }
}
