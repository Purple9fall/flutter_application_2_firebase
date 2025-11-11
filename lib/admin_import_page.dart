import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_person_page.dart';

class AdminImportPage extends StatefulWidget {
  const AdminImportPage({super.key});

  @override
  _AdminImportPageState createState() => _AdminImportPageState();
}

class _AdminImportPageState extends State<AdminImportPage> {
  bool _isLoading = false;
  String? _message;
  int _totalPeople = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('SinhVien').get();
      setState(() {
        _totalPeople = snapshot.docs.length;
      });
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _clearData() async {
    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Cảnh báo'),
        content: Text(
          'Bạn có chắc muốn xóa toàn bộ $_totalPeople người trong cơ sở dữ liệu?\n\nHành động này không thể hoàn tác!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xóa tất cả',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('SinhVien').get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
        _message = '✅ Đã xóa ${snapshot.docs.length} người!';
        _totalPeople = 0;
      });
    } catch (e) {
      setState(() {
        _message = '❌ Lỗi khi xóa: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _viewAllPeople() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('SinhVien').get();

      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có dữ liệu nào')),
        );
      } else {
        // Show list dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Danh sách (${snapshot.docs.length} người)'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.docs[index];
                  final data = doc.data();
                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(data['name'] ?? ''),
                    subtitle: Text(data['email'] ?? ''),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý dữ liệu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCount,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Statistics Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.people,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_totalPeople',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'người trong cơ sở dữ liệu',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Add Person Button
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_add, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Thêm người mới',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nhập thông tin thủ công và lưu vào Firestore',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddPersonPage(),
                            ),
                          ).then((value) {
                            if (value == true) {
                              _loadCount();
                              setState(() {
                                _message = '✅ Đã thêm người mới thành công!';
                              });
                            }
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm người mới'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // View All Button
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.list, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Xem danh sách',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Xem tất cả người trong cơ sở dữ liệu',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _viewAllPeople,
                        icon: const Icon(Icons.visibility),
                        label: const Text('Xem danh sách'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Delete All Button
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Xóa toàn bộ dữ liệu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Xóa tất cả documents trong collection "people"',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading || _totalPeople == 0
                            ? null
                            : _clearData,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.delete_sweep),
                        label: Text(_isLoading ? 'Đang xóa...' : 'Xóa tất cả'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Message
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message!.startsWith('✅')
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _message!.startsWith('✅')
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _message!.startsWith('✅')
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}