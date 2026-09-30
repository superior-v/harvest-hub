import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:harvest/core/constants/app_constants.dart';
import 'package:harvest/core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipientDashboardScreen extends StatefulWidget {
  const RecipientDashboardScreen({Key? key}) : super(key: key);

  @override
  State<RecipientDashboardScreen> createState() => _RecipientDashboardScreenState();
}

class _RecipientDashboardScreenState extends State<RecipientDashboardScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String _selectedCategory = 'All';
  final FirestoreService _firestoreService = FirestoreService();

  AnimationController? _fadeController;
  Animation<double> _fadeAnimation = const AlwaysStoppedAnimation<double>(1.0);

  List<String> _categories = [
    'All',
    'Food',
    'Clothes',
    'Electronics',
    'Furniture',
    'Books',
    'Toys',
    'Medicine',
    'Other'
  ];

  bool _isFarmer = false;

  // ─── Design Tokens ────────────────────────────────────────────────────────
  static const Color _ocean = Color(0xFF0D3D56); // deep ocean for recipient
  static const Color _wave = Color(0xFF1A6B8A); // mid wave
  static const Color _foam = Color(0xFF4A90C4); // light foam / sky
  static const Color _mist = Color(0xFFF0F6FA); // page background
  static const Color _dew = Color(0xFFE4F2F8); // light tint
  static const Color _ink = Color(0xFF0A1E2A); // near-black
  static const Color _slate = Color(0xFF5A7080); // muted text
  static const Color _divider = Color(0xFFD8EAF2); // subtle border
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _leaf = Color(0xFF3D7A45); // green for donor ref
  static const Color _sprout = Color(0xFF6BBF6A);
  static const Color _clay = Color(0xFFD4956A); // warm accent
  static const Color _forest = Color(0xFF1A3A1F);

  static const LinearGradient _heroGradient = LinearGradient(
    colors: [
      Color(0xFF0D3D56),
      Color(0xFF1A6B8A)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient _foamGradient = LinearGradient(
    colors: [
      Color(0xFF1A6B8A),
      Color(0xFF4A90C4)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍎';
      case 'clothes':
        return '👕';
      case 'electronics':
        return '📱';
      case 'books':
        return '📚';
      case 'furniture':
        return '🛋️';
      case 'toys':
        return '🧸';
      case 'medicine':
        return '💊';
      case 'organic waste':
        return '🥬';
      case 'manure':
        return '🪣';
      case 'seeds':
        return '🌱';
      default:
        return '📦';
    }
  }

  @override
  void initState() {
    super.initState();
    _initAnimationsIfNeeded();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['role'] == 'farmer') {
          setState(() {
            _isFarmer = true;
            _categories = [
              'All',
              'Organic Waste',
              'Manure',
              'Seeds',
              'Other'
            ];
          });
        }
      }
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _initAnimationsIfNeeded();
  }

  void _initAnimationsIfNeeded() {
    if (_fadeController != null) return;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeOut,
    );
    _fadeController!.forward();
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    super.dispose();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _initAnimationsIfNeeded();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      backgroundColor: _mist,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(),
            _buildCategoryChips(),
            Expanded(
              child: _selectedIndex == 0 ? _buildBrowseTab() : const Center(child: Text('Requests tab')),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final rawName = user?.displayName?.trim();
    final emailPrefix = user?.email?.split('@').first ?? '';
    final firstName = (rawName != null && rawName.isNotEmpty)
        ? rawName.split(' ').first
        : emailPrefix.isNotEmpty
            ? emailPrefix
            : 'there';
    final avatarLetter = firstName[0].toUpperCase();

    return Container(
      decoration: const BoxDecoration(gradient: _heroGradient),
      child: Stack(
        children: [
          // Blob decoration
          Positioned(
            right: -30,
            top: -20,
            child: _Blob(size: 150, color: _wave.withOpacity(0.35)),
          ),
          Positioned(
            left: -40,
            bottom: -10,
            child: _Blob(size: 110, color: _foam.withOpacity(0.15)),
          ),
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hello, $firstName 👋',
                          style: const TextStyle(
                            color: Color(0xFF8EC8E8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Browse Donations',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: _foam,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Find what your community needs',
                              style: TextStyle(
                                color: Color(0xFF8EC8E8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Avatar + profile
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2A8CB0),
                            Color(0xFF1A6B8A)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          avatarLetter,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CATEGORY CHIPS ───────────────────────────────────────────────────────

  Widget _buildCategoryChips() {
    return Container(
      height: 54,
      color: _mist,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? _wave : _cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _wave : _divider,
                    width: isSelected ? 0 : 0.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(color: _wave.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3))
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cat != 'All') ...[
                      Text(
                        _getCategoryEmoji(cat),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : _slate,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── BROWSE TAB ───────────────────────────────────────────────────────────

  Widget _buildBrowseTab() {
    return _buildDonationsStream();
  }

  // ─── DONATIONS STREAM (UNCHANGED LOGIC) ──────────────────────────────────

  Widget _buildDonationsStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('donations').orderBy('createdAt', descending: true).limit(100).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingGrid();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        // Local filtering
        final allDocs = snapshot.data!.docs;
        final filteredDonations = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] != 'available') return false;
          
          final docCategory = data['category'] as String? ?? 'Other';
          final farmerCategories = ['Organic Waste', 'Manure', 'Seeds'];

          if (_selectedCategory != 'All') {
            if (docCategory != _selectedCategory) return false;
          } else {
            // 'All' selected: isolate farmer items from NGO items based on role
            if (_isFarmer) {
              if (!farmerCategories.contains(docCategory)) return false;
            } else {
              if (farmerCategories.contains(docCategory)) return false;
            }
          }
          return true;
        }).toList();

        if (filteredDonations.isEmpty) {
          return _buildEmptyState();
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: filteredDonations.length,
          itemBuilder: (context, index) {
            final donation = filteredDonations[index].data() as Map<String, dynamic>;
            return _buildDonationCard(donation, filteredDonations[index].id);
          },
        );
      },
    );
  }

  // ─── LOADING GRID ─────────────────────────────────────────────────────────

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => _ShimmerCard(),
    );
  }

  // ─── ERROR STATE ──────────────────────────────────────────────────────────

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF0EF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Text('⚠️', style: TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load donations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _slate),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => setState(() {}),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(
                  gradient: _foamGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _dew,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text('📭', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No donations available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedCategory == 'All' ? 'Check back later for new items' : 'No items in $_selectedCategory category',
            style: TextStyle(fontSize: 13, color: _slate),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── DONATION CARD ────────────────────────────────────────────────────────

  Widget _buildDonationCard(Map<String, dynamic> donation, String donationId) {
    final imageUrls = List<String>.from(donation['imageUrls'] ?? []);
    final imageUrl = imageUrls.isNotEmpty ? imageUrls[0] : null;
    final category = donation['category'] ?? 'Other';

    return GestureDetector(
      onTap: () => _showDonationDetails(donation, donationId),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _ocean.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ──
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 96,
                    width: double.infinity,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildImagePlaceholder(category),
                          )
                        : _buildImagePlaceholder(category),
                  ),
                  // Category badge on image
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _ocean.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Details ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 11, color: _slate),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            donation['quantity'] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: _slate,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Request CTA
                    Container(
                      width: double.infinity,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: _foamGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Request',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(String category) {
    final Map<String, List<Color>> gradients = {
      'food': [
        const Color(0xFFE8F5E9),
        const Color(0xFFA5D6A7)
      ],
      'clothes': [
        const Color(0xFFE3F2FD),
        const Color(0xFF90CAF9)
      ],
      'electronics': [
        const Color(0xFFF3E5F5),
        const Color(0xFFCE93D8)
      ],
      'books': [
        const Color(0xFFFFF8E1),
        const Color(0xFFFFE082)
      ],
      'furniture': [
        const Color(0xFFFBE9E7),
        const Color(0xFFFFAB91)
      ],
      'toys': [
        const Color(0xFFE8EAF6),
        const Color(0xFF9FA8DA)
      ],
      'medicine': [
        const Color(0xFFE0F7FA),
        const Color(0xFF80DEEA)
      ],
    };
    final Map<String, IconData> icons = {
      'food': Icons.restaurant_rounded,
      'clothes': Icons.checkroom_rounded,
      'electronics': Icons.devices_rounded,
      'books': Icons.menu_book_rounded,
      'furniture': Icons.chair_rounded,
      'toys': Icons.toys_rounded,
      'medicine': Icons.medical_services_rounded,
    };
    final key = category.toLowerCase();
    final colors = gradients[key] ??
        [
          _dew,
          const Color(0xFFB0C9D8)
        ];
    final iconData = icons[key] ?? Icons.redeem_rounded;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(iconData, size: 36, color: colors[1]),
      ),
    );
  }

  // ─── DONATION DETAIL SHEET (UNCHANGED LOGIC) ─────────────────────────────

  void _showDonationDetails(Map<String, dynamic> donation, String donationId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Sheet header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _dew,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _getCategoryEmoji(donation['category'] ?? 'Other'),
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donation['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            donation['category'] ?? 'Other',
                            style: TextStyle(fontSize: 12, color: _slate),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _dew,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'AVAILABLE',
                        style: TextStyle(
                          color: _wave,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image carousel
                      if (donation['imageUrls'] != null && (donation['imageUrls'] as List).isNotEmpty)
                        Container(
                          height: 180,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: PageView.builder(
                            itemCount: (donation['imageUrls'] as List).length,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  (donation['imageUrls'] as List)[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: _dew,
                                    child: const Center(
                                      child: Text('🖼️', style: TextStyle(fontSize: 36)),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // Description
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _mist,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          donation['description'] ?? 'No description provided.',
                          style: TextStyle(
                            fontSize: 14,
                            color: _slate,
                            height: 1.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Detail rows
                      _buildDetailRow(Icons.category_rounded, 'Category', donation['category']),
                      _buildDetailRow(Icons.inventory_2_rounded, 'Quantity', donation['quantity']),
                      _buildDetailRow(Icons.star_rounded, 'Condition', donation['condition']),
                      _buildDetailRow(Icons.location_on_rounded, 'Location', donation['location']),

                      const SizedBox(height: 24),

                      // Request button
                      GestureDetector(
                        onTap: () => _handleRequestDonation(donationId, donation),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: _foamGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _wave.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 10),
                              Text(
                                'Request This Donation',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _dew,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: _wave),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: _slate,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value ?? 'N/A',
            style: const TextStyle(
              fontSize: 13,
              color: _ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HANDLE REQUEST (UNCHANGED) ───────────────────────────────────────────

  Future<void> _handleRequestDonation(String donationId, Map<String, dynamic> donation) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please login to request donations'),
          backgroundColor: const Color(0xFFD63B2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 14),
              Text('Sending request...'),
            ],
          ),
          backgroundColor: _ocean,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );

      await _firestoreService.createRequest(
        recipientId: currentUser.uid,
        donationId: donationId,
        message: 'I would like to request this donation: ${donation['title']}',
        recipientName: currentUser.displayName ?? 'Anonymous',
        recipientEmail: currentUser.email ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 12),
                Text('Request sent successfully!'),
              ],
            ),
            backgroundColor: _wave,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error requesting donation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFD63B2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ─── BOTTOM NAV ───────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    const items = [
      _NavItem(icon: Icons.explore_rounded, label: 'Browse'),
      _NavItem(icon: Icons.inbox_rounded, label: 'Requests'),
      _NavItem(icon: Icons.map_rounded, label: 'Map'),
      _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    ];
    final routes = [
      '',
      '/requests',
      '/map-view',
      '/profile'
    ];

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: _ocean.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = _selectedIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_selectedIndex == i) return;
                    setState(() => _selectedIndex = i);
                    if (routes[i].isNotEmpty) {
                      if (routes[i] == '/requests') {
                        Navigator.pushNamed(context, routes[i], arguments: {'isDonorView': false});
                      } else {
                        Navigator.pushNamed(context, routes[i]);
                      }
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _dew : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[i].icon,
                          size: 22,
                          color: selected ? _wave : _slate,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                            color: selected ? _wave : _slate,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── NAV ITEM ─────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─── SHIMMER CARD ─────────────────────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 0.85).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE4EFF5).withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

// ─── BLOB ─────────────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size * 0.6),
          topRight: Radius.circular(size * 0.3),
          bottomLeft: Radius.circular(size * 0.4),
          bottomRight: Radius.circular(size * 0.7),
        ),
      ),
    );
  }
}

// ─── DOT GRID ─────────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    const spacing = 22.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}
