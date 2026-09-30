import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harvest/core/constants/app_constants.dart';
import 'package:harvest/core/widgets/custom_widgets.dart';
import 'package:harvest/models/donation_model.dart';

class DonationTrackingScreen extends StatefulWidget {
  const DonationTrackingScreen({Key? key}) : super(key: key);

  @override
  State<DonationTrackingScreen> createState() => _DonationTrackingScreenState();
}

class _DonationTrackingScreenState extends State<DonationTrackingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';

  final List<String> filters = [
    'All',
    'Active',
    'Matched',
    'Completed',
    'Cancelled'
  ];

  // ─── Design Tokens (matches donor dashboard) ──────────────────────────────
  static const Color _forest = Color(0xFF1A3A1F);
  static const Color _leaf = Color(0xFF3D7A45);
  static const Color _sprout = Color(0xFF6BBF6A);
  static const Color _mist = Color(0xFFF3F7F0);
  static const Color _clay = Color(0xFFD4956A);
  static const Color _dew = Color(0xFFE8F4EA);
  static const Color _ink = Color(0xFF0F1F12);
  static const Color _slate = Color(0xFF6B7A6E);
  static const Color _divider = Color(0xFFDEEADE);
  static const Color _sky = Color(0xFF4A90C4);
  static const Color _cardBg = Color(0xFFFFFFFF);

  static const LinearGradient _heroGradient = LinearGradient(
    colors: [
      Color(0xFF1A3A1F),
      Color(0xFF2D5E33)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient _sproutGradient = LinearGradient(
    colors: [
      Color(0xFF3D7A45),
      Color(0xFF6BBF6A)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── STATUS HELPERS ───────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return _leaf;
      case 'matched':
        return _sky;
      case 'completed':
        return _sprout;
      case 'cancelled':
        return const Color(0xFFD63B2F);
      default:
        return _slate;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return _dew;
      case 'matched':
        return const Color(0xFFE7F3FB);
      case 'completed':
        return const Color(0xFFEAF7EA);
      case 'cancelled':
        return const Color(0xFFFEF0EF);
      default:
        return const Color(0xFFF0F0EF);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.radio_button_checked_rounded;
      case 'matched':
        return Icons.handshake_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      backgroundColor: _mist,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(innerBoxIsScrolled),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDonationsTab(),
            _buildAnalyticsTab(),
          ],
        ),
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────

  Widget _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      snap: false,
      elevation: 0,
      backgroundColor: _forest,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(decoration: const BoxDecoration(gradient: _heroGradient)),
            // Subtle blob
            Positioned(
              right: -20,
              top: -20,
              child: _Blob(size: 130, color: _leaf.withOpacity(0.28)),
            ),
            Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
            // Title content
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: innerBoxIsScrolled ? 0 : 1,
                child: IgnorePointer(
                  ignoring: innerBoxIsScrolled,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Track Donations',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.6,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: _sprout,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'Monitor your giving journey',
                                      style: TextStyle(
                                        color: Color(0xFF9DC99A),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: _forest,
          child: TabBar(
            controller: _tabController,
            indicatorColor: _sprout,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.5),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.1,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'My Donations'),
              Tab(text: 'Analytics'),
            ],
          ),
        ),
      ),
    );
  }

  // ─── DONATIONS TAB ────────────────────────────────────────────────────────

  Widget _buildDonationsTab() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(child: _buildDonationsList()),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 56,
      color: _mist,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? _leaf : _cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _leaf : _divider,
                    width: isSelected ? 0 : 0.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(color: _leaf.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))
                        ]
                      : [],
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _slate,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDonationsList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('donations').where('donorId', isEqualTo: user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_leaf)));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        final docs = snapshot.data?.docs ?? [];
        
        // Map to Donation models
        var donations = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // ensure ID is set
          
          // Handle Timestamp to String for fromMap
          if (data['postedDate'] == null) {
              if (data['createdAt'] is Timestamp) {
                  data['postedDate'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
              } else {
                  data['postedDate'] = DateTime.now().toIso8601String();
              }
          } else if (data['postedDate'] is Timestamp) {
              data['postedDate'] = (data['postedDate'] as Timestamp).toDate().toIso8601String();
          }

          if (data['pickupDate'] is Timestamp) {
            data['pickupDate'] = (data['pickupDate'] as Timestamp).toDate().toIso8601String();
          }

          return Donation.fromMap(data);
        }).toList();

        // Apply filter
        if (_selectedFilter != 'All') {
          donations = donations.where((d) => d.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();
        }

        // Sort descending by date
        donations.sort((a, b) => b.postedDate.compareTo(a.postedDate));

        if (donations.isEmpty) {
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
                    child: Icon(Icons.inbox_outlined, size: 28, color: _leaf),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'No donations found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Try a different filter',
                  style: TextStyle(fontSize: 13, color: _slate),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            return _buildDonationCard(donations[index]);
          },
        );
      },
    );
  }

  Widget _buildDonationCard(Donation donation) {
    final sColor = _statusColor(donation.status);
    final sBg = _statusBg(donation.status);
    final sIcon = _statusIcon(donation.status);
    final daysSince = DateTime.now().difference(donation.postedDate).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _forest.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _showDonationDetails(donation),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: status pill + time + menu ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: sBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(sIcon, size: 13, color: sColor),
                          const SizedBox(width: 5),
                          Text(
                            donation.status.toUpperCase(),
                            style: TextStyle(
                              color: sColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      daysSince == 0 ? 'Today' : '${daysSince}d ago',
                      style: TextStyle(
                        fontSize: 12,
                        color: _slate.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showOptionsMenu(donation),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _mist,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(Icons.more_horiz_rounded, size: 18, color: _slate),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Title row ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _dew,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(donation.category),
                          size: 22,
                          color: _leaf,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donation.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                              letterSpacing: -0.2,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${donation.category} · ${donation.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _slate,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Stats row ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _mist,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(Icons.visibility_outlined, '${donation.views}', 'Views'),
                          ),
                          _buildStatDivider(),
                          Expanded(
                            child: _buildStatItem(Icons.favorite_border_rounded, '${donation.requests}', 'Requests'),
                          ),
                        ],
                      ),
                      if (donation.recipientName != null && donation.recipientName!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _divider, width: 0.7),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 15, color: _slate),
                              const SizedBox(width: 6),
                              const Text(
                                'Recipient:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _slate,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  donation.recipientName!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Pickup banner ──
                if (donation.status == 'matched' && donation.pickupDate != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _clay.withOpacity(0.3), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 14, color: _clay),
                        const SizedBox(width: 7),
                        Text(
                          'Pickup: ${_formatDate(donation.pickupDate!)}',
                          style: TextStyle(
                            color: _clay,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 28,
      color: _divider,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _slate),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: _slate,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── ANALYTICS TAB ────────────────────────────────────────────────────────

  Widget _buildAnalyticsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('donations').where('donorId', isEqualTo: user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_leaf))));
        }

        final docs = snapshot.data?.docs ?? [];
        
        int totalDonations = docs.length;
        int completedDonations = 0;
        int totalViews = 0;
        int totalRequests = 0;
        Map<String, int> categoryCounts = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'completed') completedDonations++;
          totalViews += (data['views'] as num?)?.toInt() ?? 0;
          totalRequests += (data['requests'] as num?)?.toInt() ?? 0;
          
          final category = data['category'] as String? ?? 'Other';
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }

        // Sort categories by count
        final sortedCategories = categoryCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
          
        final maxCategoryCount = sortedCategories.isEmpty ? 1 : sortedCategories.first.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Impact header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: _heroGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      top: -10,
                      child: _Blob(size: 90, color: _leaf.withOpacity(0.3)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Impact',
                          style: TextStyle(
                            color: Color(0xFF9DC99A),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Making a difference\nevery day',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 2×2 analytics grid ──
              Row(
                children: [
                  Expanded(
                    child: _buildAnalyticsCard('$totalDonations', 'Total\nDonations', Icons.volunteer_activism_rounded, _leaf, _dew),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAnalyticsCard('$completedDonations', 'Completed', Icons.task_alt_rounded, _sprout, const Color(0xFFEAF7EA)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildAnalyticsCard('$totalViews', 'Total\nViews', Icons.visibility_rounded, _sky, const Color(0xFFE7F3FB)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAnalyticsCard('$totalRequests', 'Total\nRequests', Icons.favorite_rounded, _clay, const Color(0xFFFAEEE5)),
                  ),
                ],
              ),

              if (sortedCategories.isNotEmpty) ...[
                const SizedBox(height: 20),
                // ── Category bars ──
                _buildSectionCard(
                  title: 'Most Donated Categories',
                  child: Column(
                    children: sortedCategories.take(3).map((entry) {
                      final colors = [_clay, _sky, _leaf];
                      final colorIndex = sortedCategories.indexOf(entry) % colors.length;
                      return _buildCategoryBar(entry.key, entry.value, maxCategoryCount, colors[colorIndex]);
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsCard(String value, String label, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -1,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _slate,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _forest.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: _sprout,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                  letterSpacing: -0.2,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _dew,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _leaf,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryBar(String category, int count, int max, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: count / max,
              backgroundColor: _mist,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String text, String time, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Icon(icon, size: 16, color: accentColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(fontSize: 11, color: _slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM SHEET: DONATION DETAILS ───────────────────────────────────────

  void _showDonationDetails(Donation donation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
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
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
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
                        child: Icon(
                          _getCategoryIcon(donation.category),
                          size: 24,
                          color: _leaf,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donation.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            donation.category,
                            style: TextStyle(fontSize: 12, color: _slate),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusBg(donation.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        donation.status.toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(donation.status),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _mist,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          donation.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: _slate,
                            height: 1.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Detail rows
                      _buildDetailRow('Quantity', donation.quantity),
                      _buildDetailRow('Condition', donation.condition),
                      _buildDetailRow('Location', donation.location),
                      _buildDetailRow('Posted', _formatDate(donation.postedDate)),
                      const SizedBox(height: 24),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: _leaf, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  color: _leaf,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _leaf,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                              child: const Text(
                                'Mark Complete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
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
            value,
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

  // ─── BOTTOM SHEET: OPTIONS ────────────────────────────────────────────────

  void _showOptionsMenu(Donation donation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _buildOptionTile(
                icon: Icons.edit_rounded,
                iconColor: _leaf,
                iconBg: _dew,
                label: 'Edit Donation',
                onTap: () => Navigator.pop(context),
              ),
              _buildOptionTile(
                icon: Icons.share_rounded,
                iconColor: _sky,
                iconBg: const Color(0xFFE7F3FB),
                label: 'Share',
                onTap: () => Navigator.pop(context),
              ),
              if (donation.status == 'active')
                _buildOptionTile(
                  icon: Icons.pause_circle_rounded,
                  iconColor: _clay,
                  iconBg: const Color(0xFFFAEEE5),
                  label: 'Pause Donation',
                  onTap: () => Navigator.pop(context),
                ),
              _buildOptionTile(
                icon: Icons.delete_rounded,
                iconColor: const Color(0xFFD63B2F),
                iconBg: const Color(0xFFFEF0EF),
                label: 'Delete',
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(donation);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: label == 'Delete' ? const Color(0xFFD63B2F) : _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── DELETE CONFIRM ───────────────────────────────────────────────────────

  void _confirmDelete(Donation donation) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF0EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_rounded, color: Color(0xFFD63B2F), size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Donation?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                style: TextStyle(fontSize: 13, color: _slate),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _slate,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Donation deleted'),
                            backgroundColor: _forest,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD63B2F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HELPERS (ALL UNCHANGED) ──────────────────────────────────────────────

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'clothes':
        return Icons.checkroom_rounded;
      case 'electronics':
        return Icons.devices_rounded;
      case 'books':
        return Icons.menu_book_rounded;
      case 'furniture':
        return Icons.chair_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  List<Donation> _getSampleDonations() {
    return [
      Donation(
        id: '1',
        title: 'Fresh Vegetables Pack',
        description: '5kg mixed fresh vegetables from farm',
        category: 'Food',
        quantity: '5 kg',
        condition: 'Excellent',
        donorId: 'donor1',
        donorName: 'John Doe',
        location: 'Chennai',
        status: 'matched',
        postedDate: DateTime.now().subtract(const Duration(days: 2)),
        views: 45,
        requests: 8,
        recipientId: 'rec1',
        recipientName: 'NGO Helper',
        pickupDate: DateTime.now().add(const Duration(days: 1)),
      ),
      Donation(
        id: '2',
        title: 'Winter Clothes Bundle',
        description: '10 pieces of winter clothing in good condition',
        category: 'Clothes',
        quantity: '10 pieces',
        condition: 'Good',
        donorId: 'donor1',
        donorName: 'John Doe',
        location: 'Chennai',
        status: 'active',
        postedDate: DateTime.now().subtract(const Duration(days: 5)),
        views: 67,
        requests: 12,
      ),
      Donation(
        id: '3',
        title: 'Educational Books Set',
        description: 'Collection of NCERT books for class 10',
        category: 'Books',
        quantity: '15 books',
        condition: 'Like New',
        donorId: 'donor1',
        donorName: 'John Doe',
        location: 'Chennai',
        status: 'completed',
        postedDate: DateTime.now().subtract(const Duration(days: 10)),
        views: 89,
        requests: 15,
        recipientId: 'rec2',
        recipientName: 'School Aid',
      ),
    ];
  }
}

// ─── SHARED HELPERS (copied from donor dashboard) ─────────────────────────

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

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    const spacing = 22.0;
    const radius = 1.2;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}
