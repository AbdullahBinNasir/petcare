import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../models/health_record_model.dart';
import '../../services/health_record_service.dart';
import '../../services/auth_service.dart';

class AddHealthRecordScreen extends StatefulWidget {
  final String petId;

  const AddHealthRecordScreen({
    super.key,
    required this.petId,
  });

  @override
  State<AddHealthRecordScreen> createState() => _AddHealthRecordScreenState();
}

class _AddHealthRecordScreenState extends State<AddHealthRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _medicationController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  HealthRecordType _selectedType = HealthRecordType.checkup;
  DateTime _recordDate = DateTime.now();
  DateTime? _nextDueDate;
  bool _isLoading = false;
  
  // File upload variables
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<dynamic> _selectedFiles = []; // Changed to dynamic to handle both File and XFile
  List<String> _uploadedFileUrls = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  int _uploadedFilesCount = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _medicationController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Health Record'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveHealthRecord,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Record Type
                    DropdownButtonFormField<HealthRecordType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Record Type *',
                        border: OutlineInputBorder(),
                      ),
                      items: HealthRecordType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Record Date
                    InkWell(
                      onTap: _selectRecordDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Record Date *',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('MMM dd, yyyy').format(_recordDate)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Next Due Date
                    InkWell(
                      onTap: _selectNextDueDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Next Due Date (Optional)',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(_nextDueDate != null 
                            ? DateFormat('MMM dd, yyyy').format(_nextDueDate!)
                            : 'Select next due date'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Medication fields (for medication and vaccination types)
                    if (_selectedType == HealthRecordType.medication || 
                        _selectedType == HealthRecordType.vaccination) ...[
                      TextFormField(
                        controller: _medicationController,
                        decoration: const InputDecoration(
                          labelText: 'Medication/Vaccine Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _dosageController,
                        decoration: const InputDecoration(
                          labelText: 'Dosage',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // File Upload Section
                    _buildFileUploadSection(),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isUploading) ? null : _saveHealthRecord,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: (_isLoading || _isUploading)
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(_isUploading ? 'Uploading files...' : 'Saving...'),
                                    ],
                                  ),
                                  if (_isUploading && _selectedFiles.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: _uploadProgress,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_uploadedFilesCount}/${_selectedFiles.length} files uploaded',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ],
                              )
                            : const Text('Save Health Record'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _selectRecordDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() => _recordDate = date);
    }
  }

  Future<void> _selectNextDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _nextDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      setState(() => _nextDueDate = date);
    }
  }

  Future<void> _saveHealthRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final healthService = Provider.of<HealthRecordService>(context, listen: false);

      if (authService.currentUser == null) {
        _showErrorSnackBar('User not authenticated');
        return;
      }

      // Upload files if any are selected
      List<String> attachmentUrls = [];
      if (_selectedFiles.isNotEmpty) {
        setState(() => _isUploading = true);
        attachmentUrls = await _uploadFiles();
        setState(() => _isUploading = false);
      }

      final healthRecord = HealthRecordModel(
        id: '', // Will be set by Firestore
        petId: widget.petId,
        veterinarianId: authService.currentUser!.uid,
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        recordDate: _recordDate,
        nextDueDate: _nextDueDate,
        medication: _medicationController.text.trim().isNotEmpty 
            ? _medicationController.text.trim() 
            : null,
        dosage: _dosageController.text.trim().isNotEmpty 
            ? _dosageController.text.trim() 
            : null,
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
        attachmentUrls: attachmentUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await healthService.addHealthRecord(healthRecord);

      if (mounted) {
        _showSuccessSnackBar('Health record added successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving health record: $e');
      if (mounted) {
        _showErrorSnackBar('Error saving health record: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Attach Files',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Platform indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kIsWeb ? Colors.blue.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    kIsWeb ? 'Web' : 'Mobile',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: kIsWeb ? Colors.blue.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_isUploading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload X-rays, test reports, or other medical documents',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            
            // Upload buttons
            if (kIsWeb) ...[
              // Web-specific file input
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading || _isUploading ? null : _pickMultipleFiles,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select Multiple Files'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading || _isUploading ? null : _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Select Single File'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Mobile-specific buttons
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading || _isUploading ? null : _pickImageFromCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading || _isUploading ? null : _pickImageFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading || _isUploading ? null : _pickMultipleFiles,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select Multiple Files'),
                    ),
                  ),
                ],
              ),
            ],
            
            // Selected files list
            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Selected Files:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(_selectedFiles.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                String fileName;
                String fileSize = 'Unknown size';
                
                if (file is XFile) {
                  fileName = file.name;
                } else {
                  fileName = file.path.split('/').last;
                }
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: Text(fileName),
                    subtitle: Text(fileSize),
                    trailing: IconButton(
                      onPressed: _isLoading || _isUploading ? null : () => _removeFile(index),
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                    ),
                  ),
                );
              }).toList()),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    if (kIsWeb) {
      _showErrorSnackBar('Camera access is not available on web. Please use "Select Files" instead.');
      return;
    }
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedFiles.add(image);
        });
        _showSuccessSnackBar('Photo captured successfully');
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      _showErrorSnackBar('Error capturing photo: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedFiles.add(image);
        });
        _showSuccessSnackBar('File selected successfully');
      }
    } catch (e) {
      debugPrint('Gallery error: $e');
      _showErrorSnackBar('Error selecting file: $e');
    }
  }

  // Web-specific file picker for multiple files
  Future<void> _pickMultipleFiles() async {
    if (!kIsWeb) {
      // On mobile, use the gallery picker
      await _pickImageFromGallery();
      return;
    }

    try {
      // For web, we can pick multiple files at once
      final List<XFile>? images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (images != null && images.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(images);
        });
        _showSuccessSnackBar('${images.length} files selected successfully');
      }
    } catch (e) {
      debugPrint('Multiple file picker error: $e');
      _showErrorSnackBar('Error selecting files: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<List<String>> _uploadFiles() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Reset progress
    setState(() {
      _uploadProgress = 0.0;
      _uploadedFilesCount = 0;
    });

    // Prepare all files for parallel upload
    final List<Future<String>> uploadFutures = [];
    
    for (int i = 0; i < _selectedFiles.length; i++) {
      uploadFutures.add(_uploadSingleFile(_selectedFiles[i], i, authService.currentUser!.uid));
    }

    // Upload all files in parallel
    try {
      final List<String> uploadedUrls = await Future.wait(uploadFutures);
      return uploadedUrls;
    } catch (e) {
      debugPrint('Error in parallel upload: $e');
      throw Exception('Failed to upload files: $e');
    }
  }

  Future<String> _uploadSingleFile(dynamic file, int index, String userId) async {
    String fileName;
    String extension;
    String displayName;
    
    if (file is XFile) {
      final originalName = file.name;
      extension = originalName.split('.').last;
      fileName = '${DateTime.now().millisecondsSinceEpoch}_$index.$extension';
      displayName = originalName;
    } else {
      extension = file.path.split('.').last;
      fileName = '${DateTime.now().millisecondsSinceEpoch}_$index.$extension';
      displayName = file.path.split('/').last;
    }
    
    final ref = _storage.ref().child('health_records/$userId/$fileName');
    
    try {
      UploadTask uploadTask;
      
      if (file is XFile) {
        // Handle XFile (works on both web and mobile)
        final bytes = await _compressImage(file);
        uploadTask = ref.putData(bytes);
        
        // Set metadata for better organization
        final metadata = SettableMetadata(
          contentType: _getContentType(extension),
          customMetadata: {
            'originalName': displayName,
            'uploadedAt': DateTime.now().toIso8601String(),
            'platform': kIsWeb ? 'web' : 'mobile',
          },
        );
        uploadTask = ref.putData(bytes, metadata);
      } else {
        // For File, upload directly (mobile only)
        uploadTask = ref.putFile(file);
      }
      
      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (mounted) {
          setState(() {
            _uploadProgress = progress;
          });
        }
      });
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Update progress
      if (mounted) {
        setState(() {
          _uploadedFilesCount++;
        });
      }
      
      debugPrint('File uploaded successfully: $displayName');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file $index: $e');
      throw Exception('Failed to upload file: $displayName');
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  Future<Uint8List> _compressImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      
      // For now, we'll use the original bytes but add optimizations
      // The parallel upload will still provide significant speed improvements
      
      // Log file size for debugging
      debugPrint('File size: ${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB');
      
      return bytes;
    } catch (e) {
      debugPrint('Error reading file bytes: $e');
      rethrow;
    }
  }
}
