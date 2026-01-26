import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 자료실 화면
class FileLibraryScreen extends StatefulWidget {
  const FileLibraryScreen({Key? key}) : super(key: key);

  @override
  State<FileLibraryScreen> createState() => _FileLibraryScreenState();
}

class _FileLibraryScreenState extends State<FileLibraryScreen> {
  List<FileItem> _files = [];
  String _selectedCategory = '전체';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() {
    setState(() {
      _isLoading = true;
    });

    // Mock 데이터
    final now = DateTime.now();
    _files = [
      FileItem(
        id: 'file_001',
        name: '수중 치료 가이드라인.pdf',
        category: '치료 가이드',
        size: '2.5 MB',
        uploadDate: now.subtract(const Duration(days: 1)),
        uploaderName: '김치료',
        downloads: 24,
      ),
      FileItem(
        id: 'file_002',
        name: '환자 평가 양식.xlsx',
        category: '양식',
        size: '156 KB',
        uploadDate: now.subtract(const Duration(days: 3)),
        uploaderName: '이관리',
        downloads: 45,
      ),
      FileItem(
        id: 'file_003',
        name: '보강권 발급 절차.pdf',
        category: '운영 매뉴얼',
        size: '890 KB',
        uploadDate: now.subtract(const Duration(days: 5)),
        uploaderName: '박운영',
        downloads: 18,
      ),
      FileItem(
        id: 'file_004',
        name: '1월 치료 일정표.pdf',
        category: '일정',
        size: '345 KB',
        uploadDate: now.subtract(const Duration(days: 7)),
        uploaderName: '최관리',
        downloads: 67,
      ),
      FileItem(
        id: 'file_005',
        name: '안전 수칙 교육 자료.pptx',
        category: '교육 자료',
        size: '4.2 MB',
        uploadDate: now.subtract(const Duration(days: 10)),
        uploaderName: '정안전',
        downloads: 32,
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  List<FileItem> get _filteredFiles {
    if (_selectedCategory == '전체') {
      return _files;
    }
    return _files.where((f) => f.category == _selectedCategory).toList();
  }

  List<String> get _categories {
    final categories = <String>{'전체'};
    for (var file in _files) {
      categories.add(file.category);
    }
    return categories.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('자료실'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _showUploadDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 필터
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // 통계
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '전체 ${_filteredFiles.length}개 파일',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '총 다운로드: ${_files.fold<int>(0, (sum, file) => sum + file.downloads)}회',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // 파일 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFiles.isEmpty
                    ? Center(
                        child: Text(
                          '파일이 없습니다',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredFiles.length,
                        itemBuilder: (context, index) {
                          final file = _filteredFiles[index];
                          return _buildFileCard(file);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(FileItem file) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _buildFileIcon(file.name),
        title: Text(
          file.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('카테고리: ${file.category}'),
            Text('크기: ${file.size} · ${file.uploaderName}'),
            Text(
              '${DateFormat('yyyy-MM-dd').format(file.uploadDate)} · 다운로드 ${file.downloads}회',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => _downloadFile(file),
        ),
      ),
    );
  }

  Widget _buildFileIcon(String fileName) {
    IconData icon;
    Color color;

    if (fileName.endsWith('.pdf')) {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
      icon = Icons.table_chart;
      color = Colors.green;
    } else if (fileName.endsWith('.pptx') || fileName.endsWith('.ppt')) {
      icon = Icons.slideshow;
      color = Colors.orange;
    } else if (fileName.endsWith('.docx') || fileName.endsWith('.doc')) {
      icon = Icons.description;
      color = Colors.blue;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.grey;
    }

    return Icon(icon, color: color, size: 40);
  }

  void _downloadFile(FileItem file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('파일 다운로드'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('파일: ${file.name}'),
            const SizedBox(height: 8),
            Text('크기: ${file.size}'),
            const SizedBox(height: 16),
            const Text(
              '💡 웹 버전에서는 파일 다운로드가 제한됩니다.\n모바일 앱에서 다운로드 가능합니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ ${file.name} 다운로드 완료! (시뮬레이션)'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('다운로드'),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('파일 업로드'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('업로드할 파일을 선택하세요.'),
            SizedBox(height: 16),
            Text(
              '💡 웹 버전에서는 파일 업로드가 제한됩니다.\n모바일 앱에서 업로드 가능합니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ 파일 업로드 완료! (시뮬레이션)'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('선택'),
          ),
        ],
      ),
    );
  }
}

/// 파일 정보 모델
class FileItem {
  final String id;
  final String name;
  final String category;
  final String size;
  final DateTime uploadDate;
  final String uploaderName;
  final int downloads;

  FileItem({
    required this.id,
    required this.name,
    required this.category,
    required this.size,
    required this.uploadDate,
    required this.uploaderName,
    required this.downloads,
  });
}
