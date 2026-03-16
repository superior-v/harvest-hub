import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harvest/core/constants/app_constants.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  // Real-time stats
  int totalDonations = 0;
  int activeListings = 0;
  int completedDonations = 0;
  int totalRequests = 0;
  bool _isLoadingStats = true;

  late AnimationController _fadeController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;

  // ─── Design Tokens ────────────────────────────────────────────────────────
  static const Color _forest = Color(0xFF1A3A1F); // deep forest green
  static const Color _leaf = Color(0xFF3D7A45); // mid leaf
  static const Color _sprout = Color(0xFF6BBF6A); // fresh sprout
  static const Color _mist = Color(0xFFF3F7F0); // pale mist bg
  static const Color _clay = Color(0xFFD4956A); // warm clay / amber
  static const Color _dew = Color(0xFFE8F4EA); // lightest tint
  static const Color _ink = Color(0xFF0F1F12); // near-black
  static const Color _slate = Color(0xFF6B7A6E); // muted text
  static const Color _divider = Color(0xFFDEEADE); // subtle divider
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _sky = Color(0xFF4A90C4); // sky blue accent

  // ─── Gradient ─────────────────────────────────────────────────────────────
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

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
    _staggerController.forward();

    _loadDonorStats();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  // ─── FUNCTIONS UNCHANGED ──────────────────────────────────────────────────

  Future<void> _loadDonorStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final donationsSnapshot = await FirebaseFirestore.instance.collection('donations').where('donorId', isEqualTo: user.uid).get();

      final activeSnapshot = await FirebaseFirestore.instance.collection('donations').where('donorId', isEqualTo: user.uid).where('status', isEqualTo: 'available').get();

      final completedSnapshot = await FirebaseFirestore.instance.collection('donations').where('donorId', isEqualTo: user.uid).where('status', isEqualTo: 'completed').get();

      // Update core donation counters first so they don't stay at 0
      // when request counting has a transient failure.
      if (!mounted) return;
      setState(() {
        totalDonations = donationsSnapshot.docs.length;
        activeListings = activeSnapshot.docs.length;
        completedDonations = completedSnapshot.docs.length;
        _isLoadingStats = false;
      });

      int requestCount = 0;
      for (final doc in donationsSnapshot.docs) {
        try {
          final requests = await FirebaseFirestore.instance.collection('requests').where('donationId', isEqualTo: doc.id).get();
          requestCount += requests.docs.length;
        } catch (e) {
          debugPrint('Error counting requests for donation ${doc.id}: $e');
        }
      }

      if (!mounted) return;
      setState(() => totalRequests = requestCount);
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (!mounted) return;
      setState(() => _isLoadingStats = false);
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);
    if (difference.inDays > 0)
      return '${difference.inDays}d ago';
    else if (difference.inHours > 0)
      return '${difference.inHours}h ago';
    else if (difference.inMinutes > 0)
      return '${difference.inMinutes}m ago';
    else
      return 'Just now';
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _mist,
      extendBodyBehindAppBar: true,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _loadDonorStats,
          color: _sprout,
          backgroundColor: _cardBg,
          strokeWidth: 2.5,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _buildHeroAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildStatsRow(),
                    _buildQuickActions(),
                    _buildActiveDonations(),
                    _buildRecentActivity(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── HERO APP BAR ─────────────────────────────────────────────────────────

  Widget _buildHeroAppBar() {
    final user = FirebaseAuth.instance.currentUser;
    // Prefer displayName, then email prefix, then a generic fallback
    final rawName = user?.displayName?.trim();
    final emailPrefix = user?.email?.split('@').first ?? '';
    final firstName = (rawName != null && rawName.isNotEmpty)
        ? rawName.split(' ').first
        : emailPrefix.isNotEmpty
            ? emailPrefix
            : 'there';
    final avatarLetter = firstName[0].toUpperCase();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _forest,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero gradient
            Container(decoration: const BoxDecoration(gradient: _heroGradient)),

            // Subtle blob — smaller and tucked away
            Positioned(
              right: -30,
              top: -30,
              child: _Blob(
                size: 140,
                color: _leaf.withOpacity(0.30),
              ),
            ),

            // Dot grid texture
            Positioned.fill(
              child: CustomPaint(painter: _DotGridPainter()),
            ),

            // Content — compact single-row layout
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Greeting line
                            Text(
                              greeting,
                              style: const TextStyle(
                                color: Color(0xFF9DC99A),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // User name — large and prominent
                            Text(
                              firstName,
                              style: const TextStyle(
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
                                    color: _sprout,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'Verified Donor',
                                  style: TextStyle(
                                    color: Color(0xFF9DC99A),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Avatar + bell in a tighter row
                      Row(
                        children: [
                          // Notification bell
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/requests'),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                ),
                                if (totalRequests > 0)
                                  Positioned(
                                    right: -3,
                                    top: -3,
                                    child: Container(
                                      width: 15,
                                      height: 15,
                                      decoration: const BoxDecoration(
                                        color: _clay,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          totalRequests > 9 ? '9+' : '$totalRequests',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 7,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Avatar
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/profile'),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF5BA05E),
                                    Color(0xFF3D7A45)
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STATS ROW ────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: _isLoadingStats
          ? _buildStatsShimmer()
          : Column(
              children: [
                // Primary wide stat card
                _StatHeroCard(
                  value: totalDonations,
                  label: 'Total donations',
                  sublabel: 'All time',
                  gradient: _sproutGradient,
                  icon: Icons.volunteer_activism_rounded,
                  accentColor: const Color(0xFFB8E8B5),
                  onTap: null,
                  stagger: 0,
                  controller: _staggerController,
                ),
                const SizedBox(height: 10),
                // 3-column row
                Row(
                  children: [
                    Expanded(
                      child: _StatMiniCard(
                        value: activeListings,
                        label: 'Active',
                        icon: Icons.pending_actions_rounded,
                        color: _leaf,
                        bgColor: _dew,
                        onTap: () => Navigator.pushNamed(context, '/donation-tracking'),
                        stagger: 1,
                        controller: _staggerController,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatMiniCard(
                        value: completedDonations,
                        label: 'Done',
                        icon: Icons.task_alt_rounded,
                        color: _sky,
                        bgColor: const Color(0xFFE7F3FB),
                        onTap: null,
                        stagger: 2,
                        controller: _staggerController,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatMiniCard(
                        value: totalRequests,
                        label: 'Requests',
                        icon: Icons.inbox_rounded,
                        color: _clay,
                        bgColor: const Color(0xFFFAEEE5),
                        onTap: () => Navigator.pushNamed(context, '/requests'),
                        stagger: 3,
                        controller: _staggerController,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildStatsShimmer() {
    return Column(
      children: [
        _ShimmerBox(height: 90, radius: 20),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _ShimmerBox(height: 80, radius: 16)),
          const SizedBox(width: 10),
          Expanded(child: _ShimmerBox(height: 80, radius: 16)),
          const SizedBox(width: 10),
          Expanded(child: _ShimmerBox(height: 80, radius: 16)),
        ]),
      ],
    );
  }

  // ─── QUICK ACTIONS ────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = [
      _ActionItem(icon: Icons.add_circle_rounded, label: 'Post', color: _leaf, route: '/post-donation'),
      _ActionItem(icon: Icons.map_rounded, label: 'Map', color: _sky, route: '/map-view'),
      _ActionItem(icon: Icons.inbox_rounded, label: 'Requests', color: _clay, route: '/requests'),
      _ActionItem(icon: Icons.track_changes_rounded, label: 'Track', color: _forest, route: '/donation-tracking'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Quick Actions'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _forest.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: actions.map((a) {
                return Expanded(
                  child: _buildActionButton(
                    icon: a.icon,
                    label: a.label,
                    color: a.color,
                    onTap: () {
                      if (a.route == '/post-donation') {
                        Navigator.pushNamed(context, a.route).then((_) => _loadDonorStats());
                      } else {
                        Navigator.pushNamed(context, a.route);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _slate,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SECTION HEADER ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, {String? actionText, VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: _sprout,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        if (actionText != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _dew,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                actionText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _leaf,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── ACTIVE DONATIONS ─────────────────────────────────────────────────────

  Widget _buildActiveDonations() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _buildSectionHeader(
              'Active Donations',
              actionText: 'See all',
              onAction: () => Navigator.pushNamed(context, '/donation-tracking'),
            ),
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('donations').where('donorId', isEqualTo: user.uid).where('status', isEqualTo: 'available').orderBy('createdAt', descending: true).limit(5).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: _ShimmerBox(height: 200, width: 160, radius: 20),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: _buildEmptyState(
                    icon: '🌱',
                    title: 'No active listings',
                    subtitle: 'Post your first donation and start making impact.',
                    ctaLabel: 'Post now',
                    onCta: () => Navigator.pushNamed(context, '/post-donation').then((_) => _loadDonorStats()),
                  ),
                );
              }

              return SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.only(right: 20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('requests').where('donationId', isEqualTo: doc.id).get(),
                      builder: (context, requestSnapshot) {
                        final requestCount = requestSnapshot.hasData ? requestSnapshot.data!.docs.length : 0;
                        return _buildDonationCard(
                          title: data['title'] ?? 'Untitled',
                          category: data['category'] ?? 'Other',
                          requests: requestCount,
                          imageUrl: (data['imageUrls'] as List?)?.isNotEmpty == true ? data['imageUrls'][0] : null,
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard({
    required String title,
    required String category,
    required int requests,
    String? imageUrl,
  }) {
    final hasRequests = requests > 0;
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _forest.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                SizedBox(
                  height: 108,
                  width: double.infinity,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                ),
                // Category pill overlay
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _forest.withOpacity(0.7),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasRequests ? const Color(0xFFFAEEE5) : _dew,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasRequests ? Icons.local_fire_department_rounded : Icons.hourglass_empty_rounded,
                        size: 11,
                        color: hasRequests ? _clay : _slate,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasRequests ? '$requests req.' : 'Waiting',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: hasRequests ? _clay : _slate,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: _dew,
      child: Center(
        child: Icon(Icons.eco_rounded, size: 36, color: _leaf.withOpacity(0.4)),
      ),
    );
  }

  // ─── RECENT ACTIVITY ──────────────────────────────────────────────────────

  Widget _buildRecentActivity() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Recent Activity'),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('donations').where('donorId', isEqualTo: user.uid).orderBy('createdAt', descending: true).limit(5).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  children: List.generate(
                      3,
                      (_) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ShimmerBox(height: 64, radius: 16),
                          )),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(
                  icon: '📭',
                  title: 'No activity yet',
                  subtitle: 'Your donation history will appear here.',
                );
              }

              return Container(
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
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(left: 68),
                    child: Divider(height: 1, thickness: 0.5, color: _divider),
                  ),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'available';
                    final timestamp = data['createdAt'] as Timestamp?;

                    IconData icon;
                    Color color;
                    Color bgColor;
                    String title;

                    switch (status) {
                      case 'completed':
                        icon = Icons.check_circle_rounded;
                        color = _sprout;
                        bgColor = _dew;
                        title = 'Donation completed';
                        break;
                      case 'claimed':
                        icon = Icons.handshake_rounded;
                        color = _sky;
                        bgColor = const Color(0xFFE7F3FB);
                        title = 'Donation claimed';
                        break;
                      default:
                        icon = Icons.add_circle_rounded;
                        color = _leaf;
                        bgColor = _dew;
                        title = 'New donation posted';
                    }

                    return _buildActivityItem(
                      icon: icon,
                      title: title,
                      subtitle: data['title'] ?? 'Untitled donation',
                      time: _formatTime(timestamp),
                      color: color,
                      bgColor: bgColor,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
    required Color bgColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _slate,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _slate.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────

  Widget _buildEmptyState({
    required String icon,
    required String title,
    required String subtitle,
    String? ctaLabel,
    VoidCallback? onCta,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _divider, width: 1),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: _slate,
              height: 1.5,
            ),
          ),
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onCta,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(
                  gradient: _sproutGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ctaLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── FAB ──────────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/post-donation').then((_) => _loadDonorStats()),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: _sproutGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _leaf.withOpacity(0.40),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Post donation',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOTTOM NAV ───────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    const items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.format_list_bulleted_rounded, label: 'Donations'),
      _NavItem(icon: Icons.map_rounded, label: 'Map'),
      _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    ];
    final routes = [
      '',
      '/donation-tracking',
      '/map-view',
      '/profile'
    ];

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: _forest.withOpacity(0.08),
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
                      Navigator.pushNamed(context, routes[i]);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
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
                          color: selected ? _leaf : _slate,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                            color: selected ? _leaf : _slate,
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

// ─── SUPPORTING DATA CLASSES ────────────────────────────────────────────────

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _ActionItem({required this.icon, required this.label, required this.color, required this.route});
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─── STAT HERO CARD ─────────────────────────────────────────────────────────

class _StatHeroCard extends StatelessWidget {
  final int value;
  final String label;
  final String sublabel;
  final LinearGradient gradient;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final int stagger;
  final AnimationController controller;

  const _StatHeroCard({
    required this.value,
    required this.label,
    required this.sublabel,
    required this.gradient,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    required this.stagger,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        final begin = stagger * 0.15;
        final end = begin + 0.6;
        final t = Curves.easeOutCubic.transform(
          ((controller.value - begin) / (end - begin)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3D7A45).withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sublabel.toUpperCase(),
                      style: TextStyle(
                        color: accentColor.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$value',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── STAT MINI CARD ─────────────────────────────────────────────────────────

class _StatMiniCard extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;
  final int stagger;
  final AnimationController controller;

  const _StatMiniCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    required this.stagger,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        final begin = stagger * 0.12;
        final end = begin + 0.6;
        final t = Curves.easeOutCubic.transform(
          ((controller.value - begin) / (end - begin)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(height: 10),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -1,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7A6E),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SHIMMER BOX ────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;
  const _ShimmerBox({required this.height, required this.radius, this.width});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EDEA).withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// ─── BLOB SHAPE ─────────────────────────────────────────────────────────────

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

// ─── DOT GRID PAINTER ───────────────────────────────────────────────────────

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
