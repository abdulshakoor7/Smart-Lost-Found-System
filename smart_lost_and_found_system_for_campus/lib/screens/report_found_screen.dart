import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../user_session.dart';
import 'map_picker_screen.dart';


class ReportFoundScreen extends StatefulWidget {
  const ReportFoundScreen({super.key});

  @override
  State<ReportFoundScreen> createState() => _ReportFoundScreenState();
}

class _ReportFoundScreenState extends State<ReportFoundScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers matching the Figma Design
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String _selectedCategory = 'Electronics';

  // List to hold up to 3 images
  List<PlatformFile> _pickedFiles = [];
  bool _isSubmitting = false;

  // --- FIGMA THEME COLORS ---
  final Color _bg = const Color(0xFF0F172A); // Deep Navy
  final Color _surface = const Color(0xFF1E293B); // Charcoal Card
  final Color _primaryBlue = const Color(0xFF2563EB); // Bright Blue
  final Color _textGrey = const Color(0xFF94A3B8);

  // --- 1. PICK MULTIPLE FILES (MAX 3) ---
  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg'],
        allowMultiple: true, // Allow multiple images
        withData: true,
      );

      if (result != null) {
        setState(() {
          // Add new files to existing ones, limit to 3
          _pickedFiles.addAll(result.files);
          if (_pickedFiles.length > 3) {
            _pickedFiles = _pickedFiles.sublist(0, 3);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Maximum 3 photos allowed.'),
                  backgroundColor: Colors.orange),
            );
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking files: $e");
    }
  }

  // Remove a selected image
  void _removeFile(int index) {
    setState(() {
      _pickedFiles.removeAt(index);
    });
  }

  // --- 2. DATE & TIME PICKER ---
  Future<void> _selectDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme:
                ColorScheme.dark(primary: _primaryBlue, surface: _surface),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
                colorScheme:
                    ColorScheme.dark(primary: _primaryBlue, surface: _surface)),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          // Format: 2023-10-25 14:30
          _dateController.text =
              "${pickedDate.toString().substring(0, 10)} ${pickedTime.format(context)}";
        });
      }
    }
  }

  // --- 3. SUBMIT REPORT ---
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a location on the map'),
          backgroundColor: Colors.orange));
      return;
    }

    if (_pickedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please upload at least one photo for AI analysis'),
          backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSubmitting = true);

    Map<String, String> data = {
      'title': _titleController.text.trim(),
      'category': _selectedCategory,
      'location': _locationController.text.trim(),
      'description': _descController.text.trim(),
      'item_type': 'FOUND',
      'status': 'PENDING',
      'user_email': UserSession.email, // Link to current user
    };

    // Sending the FIRST image to backend (Backend currently expects 1 image)
    PlatformFile primaryFile = _pickedFiles.first;

    // Pass the entire list of images!
    bool success = await ApiService.reportItem(
      data: data,
      files: _pickedFiles,
    );

    if (mounted) setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Found Item Reported Successfully!'),
          backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to submit. Check connection.'),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text('Report Found Item',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Please provide as much detail as possible to help the owner.",
                  style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              const SizedBox(height: 24),

              // --- IMAGE UPLOAD BOX (MAX 3) ---
              const Text('Photos',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignInside),
                ),
                child: _pickedFiles.isEmpty
                    ? InkWell(
                        onTap: _pickFiles,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 40, color: _primaryBlue),
                            const SizedBox(height: 12),
                            const Text('Add Photos (up to 3)',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Tap to add photos',
                                style:
                                    TextStyle(color: _textGrey, fontSize: 12)),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _pickedFiles.asMap().entries.map((entry) {
                              int idx = entry.key;
                              PlatformFile file = entry.value;
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.all(8),
                                    height: 80,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: kIsWeb
                                            ? MemoryImage(file.bytes!)
                                            : FileImage(File(file.path!))
                                                as ImageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: InkWell(
                                      onTap: () => _removeFile(idx),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 16),
                                      ),
                                    ),
                                  )
                                ],
                              );
                            }).toList(),
                          ),
                          if (_pickedFiles.length < 3)
                            TextButton.icon(
                              onPressed: _pickFiles,
                              icon: Icon(Icons.add, color: _primaryBlue),
                              label: Text("Add more",
                                  style: TextStyle(color: _primaryBlue)),
                            )
                        ],
                      ),
              ),
              const SizedBox(height: 32),

              const Text('Details',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // --- INPUT FIELDS ---
              _buildLabel('What did you find?'),
              _buildInput(_titleController, 'e.g., Black Water Bottle'),

              const SizedBox(height: 16),
              _buildLabel('Category'),
              _buildDropdown([
                'Electronics',
                'Bags',
                'IDs/Cards',
                'Keys',
                'Clothing',
                'Others'
              ]),

              const SizedBox(height: 16),

              // --- MAP LOCATION BOX ---
              _buildLabel('Where did you find it?'),
              InkWell(
                // Ensure your onTap looks EXACTLY like this:
                onTap: () async {
                  // 1. Ask for Permission
                  var status = await Permission.location.request();

                  // 2. Only proceed if permission is GRANTED
                  if (status.isGranted) {
                    if (!context.mounted) return;
                    final Map<String, dynamic>? result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
                    );

                    if (result != null) {
                      setState(() {
                        _locationController.text = result['text'];
                      });
                    }
                  } else {
                    // 3. Inform the user if they denied permission
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Location permission is required to use the map."))
                    );
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.transparent)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _locationController.text.isEmpty
                              ? 'e.g., Library, 2nd Floor'
                              : _locationController.text,
                          style: TextStyle(
                              color: _locationController.text.isEmpty
                                  ? Colors.grey[600]
                                  : Colors.white,
                              fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- DATE & TIME PICKER ---
              _buildLabel('When did you find it?'),
              InkWell(
                onTap: _selectDateTime,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                      color: _surface, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          _dateController.text.isEmpty
                              ? 'Select date and time'
                              : _dateController.text,
                          style: TextStyle(
                              color: _dateController.text.isEmpty
                                  ? Colors.grey[600]
                                  : Colors.white,
                              fontSize: 14)),
                      const Icon(Icons.calendar_today,
                          color: Colors.grey, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              _buildLabel('Description'),
              _buildInput(_descController,
                  'Add details like color, brand, or any identifying marks.',
                  maxLines: 4),

              const SizedBox(height: 32),

              // --- SUBMIT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Report',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)));

  Widget _buildInput(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (val) => val!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdown(List<String> items) {
    return DropdownButtonFormField<String>(
      dropdownColor: _surface,
      decoration: InputDecoration(
          filled: true,
          fillColor: _surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      value: _selectedCategory,
      items: items
          .map((val) => DropdownMenuItem(value: val, child: Text(val)))
          .toList(),
      onChanged: (val) => setState(() => _selectedCategory = val!),
    );
  }
}
