import 'dart:io';

import 'package:budget_app/context/variable_holder.dart';
import 'package:budget_app/services/budget_service.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../dto/category_data.dart';

class AddEntryView extends StatefulWidget {
  final VoidCallback onSubmitted;

  const AddEntryView({required this.onSubmitted, Key? key}) : super(key: key);

  @override
  State<AddEntryView> createState() => _AddEntryViewState();
}

class _AddEntryViewState extends State<AddEntryView> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.timestamp();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _commentController = TextEditingController();

  XFile? _receiptImage;
  String? _recognizedRetailer;
  String? _recognizedTotal;

  final ImagePicker _picker = ImagePicker();

  CategoryData? _selectedCategory;
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      List<CategoryData> categories = await BudgetService.fetchCategories();

      setState(() {
        VariableHolder.setCategories(categories);
        _loadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _loadingCategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading categories: $e")),
      );
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      "date": DateFormat("yyyy-MM-dd").format(_selectedDate),
      "description": _descriptionController.text,
      "value": double.tryParse(_valueController.text),
      "category": {
        "name": _selectedCategory?.name,
        "type": _selectedCategory?.type
      },
      "comment": _commentController.text,
    };

    try {
      final response = await BudgetService.submitTransaction(data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Entry submitted successfully")),
        );
        _formKey.currentState!.reset();
        setState(() {});

        widget.onSubmitted();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting entry: $e")),
      );
    }
  }

  String _adjustComma(String input) {
    return double.parse(input.replaceAll(',', '.')).toString();
  }

  String? _validateComma(String? value) {
    if (value == null || double.tryParse(_adjustComma(value)) == null) {
      return "Enter a valid number";
    } else {
      _valueController.text = _adjustComma(value);
      return null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source);

    if (image == null) return;

    setState(() {
      _receiptImage = image;
    });

    await _runOCR(image);
  }

  Future<void> _runOCR(XFile image) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    String fullText = recognizedText.text;

    // Very simple extraction logic — you can refine this later
    final retailer = _extractRetailer(fullText);
    final total = _extractTotal(fullText);
    final date = _extractDate(fullText);

    setState(() {
      _recognizedRetailer = retailer;
      _recognizedTotal = total;
    });

    // Prefill the form fields
    if (retailer != null) _descriptionController.text = retailer;
    if (total != null) _valueController.text = total;
    if (date != null) {
      DateTime? parsedDate = _parseDateFlexible(date);
      _selectedDate = parsedDate != null ? parsedDate : DateTime.parse(date);
    }
  }

  String? _extractRetailer(String text) {
    // Heuristic: take the first non-empty line as retailer name
    final lines = text.split('\n').map((l) => l.trim()).toList();
    for (final line in lines) {
      if (line.isNotEmpty && line.length > 3 && !line.contains(RegExp(r'\d'))) {
        return line;
      }
    }
    return null;
  }

  String? _extractTotal(String text) {
    // Look for something like: 12.34 or 1,234.50 or EUR 10,99 etc.
    final regex = RegExp(
        r'((Total|Summe|Gesamt)[^\d]*)?(\d{1,4}[.,]\d{2})',
        caseSensitive: false);

    final match = regex.firstMatch(text);
    if (match != null) {
      return match.group(3)?.replaceAll(',', '.');
    }

    return null;
  }

  String? _extractDate(String text) {
    // Very broad regex that matches most receipt date formats
    final regex = RegExp(
      r'(\d{1,2}[.\-\/ ]\d{1,2}[.\-\/ ]\d{2,4})|'
      r'(\d{4}[.\-\/]\d{1,2}[.\-\/]\d{1,2})|'
      r'(\d{1,2} (Jan|Feb|Mar|Apr|Mai|May|Jun|Jul|Aug|Sep|Sept|Okt|Oct|Nov|Dec)[a-z]* \d{2,4})',
      caseSensitive: false,
    );

    final match = regex.firstMatch(text);
    if (match == null) return null;

    String raw = match.group(0)!;

    // Normalize spaces
    raw = raw.trim();

    // Optional: Normalize to yyyy-MM-dd for backend compatibility
    try {
      final parsed = _parseDateFlexible(raw);
      if (parsed != null) {
        return parsed.toIso8601String().split('T').first; // yyyy-MM-dd
      }
    } catch (_) {}

    return raw; // fallback
  }

  DateTime? _parseDateFlexible(String raw) {
    final candidates = [
      "dd.MM.yyyy", "d.M.yyyy", "dd.MM.yy", "d.M.yy",
      "yyyy-MM-dd", "dd-MM-yyyy", "MM/dd/yyyy", "dd/MM/yyyy",
      "dd MMM yyyy", "d MMM yyyy",
      "dd MMM yy",   "d MMM yy",
    ];

    for (final format in candidates) {
      try {
        return DateFormat(format).parseStrict(raw);
      } catch (_) {}
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Entry")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loadingCategories
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.camera_alt),
                          label: Text("Take Photo"),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: Icon(Icons.upload),
                          label: Text("Upload Receipt"),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                      ],
                    ),
                    if (_receiptImage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Image.file(File(_receiptImage!.path), height: 120),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Date: ${DateFormat("dd.MM.yyyy").format(_selectedDate)}",
                          ),
                        ),
                        TextButton(
                          onPressed: () => _pickDate(context),
                          child: const Text("Select Date"),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: "Description"),
                      textInputAction:
                          TextInputAction.next, // moves to next field
                      validator: (value) => value == null || value.isEmpty
                          ? "Enter description"
                          : null,
                    ),
                    TextFormField(
                        controller: _valueController,
                        decoration: const InputDecoration(labelText: "Value"),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textInputAction: TextInputAction.next,
                        // moves to next field
                        validator: (value) => _validateComma(value)),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory?.name,
                      items: VariableHolder.getCategories()
                          .map((cat) => DropdownMenuItem(
                              value: cat.name,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: cat.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    cat.name,
                                  ),
                                ],
                              )))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory =
                              BudgetService.findCategory(value as String);
                        });
                      },
                      decoration: const InputDecoration(labelText: "Category"),
                      validator: (value) =>
                          value == null ? "Please select a category" : null,
                    ),
                    TextFormField(
                      controller: _commentController,
                      decoration: const InputDecoration(labelText: "Comment"),
                      textInputAction: TextInputAction.done,
                      maxLines: 3,
                      onFieldSubmitted: (_) => _submitForm(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text("Submit"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
