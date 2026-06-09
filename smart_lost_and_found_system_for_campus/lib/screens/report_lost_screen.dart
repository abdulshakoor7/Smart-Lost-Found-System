import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api_service.dart';
import '../user_session.dart';
import 'map_picker_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class ReportLostScreen extends StatefulWidget {
  const ReportLostScreen({super.key});

  @override
  State<ReportLostScreen> createState() => _ReportLostScreenState();
}

class _ReportLostScreenState extends State<ReportLostScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers matching the Figma Design
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();

  String _selectedCategory = 'Electronics';
  PlatformFile? _pickedFile;
  bool _isSubmitting = false;

  // --- FIGMA THEME COLORS ---
  final Color _bg = const Color(0xFF0F172A); // Deep Navy
  final Color _surface = const Color(0xFF1E293B); // Charcoal Card
  final Color _primaryBlue = const Color(0xFF2563EB);
  @override
  void initState() {
    super.initState();
    // Pre-fill contact info from session
    _contactNameController.text = UserSession.name;
    _contactEmailController.text = UserSession.email;

  }

  // --- 1. PICK FILE ---
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg'],
        withData: true,
      );
      if (result != null) setState(() => _pickedFile = result.files.first);
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  // --- 2. IMAGE PREVIEW ---
  ImageProvider? _getImageProvider() {
    if (_pickedFile == null) return null;
    if (kIsWeb) return MemoryImage(_pickedFile!.bytes!);
    return FileImage(File(_pickedFile!.path!));
  }

  // --- 3. DATE & TIME  PICKER ---
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
  // --- 4. SUBMIT REPORT ---
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a location'),
          backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSubmitting = true);
    Map<String, String> data = {
      'title': _titleController.text.trim(),
      'category': _selectedCategory,
      'location': _locationController.text.trim(),
      'description': _descController.text.trim(),
      'item_type': 'LOST',
      'status': 'PENDING',
      // CRITICAL: Explicitly send email so "My Items" screen can find it
      'user_email': UserSession.email,
    };
    // Pass the entire list of images!
    bool success = await ApiService.reportItem(
      data: data,
      files: [_pickedFile!], // Wraps the single file into the required List
    );

    if (mounted) setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lost Item Reported Successfully!'),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('Report a Lost Item',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- IMAGE UPLOAD BOX (Figma Style) ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: _bg, // Darker inside
                  borderRadius: BorderRadius.circular(16),
                  // Dashed border simulation
                  border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignInside),
                  image: _pickedFile != null
                      ? DecorationImage(
                          image: _getImageProvider()!,
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                              Colors.black54, BlendMode.darken))
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: _primaryBlue.withValues(alpha: 0.2),
                          shape: BoxShape.circle),
                      child: Icon(Icons.camera_alt_rounded,
                          size: 32, color: _primaryBlue),
                    ),
                    const SizedBox(height: 16),
                    const Text('Upload Photos',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Optional but Recommended',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _pickFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        // Dark blue button
                        foregroundColor: _primaryBlue,
                        // Blue text
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                          _pickedFile == null ? 'Add Photos' : 'Change Photo',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- INPUT FIELDS ---
              _buildLabel('What did you lose?'),
              _buildInput(_titleController, 'e.g., iPhone 13 Pro'),

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
              _buildLabel('Description'),
              _buildInput(_descController,
                  'Add details like color, brand, or any scratches...',
                  maxLines: 4),

              const SizedBox(height: 16),

              // --- MAP LOCATION BOX ---
              _buildLabel('Where did you last see it?'),
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
                      MaterialPageRoute(
                          builder: (context) => const MapPickerScreen()),
                    );

                    if (result != null) {
                      setState(() {
                        _locationController.text = result['text'];
                      });
                    }
                  } else {
                    // 3. Inform the user if they denied permission
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "Location permission is required to use the map.")));
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
                      Icon(Icons.location_on,
                          color: _locationController.text.isEmpty
                              ? Colors.grey
                              : _primaryBlue,
                          size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _locationController.text.isEmpty
                              ? 'e.g., Main Library, 2nd Floor'
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
              _buildLabel('When did you lose it?'),
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

              const SizedBox(height: 24),
              _buildLabel('How can we reach you if it\'s found?'),
              _buildInput(_contactNameController, 'Jane Doe'),
              const SizedBox(height: 12),
              _buildInput(_contactEmailController, 'jane.doe@campus.edu'),

              const SizedBox(height: 32),

              // --- SUBMIT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
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
