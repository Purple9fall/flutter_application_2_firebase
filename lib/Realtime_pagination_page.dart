import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RealtimePaginationPage extends StatefulWidget {
  const RealtimePaginationPage({super.key});

  @override
  State<RealtimePaginationPage> createState() => _RealtimePaginationPageState();
}

class _RealtimePaginationPageState extends State<RealtimePaginationPage> {
  // Số lượng mục tải mỗi lần
  static const int _pageSize = 5;
  
  // Danh sách lưu trữ các QuerySnapshot từ các lần tải trước
  // List này chứa TẤT CẢ các document đã tải từ đầu.
  List<DocumentSnapshot> _allLoadedDocs = []; 
  
  // Con trỏ: DocumentSnapshot cuối cùng của lần tải gần nhất
  DocumentSnapshot? _lastDocument;
  
  // Trạng thái: Kiểm tra xem còn dữ liệu để tải nữa không
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    // Bắt đầu tải trang đầu tiên
    _loadNextPage(); 
  }
  
  // Hàm chính để tải trang tiếp theo
  void _loadNextPage() {
    if (!_hasMore) return; // Ngừng nếu đã tải hết

    // 1. Thiết lập Query cơ sở: Sắp xếp và Giới hạn
    Query query = FirebaseFirestore.instance
        .collection('SinhVien')
        .orderBy('name', descending: false) // BẮT BUỘC phải có orderBy
        .limit(_pageSize);
        
    // 2. Thiết lập con trỏ (startAfter) nếu đây không phải trang đầu tiên
    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }
    
    // 3. Khởi tạo Real-time Listener và lắng nghe
    // Dùng .get() chỉ để lấy trang tiếp theo, sau đó thêm vào _allLoadedDocs
    // LƯU Ý: Đây là phương pháp phổ biến nhất cho infinite scrolling.
    query.get().then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        // Cập nhật con trỏ và thêm các docs mới vào danh sách tổng
        _lastDocument = snapshot.docs.last;
        _allLoadedDocs.addAll(snapshot.docs);
      }
      
      // Kiểm tra xem đã tải hết dữ liệu chưa
      setState(() {
        if (snapshot.docs.length < _pageSize) {
          _hasMore = false;
        }
      });
    }).catchError((e) {
      // Xử lý lỗi
      print("Lỗi khi tải trang tiếp theo: $e");
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Để giữ tính năng Real-time cho những mục ĐÃ tải:
    // Chúng ta lắng nghe Stream của TOÀN BỘ Collection và giới hạn nó bằng _allLoadedDocs.
    
    // Tuy nhiên, cách dễ nhất là sử dụng stream để lắng nghe các thay đổi và cập nhật danh sách
    // Đơn giản hóa: Chúng ta chỉ cần một StreamBuilder cho trang đầu tiên 
    // và sử dụng LoadNextPage cho các trang sau.
    
    // Nếu bạn muốn Real-time cho TẤT CẢ các document đã tải, bạn cần quản lý 
    // state phức tạp hơn (ví dụ: bọc từng ListTile trong StreamBuilder, hoặc dùng 
    // thư viện chuyên biệt).
    
    // Ở đây, chúng ta tập trung vào Real-time của trang đầu tiên và tải thêm các trang tiếp theo.

    // Stream chỉ lấy 10 mục đầu tiên (hoặc 10 mục tiếp theo, nhưng cần quản lý trạng thái)
    // Để giữ đơn giản cho ví dụ này, chúng ta sẽ hiển thị tất cả các mục đã tải (_allLoadedDocs)
    // và chỉ sử dụng tính năng tải thêm (loadNextPage).

    return Scaffold(
      appBar: AppBar(title: const Text('Phân trang Real-time (Simplified)')),
      body: ListView.builder(
        itemCount: _allLoadedDocs.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _allLoadedDocs.length) {
            // Hiển thị nút Tải thêm nếu còn dữ liệu
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _loadNextPage,
                  child: const Text('Tải thêm'),
                ),
              ),
            );
          }
          
          final doc = _allLoadedDocs[index];
          final data = doc.data() as Map<String, dynamic>;

          return ListTile(
            title: Text(data['name'] ?? 'No Name'),
            subtitle: Text('Email: ${data['email'] ?? 'N/A'}'),
            trailing: Text(doc.id.substring(0, 4)),
          );
        },
      ),
    );
  }
}
