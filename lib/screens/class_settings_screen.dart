import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 수업과목 설정 화면
class ClassSettingsScreen extends StatefulWidget {
  const ClassSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ClassSettingsScreen> createState() => _ClassSettingsScreenState();
}

class _ClassSettingsScreenState extends State<ClassSettingsScreen> {
  // 카테고리 목록
  final List<String> _categories = ['물리치료', '작업치료', '언어치료'];

  // 수업 목록
  final List<Map<String, dynamic>> _classes = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance.collection('classes').get();
      setState(() {
        _classes.clear();
        _classes.addAll(snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카테고리 설정
                  _buildSectionTitle('카테고리 설정'),
                  const SizedBox(height: 16),
                  _buildCategorySection(),
                  const SizedBox(height: 32),

                  // 수업 목록
                  _buildSectionTitle('수업 분류 관리'),
                  const SizedBox(height: 16),
                  _buildClassList(),
                  const SizedBox(height: 24),

                  // 수업 등록 버튼
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _showAddClassDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('수업 등록'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// 카테고리 섹션
  Widget _buildCategorySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              return Chip(
                label: Text(category),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _categories.remove(category);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addCategory,
            icon: const Icon(Icons.add),
            label: const Text('카테고리 추가'),
          ),
        ],
      ),
    );
  }

  /// 수업 목록
  Widget _buildClassList() {
    if (_classes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            '등록된 수업이 없습니다',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final classData = _classes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.school, color: Colors.blue),
            ),
            title: Text(
              classData['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('분류: ${classData['category'] ?? ''}'),
                Text('금액: ${classData['price'] ?? 0}원'),
                Text('시간: ${classData['duration'] ?? 0}분'),
                Text('유형: ${classData['type'] ?? ''}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditClassDialog(classData),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteClass(classData['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 카테고리 추가
  void _addCategory() {
    showDialog(
      context: context,
      builder: (context) {
        String categoryName = '';
        return AlertDialog(
          title: const Text('카테고리 추가'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: '예) 수중재활',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              categoryName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (categoryName.isNotEmpty) {
                  setState(() {
                    _categories.add(categoryName);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  /// 수업 등록 다이얼로그
  void _showAddClassDialog() {
    String selectedCategory = _categories.isNotEmpty ? _categories.first : '';
    String className = '';
    String classType = '정액권(금액차감형)';
    int price = 0;
    int durationHours = 0;
    int durationMinutes = 60;
    String memo = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('수업 등록'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 수업 분류
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: '수업 분류',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 수업명
                    TextField(
                      decoration: const InputDecoration(
                        labelText: '수업명',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        className = value;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 수업 유형
                    DropdownButtonFormField<String>(
                      value: classType,
                      decoration: const InputDecoration(
                        labelText: '수업 유형',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: '정액권(금액차감형)', child: Text('정액권(금액차감형)')),
                        DropdownMenuItem(value: '횟수권(횟수차감형)', child: Text('횟수권(횟수차감형)')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            classType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 수업 금액
                    TextField(
                      decoration: const InputDecoration(
                        labelText: '수업 금액 (단가)',
                        border: OutlineInputBorder(),
                        suffixText: '원',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        price = int.tryParse(value) ?? 0;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 수업 시간
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: '시간',
                              border: OutlineInputBorder(),
                              suffixText: '시간',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              durationHours = int.tryParse(value) ?? 0;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: '분',
                              border: OutlineInputBorder(),
                              suffixText: '분',
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: '60'),
                            onChanged: (value) {
                              durationMinutes = int.tryParse(value) ?? 0;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 메모
                    TextField(
                      decoration: const InputDecoration(
                        labelText: '메모',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        memo = value;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (className.isNotEmpty) {
                      await _addClass(
                        selectedCategory,
                        className,
                        classType,
                        price,
                        durationHours * 60 + durationMinutes,
                        memo,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('등록'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 수업 수정 다이얼로그
  void _showEditClassDialog(Map<String, dynamic> classData) {
    // TODO: 수업 수정 다이얼로그 구현
  }

  /// 수업 추가
  Future<void> _addClass(
    String category,
    String name,
    String type,
    int price,
    int duration,
    String memo,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('classes').add({
        'category': category,
        'name': name,
        'type': type,
        'price': price,
        'duration': duration,
        'memo': memo,
        'created_at': FieldValue.serverTimestamp(),
      });

      await _loadClasses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 수업이 등록되었습니다'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록 실패: $e')),
        );
      }
    }
  }

  /// 수업 삭제
  Future<void> _deleteClass(String classId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수업 삭제'),
        content: const Text('이 수업을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('classes').doc(classId).delete();
        await _loadClasses();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ 수업이 삭제되었습니다'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 실패: $e')),
          );
        }
      }
    }
  }
}
