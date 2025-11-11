import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddPersonPage extends StatefulWidget {
  const AddPersonPage({super.key});

  @override
  _AddPersonPageState createState() => _AddPersonPageState();
}

class _AddPersonPageState extends State<AddPersonPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Controllers for personal info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // Controllers for address
  final _cityController = TextEditingController();
  final _wardController = TextEditingController();
  final _streetController = TextEditingController();
  final _houseNumberController = TextEditingController();

  // List of schools
  final List<Map<String, dynamic>> _schools = [];

  // Controllers for adding new school
  final _schoolNameController = TextEditingController();
  final _schoolAddressController = TextEditingController();
  final _yearInController = TextEditingController();
  final _yearOutController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _wardController.dispose();
    _streetController.dispose();
    _houseNumberController.dispose();
    _schoolNameController.dispose();
    _schoolAddressController.dispose();
    _yearInController.dispose();
    _yearOutController.dispose();
    super.dispose();
  }

  void _addSchool() {
    if (_schoolNameController.text.isEmpty ||
        _yearInController.text.isEmpty ||
        _yearOutController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin trường học')),
      );
      return;
    }

    setState(() {
      _schools.add({
        'name': _schoolNameController.text.trim(),
        'yearIn': int.parse(_yearInController.text.trim()),
        'yearOut': int.parse(_yearOutController.text.trim()),
        'address': _schoolAddressController.text.trim(),
      });

      // Clear controllers
      _schoolNameController.clear();
      _schoolAddressController.clear();
      _yearInController.clear();
      _yearOutController.clear();
    });
  }

  void _removeSchool(int index) {
    setState(() {
      _schools.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_schools.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 trường học')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare data
      final data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'address': {
          'city': _cityController.text.trim(),
          'ward': _wardController.text.trim(),
          'street': _streetController.text.trim(),
          'houseNumber': _houseNumberController.text.trim(),
        },
        'school': _schools,
      };

      // Add to Firestore
      await FirebaseFirestore.instance.collection('SinhVien').add(data);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Thêm thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        // Go back
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm người mới'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Personal Information Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '👤 Thông tin cá nhân',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập họ tên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!value.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Address Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📍 Địa chỉ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _houseNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Số nhà *',
                        border: OutlineInputBorder(),
                        hintText: 'VD: 123/45',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số nhà';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _streetController,
                      decoration: const InputDecoration(
                        labelText: 'Đường *',
                        border: OutlineInputBorder(),
                        hintText: 'VD: Le Duan',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên đường';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _wardController,
                      decoration: const InputDecoration(
                        labelText: 'Phường/Quận *',
                        border: OutlineInputBorder(),
                        hintText: 'VD: Hai Chau',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập phường/quận';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'Thành phố *',
                        border: OutlineInputBorder(),
                        hintText: 'VD: Da Nang',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập thành phố';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // School Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎓 Trường học',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add School Form
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _schoolNameController,
                            decoration: const InputDecoration(
                              labelText: 'Tên trường',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _yearInController,
                                  decoration: const InputDecoration(
                                    labelText: 'Năm vào',
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _yearOutController,
                                  decoration: const InputDecoration(
                                    labelText: 'Năm ra',
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _schoolAddressController,
                            decoration: const InputDecoration(
                              labelText: 'Địa điểm',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _addSchool,
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm trường'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // List of added schools
                    if (_schools.isNotEmpty) ...[
                      const Text(
                        'Danh sách trường đã thêm:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._schools.asMap().entries.map((entry) {
                        final index = entry.key;
                        final school = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.green.shade50,
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            title: Text(school['name']),
                            subtitle: Text(
                              '${school['yearIn']} - ${school['yearOut']} | ${school['address']}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeSchool(index),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSubmitting ? 'Đang lưu...' : 'Lưu thông tin',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}