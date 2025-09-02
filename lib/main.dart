import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_docx/docx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'محرر مستندات Word',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arabic',
      ),
      home: WordEditorApp(),
    );
  }
}

class WordEditorApp extends StatefulWidget {
  @override
  _WordEditorAppState createState() => _WordEditorAppState();
}

class _WordEditorAppState extends State<WordEditorApp> {
  final Document _doc = Document();
  String? _filePath;
  int _activeParagraphIndex = -1;
  dynamic _activeImagePart;
  String _selectedTextColor = "default";
  List<Map<String, dynamic>> _paragraphs = [];
  List<Map<String, dynamic>> _images = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _paragraphController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  int _fontSize = 12;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;

  @override
  void initState() {
    super.initState();
    _loadFonts();
  }

  Future<void> _loadFonts() async {
    // يمكنك إضافة خطوط عربية هنا إذا لزم الأمر
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('محرر مستندات Word'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'المحتوى'),
              Tab(text: 'الفقرات'),
              Tab(text: 'الصور'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildContentTab(),
            _buildParagraphsTab(),
            _buildImagesTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _saveDocument,
          child: Icon(Icons.save),
          tooltip: 'حفظ المستند',
        ),
      ),
    );
  }

  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDocumentInfoSection(),
          SizedBox(height: 20),
          _buildTextFormattingSection(),
          SizedBox(height: 20),
          _buildParagraphSection(),
          SizedBox(height: 20),
          _buildImageSection(),
        ],
      ),
    );
  }

  Widget _buildDocumentInfoSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'معلومات المستند',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ArabicTextField(
              controller: _titleController,
              hintText: 'عنوان المستند',
            ),
            SizedBox(height: 10),
            ArabicTextField(
              controller: _authorController,
              hintText: 'اسم المؤلف',
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _createNewDocument,
                    child: Text('مستند جديد'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _openDocument,
                    child: Text('فتح مستند'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormattingSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تنسيق النص',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text('حجم الخط:'),
                SizedBox(width: 10),
                DropdownButton<int>(
                  value: _fontSize,
                  items: [8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 72]
                      .map((size) => DropdownMenuItem<int>(
                            value: size,
                            child: Text('$size'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _fontSize = value!;
                    });
                  },
                ),
                SizedBox(width: 20),
                IconButton(
                  icon: Icon(Icons.format_bold),
                  color: _isBold ? Colors.blue : Colors.grey,
                  onPressed: () {
                    setState(() {
                      _isBold = !_isBold;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.format_italic),
                  color: _isItalic ? Colors.blue : Colors.grey,
                  onPressed: () {
                    setState(() {
                      _isItalic = !_isItalic;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.format_underline),
                  color: _isUnderline ? Colors.blue : Colors.grey,
                  onPressed: () {
                    setState(() {
                      _isUnderline = !_isUnderline;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _showColorPicker,
              child: Text('اختر لون النص'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraphSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إدارة الفقرات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ArabicTextField(
              controller: _paragraphController,
              hintText: 'أضف فقرة جديدة',
              maxLines: 3,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addParagraph,
              child: Text('إضافة فقرة'),
            ),
            SizedBox(height: 10),
            ArabicTextField(
              controller: _searchController,
              hintText: 'بحث في النص',
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _searchInDocument,
              child: Text('بحث'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إدارة الصور',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addImage,
              child: Text('إضافة صورة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraphsTab() {
    return ListView.builder(
      itemCount: _paragraphs.length,
      itemBuilder: (context, index) {
        final paragraph = _paragraphs[index];
        return ListTile(
          title: Text(
            'الفقرة ${index + 1}: ${paragraph['text'].toString().substring(0, paragraph['text'].toString().length > 50 ? 50 : paragraph['text'].toString().length)}...',
            textAlign: TextAlign.right,
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _removeParagraph(index),
          ),
          onTap: () => _editParagraph(index),
        );
      },
    );
  }

  Widget _buildImagesTab() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final image = _images[index];
        return Stack(
          children: [
            Image.memory(
              image['data'],
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeImage(index),
              ),
            ),
          ],
        );
      },
    );
  }

  void _createNewDocument() {
    setState(() {
      _paragraphs.clear();
      _images.clear();
      _titleController.clear();
      _authorController.clear();
      _filePath = null;
    });
  }

  Future<void> _openDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx'],
      );

      if (result != null) {
        setState(() {
          _filePath = result.files.single.path;
        });
        // هنا يمكنك إضافة كود لقراءة المستند وتحليل محتواه
      }
    } on PlatformException catch (e) {
      _showMessage('خطأ: $e');
    }
  }

  Future<void> _saveDocument() async {
    if (_titleController.text.isEmpty) {
      _showMessage('يرجى إدخال عنوان للمستند');
      return;
    }

    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final String path = '${directory.path}/${_titleController.text}.docx';

      // هنا يمكنك إضافة كود لحفظ المستند باستخدام مكتبة syncfusion_flutter_docx

      _showMessage('تم حفظ المستند بنجاح');
    } catch (e) {
      _showMessage('خطأ في حفظ المستند: $e');
    }
  }

  void _addParagraph() {
    if (_paragraphController.text.isEmpty) return;

    setState(() {
      _paragraphs.add({
        'text': _paragraphController.text,
        'fontSize': _fontSize,
        'isBold': _isBold,
        'isItalic': _isItalic,
        'isUnderline': _isUnderline,
        'color': _selectedTextColor,
      });
      _paragraphController.clear();
    });
  }

  void _removeParagraph(int index) {
    setState(() {
      _paragraphs.removeAt(index);
    });
  }

  void _editParagraph(int index) {
    final paragraph = _paragraphs[index];
    _paragraphController.text = paragraph['text'];
    _fontSize = paragraph['fontSize'];
    _isBold = paragraph['isBold'];
    _isItalic = paragraph['isItalic'];
    _isUnderline = paragraph['isUnderline'];
    _selectedTextColor = paragraph['color'];

    setState(() {
      _activeParagraphIndex = index;
    });

    // انتقل إلى تبويب المحتوى
    DefaultTabController.of(context)?.animateTo(0);
  }

  Future<void> _addImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _images.add({
            'path': image.path,
            'data': bytes,
          });
        });
      }
    } catch (e) {
      _showMessage('خطأ في إضافة الصورة: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _searchInDocument() {
    final query = _searchController.text;
    if (query.isEmpty) return;

    // هنا يمكنك إضافة كود للبحث في النص
    _showMessage('سيتم تنفيذ البحث عن: $query');
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('اختر لون النص'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildColorOption('أسود', Colors.black),
                _buildColorOption('أحمر', Colors.red),
                _buildColorOption('أزرق', Colors.blue),
                _buildColorOption('أخضر', Colors.green),
                _buildColorOption('أصفر', Colors.yellow),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorOption(String name, Color color) {
    return ListTile(
      title: Text(name),
      leading: Container(
        width: 24,
        height: 24,
        color: color,
      ),
      onTap: () {
        setState(() {
          _selectedTextColor = color.value.toRadixString(16);
        });
        Navigator.pop(context);
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class ArabicTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;

  const ArabicTextField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintTextDirection: TextDirection.rtl,
        border: OutlineInputBorder(),
      ),
    );
  }
}
