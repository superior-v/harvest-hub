import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harvest/core/constants/app_constants.dart';
import 'package:harvest/core/services/firestore_service.dart';
import 'package:harvest/core/widgets/custom_widgets.dart';
import 'package:harvest/models/request_model.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({Key? key}) : super(key: key);

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Future<String> _userRoleFuture;

  final List<String> filters = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
    'Completed',
    'Cancelled'
  ];

  // ─── Design Tokens ────────────────────────────────────────────────────────
  static const Color _ocean = Color(0xFF0D3D56);
  static const Color _wave = Color(0xFF1A6B8A);
  static const Color _foam = Color(0xFF4A90C4);
  static const Color _mist = Color(0xFFF0F6FA);
  static const Color _dew = Color(0xFFE4F2F8);
  static const Color _ink = Color(0xFF0A1E2A);
  static const Color _slate = Color(0xFF5A7080);
  static const Color _divider = Color(0xFFD8EAF2);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _leaf = Color(0xFF3D7A45);
  static const Color _sprout = Color(0xFF6BBF6A);
  static const Color _clay = Color(0xFFD4956A);
  static const Color _danger = Color(0xFFD63B2F);

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

  // ─── Status helpers ───────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _clay;
      case 'approved':
        return _leaf;
      case 'rejected':
        return _danger;
      case 'completed':
        return _foam;
      case 'cancelled':
        return _slate;
      default:
        return _slate;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFAEEE5);
      case 'approved':
        return const Color(0xFFE8F4EA);
      case 'rejected':
        return const Color(0xFFFEF0EF);
      case 'completed':
        return _dew;
      case 'cancelled':
        return const Color(0xFFF2F4F5);
      default:
        return const Color(0xFFF0F0EF);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.remove_circle_outline_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _userRoleFuture = _resolveUserRole();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            _buildActiveTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────

  Widget _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 148,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _ocean,
      titleSpacing: 0,
      title: const Row(
        children: [
          SizedBox(width: 4),
          Icon(Icons.assignment_rounded, size: 18, color: Color(0xFF8EC8E8)),
          SizedBox(width: 8),
          Text(
            'Requests',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
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
            Positioned(
              right: -20,
              top: -20,
              child: _Blob(size: 130, color: _wave.withOpacity(0.3)),
            ),
            Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: innerBoxIsScrolled ? 0 : 1,
                child: IgnorePointer(
                  ignoring: innerBoxIsScrolled,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'My Requests',
                            style: TextStyle(
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
                                  color: _foam,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Track and manage donation requests',
                                style: TextStyle(
                                  color: Color(0xFF8EC8E8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
        preferredSize: const Size.fromHeight(46),
        child: Container(
          color: _ocean,
          child: TabBar(
            controller: _tabController,
            indicatorColor: _foam,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.45),
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
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TABS ─────────────────────────────────────────────────────────────────

  Widget _buildActiveTab() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(child: _buildRequestsList(showActive: true)),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return _buildRequestsList(showActive: false);
  }

  // ─── FILTER CHIPS ─────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    return Container(
      height: 52,
      color: _mist,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? _wave : _cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _wave : _divider,
                    width: isSelected ? 0 : 0.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(color: _wave.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))
                        ]
                      : [],
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _slate,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── REQUESTS LIST (logic unchanged) ─────────────────────────────────────

  Widget _buildRequestsList({required bool showActive}) {
    return FutureBuilder<String>(
      future: _userRoleFuture,
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _wave));
        }

        final user = _auth.currentUser;
        if (user == null) {
          return _buildEmptyState(showActive: showActive, isDonor: false, emptyBecauseAuth: true);
        }

        final role = roleSnapshot.data ?? 'recipient';
        final isDonor = role.toLowerCase() == 'donor';
        final stream = isDonor ? _firestoreService.getDonorIncomingRequests(user.uid) : _firestoreService.getUserRequests(user.uid);

        return StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Failed to load requests',
                  style: TextStyle(color: _slate, fontSize: 14),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _wave));
            }

            final requests = snapshot.data?.docs.map(_mapRequestDoc).toList() ?? <DonationRequest>[];
            final filteredRequests = requests.where((r) {
              final status = _normalizeStatus(r.status);
              final isActive = status == 'pending' || status == 'approved';
              if (showActive && !isActive) return false;
              if (!showActive && isActive) return false;
              if (_selectedFilter != 'All' && status != _selectedFilter.toLowerCase()) {
                return false;
              }
              return true;
            }).toList();

            if (filteredRequests.isEmpty) {
              return _buildEmptyState(showActive: showActive, isDonor: isDonor);
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) => _buildRequestCard(filteredRequests[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({required bool showActive, required bool isDonor, bool emptyBecauseAuth = false}) {
    final title = emptyBecauseAuth ? 'Login required' : (showActive ? 'No active requests' : 'No history yet');
    final subtitle = emptyBecauseAuth ? 'Please sign in to view requests' : (isDonor ? (showActive ? 'Incoming recipient requests will appear here' : 'Completed or declined requests will appear here') : (showActive ? 'Browse donations and submit requests' : 'Your completed requests will appear here'));

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
            child: Center(
              child: Icon(
                showActive ? Icons.inbox_rounded : Icons.history_rounded,
                size: 28,
                color: _wave.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: _slate),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── REQUEST CARD ─────────────────────────────────────────────────────────

  Widget _buildRequestCard(DonationRequest request) {
    final normalizedStatus = _normalizeStatus(request.status);
    final isCurrentUserDonor = _auth.currentUser?.uid == request.donorId;
    final sColor = _statusColor(normalizedStatus);
    final sBg = _statusBg(normalizedStatus);
    final sIcon = _statusIcon(normalizedStatus);
    final statusText = DonationRequest.getStatusText(normalizedStatus);
    final daysSince = DateTime.now().difference(request.requestDate).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _ocean.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showRequestDetails(request),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: status + time + menu ──
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
                          Icon(sIcon, size: 12, color: sColor),
                          const SizedBox(width: 5),
                          Text(
                            statusText.toUpperCase(),
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
                      onTap: () => _showOptionsMenu(request),
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

                // ── Donation item row ──
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
                          _getCategoryIcon(request.donationCategory),
                          size: 21,
                          color: _wave,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.donationTitle,
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
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 12, color: _slate),
                              const SizedBox(width: 4),
                              Text(
                                request.donorName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _slate,
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

                // ── Message snippet ──
                if (request.message.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _mist,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.format_quote_rounded, size: 14, color: _slate.withOpacity(0.5)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            request.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: _slate,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Approved: pickup banner ──
                if (normalizedStatus == 'approved' && request.scheduledPickupDate != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4EA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _leaf.withOpacity(0.25), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_rounded, size: 15, color: _leaf),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pickup scheduled',
                                style: TextStyle(
                                  color: _leaf,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _formatDate(request.scheduledPickupDate!),
                                style: TextStyle(
                                  color: _leaf.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showPickupDetails(request),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: _leaf,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Rejected: donor response ──
                if (normalizedStatus == 'rejected' && request.donorResponse != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF0EF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _danger.withOpacity(0.2), width: 0.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: _danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request.donorResponse!,
                            style: TextStyle(
                              color: _danger.withOpacity(0.85),
                              fontSize: 12,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Pending: action buttons ──
                if (normalizedStatus == 'pending' && !isCurrentUserDonor) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _editRequest(request),
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: _dew,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _wave.withOpacity(0.3), width: 0.5),
                            ),
                            child: Center(
                              child: Text(
                                'Edit Request',
                                style: TextStyle(
                                  color: _wave,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _cancelRequest(request),
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF0EF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: _danger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (normalizedStatus == 'pending' && isCurrentUserDonor) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _rejectRequest(request),
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF0EF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Reject',
                                style: TextStyle(
                                  color: _danger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _approveRequest(request),
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F4EA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Approve',
                                style: TextStyle(
                                  color: _leaf,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── REQUEST DETAILS SHEET (logic unchanged) ──────────────────────────────

  void _showRequestDetails(DonationRequest request) {
    final sColor = _statusColor(request.status);
    final sBg = _statusBg(request.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
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
                        color: sBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _statusIcon(request.status),
                        color: sColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.donationTitle,
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
                            'Request · ${request.id}',
                            style: TextStyle(fontSize: 11, color: _slate),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: sBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        DonationRequest.getStatusText(request.status).toUpperCase(),
                        style: TextStyle(
                          color: sColor,
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section: Donation Details
                      _buildSheetSectionHeader('Donation Details'),
                      const SizedBox(height: 10),
                      _buildDetailRow('Item', request.donationTitle),
                      _buildDetailRow('Category', request.donationCategory),
                      _buildDetailRow('Donor', request.donorName),

                      const SizedBox(height: 16),
                      _buildSheetSectionHeader('Request Details'),
                      const SizedBox(height: 10),
                      _buildDetailRow('Submitted', _formatDate(request.requestDate)),
                      if (request.responseDate != null) _buildDetailRow('Response', _formatDate(request.responseDate!)),

                      // Message
                      if (request.message.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _mist,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your message',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _slate,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                request.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _ink,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Pickup address
                      if (request.pickupAddress != null) ...[
                        const SizedBox(height: 16),
                        _buildSheetSectionHeader('Pickup Location'),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F4EA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _leaf.withOpacity(0.2), width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _leaf.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.location_on_rounded, color: _leaf, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  request.pickupAddress!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _ink,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // CTA
                      if (_normalizeStatus(request.status) == 'approved')
                        _buildSheetCTA(
                          label: 'Contact Donor',
                          icon: Icons.message_rounded,
                          gradient: _foamGradient,
                          onTap: () => Navigator.pop(context),
                        ),

                      if (_normalizeStatus(request.status) == 'pending')
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _cancelRequest(request);
                                },
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF0EF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: _danger,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _editRequest(request);
                                },
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: _foamGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Edit Request',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _foam,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildSheetCTA({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _wave.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 9),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  // ─── PICKUP DETAILS DIALOG (logic unchanged) ──────────────────────────────

  void _showPickupDetails(DonationRequest request) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pickup Details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 18),
              _buildInfoRow(Icons.event_rounded, 'Date', _formatDate(request.scheduledPickupDate!)),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.location_on_rounded, 'Address', request.pickupAddress ?? 'Not specified'),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.person_rounded, 'Donor', request.donorName),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: _mist,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Center(
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: _slate,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: _foamGradient,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Center(
                          child: Text(
                            'Directions',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
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
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _dew,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: _wave),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: _slate)),
              Text(value, style: const TextStyle(fontSize: 13, color: _ink, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── OPTIONS MENU (logic unchanged) ───────────────────────────────────────

  void _showOptionsMenu(DonationRequest request) {
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
              if (request.status == 'pending') ...[
                _buildOptionTile(
                  icon: Icons.edit_rounded,
                  iconColor: _wave,
                  iconBg: _dew,
                  label: 'Edit Request',
                  onTap: () {
                    Navigator.pop(context);
                    _editRequest(request);
                  },
                ),
                _buildOptionTile(
                  icon: Icons.cancel_rounded,
                  iconColor: _danger,
                  iconBg: const Color(0xFFFEF0EF),
                  label: 'Cancel Request',
                  onTap: () {
                    Navigator.pop(context);
                    _cancelRequest(request);
                  },
                ),
              ],
              if (request.status == 'approved')
                _buildOptionTile(
                  icon: Icons.message_rounded,
                  iconColor: _wave,
                  iconBg: _dew,
                  label: 'Contact Donor',
                  onTap: () => Navigator.pop(context),
                ),
              _buildOptionTile(
                icon: Icons.share_rounded,
                iconColor: _foam,
                iconBg: const Color(0xFFE4F2F8),
                label: 'Share',
                onTap: () => Navigator.pop(context),
              ),
              if (request.status == 'completed' || request.status == 'rejected')
                _buildOptionTile(
                  icon: Icons.delete_rounded,
                  iconColor: _danger,
                  iconBg: const Color(0xFFFEF0EF),
                  label: 'Delete',
                  onTap: () {
                    Navigator.pop(context);
                    _deleteRequest(request);
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
                  color: label.contains('Cancel') || label.contains('Delete') ? _danger : _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── DIALOGS (logic unchanged) ────────────────────────────────────────────

  void _editRequest(DonationRequest request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Edit request feature coming soon'),
        backgroundColor: _ocean,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _cancelRequest(DonationRequest request) {
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
                  color: Color(0xFFFAEEE5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cancel_rounded, color: _clay, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Cancel Request?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  )),
              const SizedBox(height: 8),
              Text('Are you sure you want to cancel this request?', style: TextStyle(fontSize: 13, color: _slate), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: _mist,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Center(
                          child: Text('No', style: TextStyle(color: _slate, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _updateRequestStatus(request.id, 'cancelled', successMessage: 'Request cancelled');
                      },
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF0EF),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Center(
                          child: Text('Yes, Cancel', style: TextStyle(color: _danger, fontWeight: FontWeight.w700)),
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

  void _deleteRequest(DonationRequest request) {
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
                child: Icon(Icons.delete_rounded, color: _danger, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Delete Request?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  )),
              const SizedBox(height: 8),
              Text('This action cannot be undone.', style: TextStyle(fontSize: 13, color: _slate), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: _mist,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Center(
                          child: Text('Cancel', style: TextStyle(color: _slate, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Request deleted'),
                            backgroundColor: _danger,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: _danger,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Center(
                          child: Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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

  // ─── HELPERS (all unchanged) ──────────────────────────────────────────────

  Future<String> _resolveUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return 'recipient';

    try {
      final doc = await _firestoreService.getUserProfile(user.uid);
      final data = doc.data() as Map<String, dynamic>?;
      return (data?['role'] as String? ?? 'recipient').toLowerCase();
    } catch (_) {
      return 'recipient';
    }
  }

  DonationRequest _mapRequestDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final status = _normalizeStatus((data['status'] as String? ?? 'pending'));

    return DonationRequest(
      id: doc.id,
      donationId: data['donationId'] as String? ?? '',
      donationTitle: data['donationTitle'] as String? ?? 'Donation Item',
      donationCategory: data['donationCategory'] as String? ?? 'Other',
      recipientId: data['recipientId'] as String? ?? '',
      recipientName: data['recipientName'] as String? ?? 'Recipient',
      donorId: data['donorId'] as String? ?? '',
      donorName: data['donorName'] as String? ?? 'Donor',
      status: status,
      message: data['message'] as String? ?? '',
      requestDate: _toDateTime(data['createdAt']) ?? DateTime.now(),
      responseDate: _toDateTime(data['responseDate'] ?? data['updatedAt']),
      pickupAddress: data['pickupAddress'] as String?,
      scheduledPickupDate: _toDateTime(data['scheduledPickupDate']),
      donorResponse: data['donorResponse'] as String?,
    );
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _normalizeStatus(String status) {
    final lower = status.toLowerCase();
    if (lower == 'accepted') return 'approved';
    return lower;
  }

  Future<void> _updateRequestStatus(String requestId, String status, {required String successMessage}) async {
    try {
      await _firestoreService.updateRequestStatus(requestId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: _ocean,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update request: $e'),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _approveRequest(DonationRequest request) {
    _updateRequestStatus(request.id, 'approved', successMessage: 'Request approved');
  }

  void _rejectRequest(DonationRequest request) {
    _updateRequestStatus(request.id, 'rejected', successMessage: 'Request rejected');
  }

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
      case 'medicine':
        return Icons.medication_rounded;
      case 'toys':
        return Icons.toys_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  List<DonationRequest> _getSampleRequests() {
    return [
      DonationRequest(
        id: 'REQ001',
        donationId: 'DON001',
        donationTitle: 'Fresh Vegetables Pack',
        donationCategory: 'Food',
        recipientId: 'rec1',
        recipientName: 'Current User',
        donorId: 'donor1',
        donorName: 'John Doe',
        status: 'approved',
        message: 'We need this for our community kitchen serving 50 families daily.',
        requestDate: DateTime.now().subtract(const Duration(days: 3)),
        responseDate: DateTime.now().subtract(const Duration(days: 1)),
        scheduledPickupDate: DateTime.now().add(const Duration(days: 2)),
        pickupAddress: '123 Main Street, Chennai - 600001',
        donorResponse: 'Happy to help! Please collect between 9 AM - 5 PM',
      ),
      DonationRequest(
        id: 'REQ002',
        donationId: 'DON002',
        donationTitle: 'Winter Clothes Bundle',
        donationCategory: 'Clothes',
        recipientId: 'rec1',
        recipientName: 'Current User',
        donorId: 'donor2',
        donorName: 'Sarah Smith',
        status: 'pending',
        message: 'These would help homeless people in our shelter.',
        requestDate: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      DonationRequest(
        id: 'REQ003',
        donationId: 'DON003',
        donationTitle: 'Educational Books Set',
        donationCategory: 'Books',
        recipientId: 'rec1',
        recipientName: 'Current User',
        donorId: 'donor3',
        donorName: 'Mike Johnson',
        status: 'rejected',
        message: 'Need these books for our rural school library.',
        requestDate: DateTime.now().subtract(const Duration(days: 7)),
        responseDate: DateTime.now().subtract(const Duration(days: 6)),
        donorResponse: 'Sorry, already promised to another organization.',
      ),
      DonationRequest(
        id: 'REQ004',
        donationId: 'DON004',
        donationTitle: 'Old Furniture Set',
        donationCategory: 'Furniture',
        recipientId: 'rec1',
        recipientName: 'Current User',
        donorId: 'donor4',
        donorName: 'Emma Brown',
        status: 'completed',
        message: 'Perfect for our new community center!',
        requestDate: DateTime.now().subtract(const Duration(days: 15)),
        responseDate: DateTime.now().subtract(const Duration(days: 14)),
        scheduledPickupDate: DateTime.now().subtract(const Duration(days: 10)),
        pickupAddress: '456 Park Avenue, Chennai - 600002',
      ),
    ];
  }
}

// ─── SHARED PAINTERS ──────────────────────────────────────────────────────

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
    for (double x = 0; x < size.width; x += 22) {
      for (double y = 0; y < size.height; y += 22) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}
