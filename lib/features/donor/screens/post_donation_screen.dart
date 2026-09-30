import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harvest/core/services/image_picker_service.dart';
import 'package:harvest/core/services/storage_service.dart';
import 'package:harvest/core/services/firestore_service.dart';
import 'package:harvest/core/services/map_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDonationScreen extends StatefulWidget {
  const PostDonationScreen({super.key});

  @override
  State<PostDonationScreen> createState() => _PostDonationScreenState();
}

class _PostDonationScreenState extends State<PostDonationScreen> {
  // Theme Tokens
  static const Color _forest = Color(0xFF1A3A1F);
  static const Color _leaf = Color(0xFF3D7A45);
  static const Color _sprout = Color(0xFF6BBF6A);
  static const Color _mist = Color(0xFFF3F7F0);
  static const Color _divider = Color(0xFFDEEADE);
  static const Color _ink = Color(0xFF0F1F12);
  static const Color _slate = Color(0xFF6B7A6E);

  static const LinearGradient _heroGradient = LinearGradient(
    colors: [Color(0xFF1A3A1F), Color(0xFF2D5E33)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  int _currentStep = 0; // 0: Details, 1: Photos & Category, 2: Location & Time
  final PageController _pageController = PageController();
  bool _isUploading = false;
  bool _isGettingLocation = false;

  // Services
  final ImagePickerService _imagePickerService = ImagePickerService();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  final MapService _mapService = MapService();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _donorPhoneController = TextEditingController();

  // Data
  String _selectedCategory = 'Food';
  String _selectedCondition = 'Fresh / New';
  final List<File> _selectedImages = [];
  DateTime? _expiryDate;
  DateTime? _cookedAt;
  DateTime? _pickupDeadline;
  double? _latitude;
  double? _longitude;

  final Set<String> _selectedDietaryTags = {};
  final Set<String> _selectedAllergenTags = {};

  final List<String> _categories = [
    'Food',
    'Raw Produce',
    'Cooked Meals',
    'Clothes',
    'Organic Waste',
    'Manure',
    'Seeds',
    'Medicine',
    'Books',
    'Electronics',
    'Furniture',
    'Other',
  ];

  final List<String> _conditions = [
    'Fresh / New',
    'Like New',
    'Good',
    'Fair',
  ];

  final List<String> _dietaryOptions = [
    'Vegetarian',
    'Non-Veg',
    'Vegan',
    'Halal',
    'Gluten-Free',
    'Dairy-Free',
  ];

  final List<String> _allergenOptions = [
    'Contains Nuts',
    'Contains Dairy',
    'Contains Gluten',
    'Contains Soy',
    'Contains Seafood',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _donorPhoneController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step > 2) return;
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  bool _validateStep1() {
    if (_titleController.text.trim().isEmpty) {
      _showSnackbar('Please enter a donation title', isError: true);
      return false;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showSnackbar('Please enter a brief description', isError: true);
      return false;
    }
    if (_quantityController.text.trim().isEmpty) {
      _showSnackbar('Please specify the quantity', isError: true);
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    if (_locationController.text.trim().isEmpty) {
      _showSnackbar('Please provide or detect a pickup address', isError: true);
      return false;
    }
    if (_donorPhoneController.text.trim().isEmpty) {
      _showSnackbar('Please enter your contact phone number', isError: true);
      return false;
    }
    return true;
  }

  Future<void> _autoDetectLocation() async {
    setState(() => _isGettingLocation = true);
    HapticFeedback.lightImpact();

    try {
      final hasPermission = await _mapService.requestLocationPermission();
      if (!hasPermission) {
        if (mounted) {
          _showSnackbar('Location permission is required. Please enable it in Settings.', isError: true);
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      final position = await _mapService.getCurrentLocation();
      if (position == null) {
        if (mounted) {
          _showSnackbar('Unable to fetch GPS coordinates. Please ensure GPS is enabled.', isError: true);
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      final address = await _mapService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          if (address != null && address.isNotEmpty) {
            _locationController.text = address;
          } else {
            _locationController.text = 'GPS: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
          }
          _isGettingLocation = false;
        });

        _showSnackbar('📍 Location auto-filled: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}');
      }
    } catch (e) {
      debugPrint('Error auto-detecting location: $e');
      if (mounted) {
        setState(() => _isGettingLocation = false);
        _showSnackbar('Error detecting location: $e', isError: true);
      }
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      _showSnackbar('Maximum 5 images allowed');
      return;
    }

    final File? image = await _imagePickerService.showImageSourceDialog(context);
    if (image != null && mounted) {
      setState(() {
        _selectedImages.add(image);
      });
      HapticFeedback.selectionClick();
    }
  }

  void _removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      setState(() {
        _selectedImages.removeAt(index);
      });
      HapticFeedback.lightImpact();
      _showSnackbar('Image removed');
    }
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final File item = _selectedImages.removeAt(oldIndex);
      _selectedImages.insert(newIndex, item);
    });
    HapticFeedback.selectionClick();
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : _leaf,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitDonation() async {
    if (!_validateStep1() || !_validateStep3()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackbar('You must be logged in to post a donation', isError: true);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final String donorName = userDoc.data()?['name'] ?? user.displayName ?? 'Community Donor';

      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _storageService.uploadMultipleImages(
          imageFiles: _selectedImages,
          folder: 'donations',
          userId: user.uid,
        );
      }

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
        donorName: donorName,
        donorPhone: _donorPhoneController.text.trim(),
        cookedAt: _cookedAt,
        pickupDeadline: _pickupDeadline,
        dietaryTags: _selectedDietaryTags.toList(),
        allergenTags: _selectedAllergenTags.toList(),
      );

      if (mounted) {
        setState(() => _isUploading = false);
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('Error creating donation: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        _showSnackbar('Failed to post donation: $e', isError: true);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: _leaf, size: 30),
            SizedBox(width: 12),
            Text('Donation Live!', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your donation has been posted successfully and is now visible on the map and recipient dashboards.',
              style: TextStyle(fontSize: 14.5, height: 1.4, color: _ink),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _sprout.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.photo_library_rounded, size: 16, color: _leaf),
                      const SizedBox(width: 8),
                      Text('${_selectedImages.length} photo(s) uploaded', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (_latitude != null && _longitude != null) ...[
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 16, color: _leaf),
                        SizedBox(width: 8),
                        Text('GPS Coordinates saved', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to Dashboard', style: TextStyle(color: _slate, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pushNamed(context, '/donation-tracking');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _leaf,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Track Donation', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: _mist,
      appBar: AppBar(
        title: const Text(
          'Post Donation',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        backgroundColor: _forest,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: _heroGradient)),
      ),
      body: _isUploading
          ? _buildUploadingScreen()
          : Column(
              children: [
                // Visible Multi-Step Progress Indicator
                _buildStepHeader(),

                // Step Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1Details(),
                      _buildStep2PhotosAndCategory(),
                      _buildStep3LocationAndTime(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _isUploading ? null : _buildBottomNavigationBar(),
    );
  }

  // ─── STEP PROGRESS INDICATOR ────────────────────────────────────────────────
  Widget _buildStepHeader() {
    const steps = [
      {'title': 'Details', 'icon': Icons.description_outlined},
      {'title': 'Photos', 'icon': Icons.photo_camera_outlined},
      {'title': 'Location', 'icon': Icons.place_outlined},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final lineIndex = index ~/ 2;
                final isCompleted = _currentStep > lineIndex;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    color: isCompleted ? _leaf : _divider,
                  ),
                );
              }

              final stepIndex = index ~/ 2;
              final isCurrent = _currentStep == stepIndex;
              final isCompleted = _currentStep > stepIndex;

              return InkWell(
                onTap: () {
                  if (stepIndex < _currentStep) {
                    _goToStep(stepIndex);
                  } else if (stepIndex == 1 && _validateStep1()) {
                    _goToStep(1);
                  } else if (stepIndex == 2 && _validateStep1()) {
                    _goToStep(2);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? _leaf
                            : isCurrent
                                ? _forest
                                : _mist,
                        border: Border.all(
                          color: isCurrent ? _leaf : _divider,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                            : Text(
                                '${stepIndex + 1}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent ? Colors.white : _slate,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      steps[stepIndex]['title'] as String,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                        color: isCurrent ? _forest : (isCompleted ? _leaf : _slate),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── STEP 1: DETAILS ────────────────────────────────────────────────────────
  Widget _buildStep1Details() {
    final isFoodCategory = _selectedCategory == 'Food' ||
        _selectedCategory == 'Raw Produce' ||
        _selectedCategory == 'Cooked Meals';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Basic Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _forest),
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _titleController,
                  label: 'Donation Title *',
                  hint: 'e.g., 20 Packets Fresh Meals / 5kg Rice',
                  icon: Icons.title_rounded,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description *',
                  hint: 'Provide details about the item condition, quantity, and packaging...',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _quantityController,
                  label: 'Quantity *',
                  hint: 'e.g., 10 kg, 25 meals, 4 boxes',
                  icon: Icons.inventory_2_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _buildCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '2. Category & Condition',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _forest),
                ),
                const SizedBox(height: 12),
                const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _slate)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: _leaf,
                      backgroundColor: _mist,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : _ink,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Condition', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _slate)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _conditions.map((cond) {
                    final isSelected = _selectedCondition == cond;
                    return ChoiceChip(
                      label: Text(cond),
                      selected: isSelected,
                      selectedColor: _forest,
                      backgroundColor: _mist,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : _ink,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (_) => setState(() => _selectedCondition = cond),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          if (isFoodCategory) ...[
            const SizedBox(height: 18),
            _buildCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.health_and_safety_outlined, color: _leaf, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '3. Food Safety & Dietary Tags',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _forest),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Dietary Preference', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _slate)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dietaryOptions.map((tag) {
                      final isSelected = _selectedDietaryTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        selectedColor: _leaf.withValues(alpha: 0.2),
                        checkmarkColor: _leaf,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDietaryTags.add(tag);
                            } else {
                              _selectedDietaryTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text('Allergen Warnings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _slate)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allergenOptions.map((tag) {
                      final isSelected = _selectedAllergenTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        selectedColor: Colors.orange.withValues(alpha: 0.2),
                        checkmarkColor: Colors.deepOrange,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAllergenTags.add(tag);
                            } else {
                              _selectedAllergenTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── STEP 2: PHOTOS & MEDIA (DRAG-TO-REORDER & 1-TAP DELETE) ────────────────
  Widget _buildStep2PhotosAndCategory() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Donation Photos',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _forest),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _mist,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_selectedImages.length} / 5 photos',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _slate),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Add high quality photos. Tap and drag any image to reorder. The first photo is your cover image.',
                  style: TextStyle(fontSize: 12.5, color: _slate, height: 1.4),
                ),
                const SizedBox(height: 16),

                // Upload Button
                OutlinedButton.icon(
                  onPressed: _selectedImages.length >= 5 ? null : _pickImages,
                  icon: const Icon(Icons.add_a_photo_rounded, size: 20),
                  label: Text(_selectedImages.isEmpty ? 'Select Photos (Camera / Gallery)' : 'Add Another Photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _forest,
                    side: const BorderSide(color: _leaf, width: 1.5),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),

                const SizedBox(height: 20),

                // Interactive Reorderable List of Photos
                if (_selectedImages.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    decoration: BoxDecoration(
                      color: _mist,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _divider, style: BorderStyle.solid),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 48, color: _slate),
                        SizedBox(height: 10),
                        Text('No photos added yet', style: TextStyle(fontWeight: FontWeight.bold, color: _ink)),
                        SizedBox(height: 4),
                        Text('Photos make your donation 4x more likely to be claimed!', style: TextStyle(fontSize: 12, color: _slate)),
                      ],
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedImages.length,
                    onReorder: _reorderImages,
                    itemBuilder: (context, index) {
                      final imageFile = _selectedImages[index];
                      final isCover = index == 0;

                      return Container(
                        key: ValueKey(imageFile.path),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCover ? _leaf : _divider,
                            width: isCover ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Drag Handle Icon
                            const Icon(Icons.drag_indicator_rounded, color: _slate, size: 24),
                            const SizedBox(width: 8),

                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                imageFile,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Photo #${index + 1}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      if (isCover) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _leaf.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            '⭐ Cover Photo',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _leaf,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Long press and drag to reorder',
                                    style: TextStyle(fontSize: 12, color: _slate),
                                  ),
                                ],
                              ),
                            ),

                            // 1-Tap Delete Button
                            IconButton(
                              onPressed: () => _removeImage(index),
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                              ),
                              tooltip: 'Remove photo',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── STEP 3: PICKUP LOCATION & TIME ─────────────────────────────────────────
  Widget _buildStep3LocationAndTime() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: _leaf, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Pickup Address & GPS',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _forest),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Auto-detect using GPS or type your full address with landmark.',
                  style: TextStyle(fontSize: 12.5, color: _slate),
                ),
                const SizedBox(height: 16),

                // GPS Auto-detect Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isGettingLocation ? null : _autoDetectLocation,
                    icon: _isGettingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded, size: 20),
                    label: Text(_isGettingLocation ? 'Detecting GPS Location...' : '📍 Auto-Detect Current Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _leaf,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                if (_latitude != null && _longitude != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _sprout.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _leaf.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: _leaf, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'GPS Coordinates Captured: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _forest),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                _buildTextField(
                  controller: _locationController,
                  label: 'Full Address / Landmark *',
                  hint: 'Street, Building, Flat / Unit, City, Pincode',
                  icon: Icons.map_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _donorPhoneController,
                  label: 'Contact Phone Number *',
                  hint: '+91 98765 43210',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _buildCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: _leaf, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Pickup Timings & Expiry',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _forest),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Expiry Date
                _buildDateTile(
                  label: _expiryDate == null
                      ? 'Best Before / Expiry Deadline'
                      : 'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year} ${_formatTime(_expiryDate!)}',
                  icon: Icons.timer_outlined,
                  onTap: () => _pickDateTime((val) => setState(() => _expiryDate = val)),
                  onClear: _expiryDate != null ? () => setState(() => _expiryDate = null) : null,
                ),

                const SizedBox(height: 12),

                // Prepared At (Optional for food)
                if (_selectedCategory == 'Food' || _selectedCategory == 'Cooked Meals')
                  _buildDateTile(
                    label: _cookedAt == null
                        ? 'When was it prepared / cooked?'
                        : 'Prepared: ${_cookedAt!.day}/${_cookedAt!.month} ${_formatTime(_cookedAt!)}',
                    icon: Icons.restaurant_outlined,
                    onTap: () => _pickDateTime((val) => setState(() => _cookedAt = val)),
                    onClear: _cookedAt != null ? () => setState(() => _cookedAt = null) : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── BOTTOM NAVIGATION BAR ──────────────────────────────────────────────────
  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              OutlinedButton.icon(
                onPressed: () => _goToStep(_currentStep - 1),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _forest,
                  side: const BorderSide(color: _divider, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_currentStep == 0) {
                    if (_validateStep1()) _goToStep(1);
                  } else if (_currentStep == 1) {
                    _goToStep(2);
                  } else {
                    _submitDonation();
                  }
                },
                icon: Icon(
                  _currentStep == 2 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                  size: 18,
                ),
                label: Text(
                  _currentStep == 0
                      ? 'Next: Photos ➔'
                      : _currentStep == 1
                          ? 'Next: Location & Time ➔'
                          : 'Post Donation Now',
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _leaf,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────
  Widget _buildCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _forest),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14.5, color: _ink, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFA0ABA2), fontSize: 13.5),
            filled: true,
            fillColor: _mist,
            prefixIcon: Icon(icon, color: _leaf, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 14 : 0),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTile({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _mist,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: _leaf, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _ink),
              ),
            ),
            if (onClear != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: _slate),
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              const Icon(Icons.chevron_right_rounded, size: 20, color: _slate),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime(Function(DateTime) onPicked) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 4))),
      );
      if (time != null) {
        final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        onPicked(combined);
      }
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  Widget _buildUploadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_leaf)),
          const SizedBox(height: 20),
          const Text('Posting your donation...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _forest)),
          const SizedBox(height: 6),
          const Text('Uploading photos and saving to live map...', style: TextStyle(fontSize: 13, color: _slate)),
        ],
      ),
    );
  }
}
