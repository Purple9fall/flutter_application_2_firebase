import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'person.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Ô nhập từ khóa
  final TextEditingController _controller = TextEditingController();

  // --- Tiêu chí tìm kiếm ---
  final Map<String, String> _criteriaOptions = const {
    'name': 'Tên',
    'email': 'Email',
    'city': 'Thành phố',
    'ward': 'Phường/Xã',
  };
  String _selectedCriteria = 'name';

  // --- Order by + hướng sắp xếp (mũi tên) ---
  final Map<String, String> _orderByOptions = const {
    'name': 'Tên',
    'email': 'Email',
    'city': 'Thành phố',
    'ward': 'Phường/Xã',
  };
  String _selectedOrderBy = 'name';
  bool _orderDesc = false; // false = tăng dần (arrow_upward), true = giảm dần (arrow_downward)

  // --- Limit: nhập tay ---
  final TextEditingController _limitController = TextEditingController(); // để nhập số
  int? _parsedLimit; // giá trị limit parse được

  // --- Trạng thái dữ liệu ---
  List<Person> people = [];      // danh sách đã nạp từ Firestore
  List<Person> foundPeople = []; // kết quả tìm kiếm
  String? error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _limitController.dispose();
    super.dispose();
  }

  // Nạp dữ liệu Firestore (lọc trước city == "Da Nang")
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      error = null;
    });

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('SinhVien')
          .get();

      setState(() {
        people = snapshot.docs.map((doc) => Person.fromFirestore(doc)).toList();
        foundPeople = [];
        error = null;
      });
    } catch (e) {
      setState(() {
        people = [];
        foundPeople = [];
        error = "Không thể tải dữ liệu từ Firestore: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Placeholder theo tiêu chí
  String _placeholderForCriteria(String criteria) {
    switch (criteria) {
      case 'name':
        return 'Ví dụ: Nguyen Van A';
      case 'email':
        return 'Ví dụ: ten@domain.com';
      case 'city':
        return 'Ví dụ: Da Nang';
      case 'ward':
        return 'Ví dụ: Hai Chau';
      default:
        return 'Nhập từ khóa';
    }
  }

  // Lấy giá trị trường theo key để order
  Comparable _fieldValueForOrder(Person p, String field) {
    switch (field) {
      case 'name':
        return p.name.toLowerCase();
      case 'email':
        return p.email.toLowerCase();
      case 'city':
        return p.address.city.toLowerCase();
      case 'ward':
        return p.address.ward.toLowerCase();
      default:
        return '';
    }
  }

  // Tìm kiếm NHIỀU KẾT QUẢ theo cấu hình (lọc cục bộ people)
  void _search() {
    setState(() {
      final keyword = _controller.text.trim().toLowerCase();
      if (keyword.isEmpty) {
        error = 'Vui lòng nhập từ khóa cần tra cứu';
        foundPeople = [];
        return;
      }

      // Parse limit từ ô nhập
      _parsedLimit = int.tryParse(_limitController.text.trim());
      if (_parsedLimit != null && _parsedLimit! <= 0) {
        _parsedLimit = null; // bỏ qua nếu <= 0
      }

      // Lọc theo tiêu chí
      List<Person> results = people.where((p) {
        switch (_selectedCriteria) {
          case 'name':
            return p.name.toLowerCase().contains(keyword);
          case 'email':
            return p.email.toLowerCase().contains(keyword);
          case 'city':
            return p.address.city.toLowerCase().contains(keyword);
          case 'ward':
            return p.address.ward.toLowerCase().contains(keyword);
          default:
            return false;
        }
      }).toList();

      // Sắp xếp theo orderBy + mũi tên tăng/giảm
      results.sort((a, b) {
        final av = _fieldValueForOrder(a, _selectedOrderBy);
        final bv = _fieldValueForOrder(b, _selectedOrderBy);
        final cmp = av.compareTo(bv);
        return _orderDesc ? -cmp : cmp;
      });

      // Áp dụng limit nếu có
      if (_parsedLimit != null && results.length > _parsedLimit!) {
        results = results.take(_parsedLimit!).toList();
      }

      if (results.isEmpty) {
        error =
            'Không tìm thấy theo "${_criteriaOptions[_selectedCriteria]}" với từ khóa "$keyword"';
        foundPeople = [];
      } else {
        error = null;
        foundPeople = results;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hint = _placeholderForCriteria(_selectedCriteria);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm thông tin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Tải lại dữ liệu',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Hàng 1: Tiêu chí + Từ khóa ---
              Row(
                children: [
                  // Dropdown tiêu chí
                  Flexible(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCriteria,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu chí',
                        border: OutlineInputBorder(),
                      ),
                      items: _criteriaOptions.entries
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.key,
                              child: Text(e.value, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => _selectedCriteria = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Ô nhập từ khóa
                  Flexible(
                    flex: 4,
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: 'Từ khóa',
                        hintText: hint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Xoá',
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              foundPeople = [];
                              error = null;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // --- Hàng 2: Order by + Mũi tên tăng/giảm + Limit (nhập tay) ---
              Row(
                children: [
                  // Order by field
                  Flexible(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _selectedOrderBy,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Order by',
                        border: OutlineInputBorder(),
                      ),
                      items: _orderByOptions.entries
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.key,
                              child: Text(e.value, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => _selectedOrderBy = val);
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Nút mũi tên đổi chiều sắp xếp
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      tooltip: _orderDesc ? 'Đang giảm dần' : 'Đang tăng dần',
                      icon: Icon(_orderDesc
                          ? Icons.arrow_downward
                          : Icons.arrow_upward),
                      onPressed: () => setState(() => _orderDesc = !_orderDesc),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Limit nhập tay
                  Flexible(
                    flex: 2,
                    child: TextField(
                      controller: _limitController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Limit',
                        hintText: 'VD: 20',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Nút tìm kiếm
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _search,
                  icon: const Icon(Icons.search),
                  label: const Text('Tìm kiếm'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Loading
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),

              // Lỗi
              if (error != null && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              // --- Kết quả nhiều người ---
              if (foundPeople.isNotEmpty && !_isLoading) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Kết quả tìm kiếm',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${foundPeople.length} kết quả'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: foundPeople.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = foundPeople[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(p.name),
                        subtitle: Text(
                          p.email.isEmpty ? 'Không có email' : p.email,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(p.address.city, style: const TextStyle(fontSize: 12)),
                            Text(
                              p.address.ward,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        onTap: () {
                          // TODO: mở chi tiết nếu cần
                        },
                      ),
                    );
                  },
                ),
              ],

              // --- Tổng số record đã nạp ---
              if (people.isNotEmpty && !_isLoading) ...[
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Tổng số: ${people.length} người trong cơ sở dữ liệu',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
