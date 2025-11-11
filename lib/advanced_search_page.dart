import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'person.dart';

class AdvancedSearchPage extends StatefulWidget {
  const AdvancedSearchPage({super.key});

  @override
  _AdvancedSearchPageState createState() => _AdvancedSearchPageState();
}

class _AdvancedSearchPageState extends State<AdvancedSearchPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _wardController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _yearFromController = TextEditingController();
  final _yearToController = TextEditingController();

  List<Person> _allPeople = [];
  List<Person> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  // Filter options
  bool _searchByName = false;
  bool _searchByEmail = false;
  bool _searchByCity = false;
  bool _searchByWard = false;
  bool _searchBySchool = false;
  bool _searchByYearRange = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _wardController.dispose();
    _schoolNameController.dispose();
    _yearFromController.dispose();
    _yearToController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('SinhVien').get();
      
      setState(() {
        _allPeople = snapshot.docs.map((doc) => Person.fromFirestore(doc)).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Không thể tải dữ liệu: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _performSearch() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if at least one filter is selected
    if (!_searchByName && !_searchByEmail && !_searchByCity && 
        !_searchByWard && !_searchBySchool && !_searchByYearRange) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 tiêu chí tìm kiếm'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _hasSearched = true;
      _searchResults = _allPeople.where((person) {
        bool matches = true;

        // Filter by name
        if (_searchByName && _nameController.text.isNotEmpty) {
          matches = matches && 
              person.name.toLowerCase().contains(_nameController.text.toLowerCase());
        }

        // Filter by email
        if (_searchByEmail && _emailController.text.isNotEmpty) {
          matches = matches && 
              person.email.toLowerCase().contains(_emailController.text.toLowerCase());
        }

        // Filter by city
        if (_searchByCity && _cityController.text.isNotEmpty) {
          matches = matches && 
              person.address.city.toLowerCase().contains(_cityController.text.toLowerCase());
        }

        // Filter by ward
        if (_searchByWard && _wardController.text.isNotEmpty) {
          matches = matches && 
              person.address.ward.toLowerCase().contains(_wardController.text.toLowerCase());
        }

        // Filter by school name
        if (_searchBySchool && _schoolNameController.text.isNotEmpty) {
          matches = matches && 
              person.school.any((school) => 
                  school.name.toLowerCase().contains(_schoolNameController.text.toLowerCase()));
        }

        // Filter by year range
        if (_searchByYearRange) {
          int? yearFrom = int.tryParse(_yearFromController.text);
          int? yearTo = int.tryParse(_yearToController.text);
          
          if (yearFrom != null || yearTo != null) {
            matches = matches && person.school.any((school) {
              bool yearMatch = true;
              if (yearFrom != null) {
                yearMatch = yearMatch && school.yearIn >= yearFrom;
              }
              if (yearTo != null) {
                yearMatch = yearMatch && school.yearOut <= yearTo;
              }
              return yearMatch;
            });
          }
        }

        return matches;
      }).toList();
    });
  }

  void _resetSearch() {
    setState(() {
      _nameController.clear();
      _emailController.clear();
      _cityController.clear();
      _wardController.clear();
      _schoolNameController.clear();
      _yearFromController.clear();
      _yearToController.clear();
      
      _searchByName = false;
      _searchByEmail = false;
      _searchByCity = false;
      _searchByWard = false;
      _searchBySchool = false;
      _searchByYearRange = false;
      
      _searchResults = [];
      _hasSearched = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm nâng cao'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Tải lại dữ liệu',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  // Search Filters Section
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Info Card
                        Card(
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Chọn các tiêu chí và nhập thông tin để tìm kiếm',
                                    style: TextStyle(color: Colors.blue.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Name Filter
                        _buildFilterTile(
                          title: 'Tìm theo tên',
                          value: _searchByName,
                          onChanged: (val) => setState(() => _searchByName = val!),
                          child: TextFormField(
                            controller: _nameController,
                            enabled: _searchByName,
                            decoration: const InputDecoration(
                              labelText: 'Nhập tên',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                        ),

                        // Email Filter
                        _buildFilterTile(
                          title: 'Tìm theo email',
                          value: _searchByEmail,
                          onChanged: (val) => setState(() => _searchByEmail = val!),
                          child: TextFormField(
                            controller: _emailController,
                            enabled: _searchByEmail,
                            decoration: const InputDecoration(
                              labelText: 'Nhập email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                        ),

                        // City Filter
                        _buildFilterTile(
                          title: 'Tìm theo thành phố',
                          value: _searchByCity,
                          onChanged: (val) => setState(() => _searchByCity = val!),
                          child: TextFormField(
                            controller: _cityController,
                            enabled: _searchByCity,
                            decoration: const InputDecoration(
                              labelText: 'Nhập thành phố',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city),
                              hintText: 'VD: Da Nang',
                            ),
                          ),
                        ),

                        // Ward Filter
                        _buildFilterTile(
                          title: 'Tìm theo phường/quận',
                          value: _searchByWard,
                          onChanged: (val) => setState(() => _searchByWard = val!),
                          child: TextFormField(
                            controller: _wardController,
                            enabled: _searchByWard,
                            decoration: const InputDecoration(
                              labelText: 'Nhập phường/quận',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                              hintText: 'VD: Hai Chau',
                            ),
                          ),
                        ),

                        // School Filter
                        _buildFilterTile(
                          title: 'Tìm theo tên trường',
                          value: _searchBySchool,
                          onChanged: (val) => setState(() => _searchBySchool = val!),
                          child: TextFormField(
                            controller: _schoolNameController,
                            enabled: _searchBySchool,
                            decoration: const InputDecoration(
                              labelText: 'Nhập tên trường',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.school),
                            ),
                          ),
                        ),

                        // Year Range Filter
                        _buildFilterTile(
                          title: 'Tìm theo khoảng năm học',
                          value: _searchByYearRange,
                          onChanged: (val) => setState(() => _searchByYearRange = val!),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _yearFromController,
                                  enabled: _searchByYearRange,
                                  decoration: const InputDecoration(
                                    labelText: 'Từ năm',
                                    border: OutlineInputBorder(),
                                    hintText: '2015',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _yearToController,
                                  enabled: _searchByYearRange,
                                  decoration: const InputDecoration(
                                    labelText: 'Đến năm',
                                    border: OutlineInputBorder(),
                                    hintText: '2020',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _performSearch,
                                icon: const Icon(Icons.search),
                                label: const Text('Tìm kiếm'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _resetSearch,
                                icon: const Icon(Icons.clear),
                                label: const Text('Đặt lại'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Results Section
                        if (_hasSearched) ...[
                          Card(
                            color: _searchResults.isEmpty 
                                ? Colors.orange.shade50 
                                : Colors.green.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    _searchResults.isEmpty 
                                        ? Icons.search_off 
                                        : Icons.check_circle,
                                    color: _searchResults.isEmpty 
                                        ? Colors.orange.shade700 
                                        : Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _searchResults.isEmpty
                                          ? 'Không tìm thấy kết quả nào'
                                          : 'Tìm thấy ${_searchResults.length} kết quả',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _searchResults.isEmpty 
                                            ? Colors.orange.shade700 
                                            : Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Results List
                          ..._searchResults.map((person) => _buildPersonCard(person)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterTile({
    required String title,
    required bool value,
    required Function(bool?) onChanged,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              value: value,
              onChanged: onChanged,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (value) ...[
              const SizedBox(height: 12),
              child,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPersonCard(Person person) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            person.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          person.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(person.email),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address
                const Text(
                  '📍 Địa chỉ:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(person.address.fullAddress),
                ),
                const SizedBox(height: 12),

                // Schools
                const Text(
                  '🎓 Trường học:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                ...person.school.map((school) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            school.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '📅 ${school.yearIn} - ${school.yearOut}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                          Text(
                            '📍 ${school.address}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}