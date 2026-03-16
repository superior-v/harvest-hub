import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:harvest/core/constants/app_constants.dart';
import 'package:harvest/core/services/image_picker_service.dart';
import 'package:harvest/core/services/storage_service.dart';
import 'package:harvest/core/services/firestore_service.dart';
import 'package:harvest/core/services/map_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class PostDonationScreen extends StatefulWidget {
  const PostDonationScreen({Key? key}) : super(key: key);

  @override
  State<PostDonationScreen> createState() => _PostDonationScreenState();
}

class _PostDonationScreenState extends State<PostDonationScreen> {
  // Theme tokens aligned with donor dashboard
  static const Color _forest = Color(0xFF1A3A1F);
  static const Color _leaf = Color(0xFF3D7A45);
  static const Color _sprout = Color(0xFF6BBF6A);
  static const Color _mist = Color(0xFFF3F7F0);
  static const Color _clay = Color(0xFFD4956A);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _divider = Color(0xFFDEEADE);

  static const LinearGradient _heroGradient = LinearGradient(
    colors: [
      Color(0xFF1A3A1F),
      Color(0xFF2D5E33)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  int _currentStep = 0;
  bool _isUploading = false;
  bool _isGettingLocation = false;

  // Services
  final ImagePickerService _imagePickerService = ImagePickerService();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  final MapService _mapService = MapService();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();

  // Selected data
  String _selectedCategory = 'Food';
  String _selectedCondition = 'New';
  List<File> _selectedImages = [];
  DateTime? _expiryDate;
  double? _latitude;
  double? _longitude;

  final List<String> _categories = [
    'Food',
    'Clothes',
    'Electronics',
    'Furniture',
    'Books',
    'Toys',
    'Medicine',
    'Other'
  ];

  final List<String> _conditions = [
    'New',
    'Like New',
    'Good',
    'Fair'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: _mist,
      appBar: AppBar(
        title: const Text(
          'Post Donation',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _forest,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: _heroGradient)),
      ),
      body: _isUploading
          ? _buildUploadingScreen()
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _forest.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: _leaf,
                    ),
                  ),
                  child: Stepper(
                    currentStep: _currentStep,
                    onStepContinue: _onStepContinue,
                    onStepCancel: _onStepCancel,
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: details.onStepContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _leaf,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _currentStep == 3 ? 'Submit' : 'Continue',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            if (_currentStep > 0) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: details.onStepCancel,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: const BorderSide(color: _leaf),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Back',
                                    style: TextStyle(color: _leaf),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    steps: [
                      Step(
                        title: const Text('Basic Info'),
                        isActive: _currentStep >= 0,
                        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                        content: _buildBasicInfoStep(),
                      ),
                      Step(
                        title: const Text('Details'),
                        isActive: _currentStep >= 1,
                        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                        content: _buildDetailsStep(),
                      ),
                      Step(
                        title: const Text('Photos'),
                        isActive: _currentStep >= 2,
                        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                        content: _buildImagesStep(),
                      ),
                      Step(
                        title: const Text('Location'),
                        isActive: _currentStep >= 3,
                        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                        content: _buildLocationStep(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildUploadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_leaf),
          ),
          const SizedBox(height: 24),
          const Text(
            'Uploading your donation...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we process your images',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Title *',
            hintText: 'e.g., Fresh Vegetables',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.title, color: AppColors.primaryGreen),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Description *',
            hintText: 'Describe your donation...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.description, color: AppColors.primaryGreen),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _quantityController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            labelText: 'Quantity *',
            hintText: 'e.g., 10 kg or 5 items',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.inventory, color: AppColors.primaryGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              selectedColor: _leaf,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Condition',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _conditions.map((condition) {
            final isSelected = _selectedCondition == condition;
            return ChoiceChip(
              label: Text(condition),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCondition = condition);
              },
              selectedColor: _leaf,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Expiry Date (Optional for Food items)
        if (_selectedCategory == 'Food') ...[
          const Text(
            'Expiry Date (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectExpiryDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.primaryGreen),
                  const Icon(Icons.calendar_today, color: _leaf),
                  const SizedBox(width: 12),
                  Text(
                    _expiryDate == null ? 'Select expiry date' : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _expiryDate == null ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  if (_expiryDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() => _expiryDate = null);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Photos (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Add up to 5 photos of your donation',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _selectedImages.length + 1,
          itemBuilder: (context, index) {
            if (index == _selectedImages.length) {
              return _buildAddPhotoButton();
            }
            return _buildImageCard(_selectedImages[index], index);
          },
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _selectedImages.length < 5 ? _addImage : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _leaf,
            width: 2,
            style: _selectedImages.length < 5 ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 40,
              color: _selectedImages.length < 5 ? _leaf : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              'Add Photo',
              style: TextStyle(
                color: _selectedImages.length < 5 ? _leaf : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(File image, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _locationController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Pickup Location *',
            hintText: 'Enter full address',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.location_on, color: _leaf),
            suffixIcon: _isGettingLocation
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_leaf),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.my_location, color: _leaf),
                    onPressed: _pickLocationFromMap,
                    tooltip: 'Use current location',
                  ),
          ),
        ),

        const SizedBox(height: 12),

        // Location info card
        if (_latitude != null && _longitude != null)
          Card(
            color: _sprout.withOpacity(0.16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: _leaf, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location captured: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _leaf,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Summary Card
        Card(
          elevation: 2,
          color: _cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: _divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.summarize, color: _leaf),
                    SizedBox(width: 8),
                    Text(
                      'Summary',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildSummaryItem('Title', _titleController.text),
                _buildSummaryItem('Category', _selectedCategory),
                _buildSummaryItem('Condition', _selectedCondition),
                _buildSummaryItem('Quantity', _quantityController.text),
                _buildSummaryItem('Photos', '${_selectedImages.length} image${_selectedImages.length != 1 ? 's' : ''}'),
                if (_expiryDate != null)
                  _buildSummaryItem(
                    'Expiry',
                    '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                  ),
                _buildSummaryItem(
                  'Location',
                  _latitude != null ? '✓ Captured' : 'Not set',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _leaf,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _pickLocationFromMap() async {
    setState(() => _isGettingLocation = true);

    try {
      debugPrint('🔵 Pick location button pressed');

      // Request permission first
      final hasPermission = await _mapService.requestLocationPermission();

      if (!hasPermission) {
        if (mounted) {
          _showError('Location permission is required. Please enable it in settings.');
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      debugPrint('✅ Permission granted, getting location...');

      // Get current position
      final position = await _mapService.getCurrentLocation();

      if (position == null) {
        if (mounted) {
          _showError('Unable to get current location. Please:\n1. Enable Location Services\n2. Grant location permission\n3. Ensure GPS is on');
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      debugPrint('✅ Position obtained: ${position.latitude}, ${position.longitude}');

      // Get address from coordinates
      final address = await _mapService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (address != null && address.isNotEmpty) {
          _locationController.text = address;
        } else {
          _locationController.text = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lon: ${position.longitude.toStringAsFixed(6)}';
        }
        _isGettingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Location captured: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
            backgroundColor: _leaf,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      debugPrint('✅ Location set successfully');
    } catch (e) {
      debugPrint('❌ Error in _pickLocationFromMap: $e');
      if (mounted) {
        _showError('Error getting location: $e');
      }
      setState(() => _isGettingLocation = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () async {
            await Geolocator.openAppSettings();
          },
        ),
      ),
    );
  }

  Future<void> _addImage() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')),
      );
      return;
    }

    final File? image = await _imagePickerService.showImageSourceDialog(context);

    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _onStepContinue() {
    if (_currentStep < 3) {
      // Validate current step before continuing
      if (_currentStep == 0) {
        if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty || _quantityController.text.trim().isEmpty) {
          _showError('Please fill in all required fields');
          return;
        }
      }
      setState(() => _currentStep++);
    } else {
      _submitDonation();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitDonation() async {
    // Validate
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a title');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please enter a description');
      return;
    }
    if (_quantityController.text.trim().isEmpty) {
      _showError('Please enter quantity');
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      _showError('Please enter pickup location');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('You must be logged in to post a donation');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Upload images to Firebase Storage
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _storageService.uploadMultipleImages(
          imageFiles: _selectedImages,
          folder: 'donations',
          userId: user.uid,
        );
      }

      // Create donation in Firestore
      await _firestoreService.createDonation(
        donorId: user.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        condition: _selectedCondition,
        quantity: _quantityController.text.trim(),
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        imageUrls: imageUrls,
        expiryDate: _expiryDate,
      );

      if (mounted) {
        setState(() => _isUploading = false);
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('❌ Error creating donation: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        _showError('Failed to post donation: $e');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: _leaf, size: 32),
            SizedBox(width: 12),
            Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your donation has been posted successfully!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _sprout.withOpacity(0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.photo, size: 16, color: _leaf),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedImages.length} photo${_selectedImages.length != 1 ? 's' : ''} uploaded',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  if (_latitude != null && _longitude != null) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: _leaf),
                        SizedBox(width: 8),
                        Text(
                          'Location captured',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Recipients can now see and request your donation.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to dashboard
              Navigator.pushNamed(context, '/donation-tracking');
            },
            child: const Text(
              'View My Donations',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _leaf,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
