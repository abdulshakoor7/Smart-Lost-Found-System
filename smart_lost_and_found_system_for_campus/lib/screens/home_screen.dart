import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../user_session.dart';

// --- IMPORTS ---
import 'alerts_screen.dart';
import 'profile_screen.dart';
import 'my_items_screen.dart';
import 'report_selection_screen.dart';
import 'settings_screen.dart';
import 'item_detail_screen.dart';
import 'package:smart_lost_and_found_system_for_campus/core/utils/time_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  // Theme: Deep Navy
  final Color _bg = const Color(0xFF0F172A);
  final Color _accentBlue = const Color(0xFF3B82F6);

  final List<Widget> _pages = [
    const HomeContent(),
    const MyItemsScreen(),
    const ReportSelectionScreen(),
    const AlertsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Breakpoint for Web
    bool isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: _bg,
      body: _pages[_navIndex],
      // Retain BottomNav for Mobile Only
      bottomNavigationBar: isWide ? null : Theme(
        data: Theme.of(context).copyWith(cardColor: Theme.of(context).cardColor,),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0F172A),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _accentBlue,
          unselectedItemColor: Colors.blueGrey,
          showUnselectedLabels: true,
          currentIndex: _navIndex,
          onTap: (index) => setState(() => _navIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'My Items'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: 'Report'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Updates'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final Color _cardBg = const Color(0xFF1E293B);
  final Color _vibrantBlue = const Color(0xFF3B82F6);
  final Color _foundGreen = const Color(0xFF10B981);
  final Color _lostRed = const Color(0xFFEF4444);

  List<dynamic> _allItems = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All', 'Lost', 'Found', 'Electronics', 'Bags', 'Keys', 'Documents', 'Others'
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final items = await ApiService.fetchItems();
      if (mounted) {
        setState(() {
          _allItems = items;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredItems = _allItems.where((item) {
        bool matchesCategory = (_selectedCategory == 'All' ||
            item['category'] == _selectedCategory ||
            (_selectedCategory == 'Lost' && item['item_type'] == 'LOST') ||
            (_selectedCategory == 'Found' && item['item_type'] == 'FOUND'));

        bool matchesSearch =
        (item['title'].toString().toLowerCase().contains(query) ||
            item['description'].toString().toLowerCase().contains(query));

        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  Future<void> _runAISearch() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null) {
      setState(() => _isLoading = true);
      final matches = await ApiService.smartSearch(imageBytes: result.files.first.bytes);
      setState(() {
        _filteredItems = matches;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isWeb = constraints.maxWidth > 900;

      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Column(
          children: [
            // 1. DYNAMIC HEADER
            isWeb ? _buildWebHeader() : _buildMobileHeader(),

            // 2. MAIN BODY
            Expanded(
              child: Row(
                children: [
                  if (isWeb) _buildWebSidebar(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchData,
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator(color: _vibrantBlue))
                          : _filteredItems.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWeb ? 5 : 2,
                          childAspectRatio: isWeb ? 0.75 : 0.72,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) =>
                            _buildGridCard(_filteredItems[index], isWeb),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // --- WEB ONLY HEADER ---
  Widget _buildWebHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.2), blurRadius: 10)],
      ),
      child: Row(
        children: [
          // Left Corner: Settings + Profile
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen())),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen())),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: UserSession.photoUrl.isNotEmpty ? NetworkImage(UserSession.photoUrl) : null,
                  child: UserSession.photoUrl.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 10),
                Text(UserSession.name.split(" ")[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 40),
          // Center: Search
          Expanded(
            child: Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => _applyFilters(),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'What are you looking for?',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                  icon: const Icon(Icons.search, color: Colors.white24, size: 20),
                  suffixIcon: IconButton(icon: Icon(Icons.camera_alt_rounded, color: _vibrantBlue, size: 20), onPressed: _runAISearch),
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
          // Right Corner: Report + Updates
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ReportSelectionScreen())),
            icon: const Icon(Icons.add_box_rounded, size: 18),
            label: const Text("REPORT ITEM"),
            style: ElevatedButton.styleFrom(backgroundColor: _vibrantBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
          ),
          const SizedBox(width: 15),
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AlertsScreen())),
          ),
        ],
      ),
    );
  }

  // --- ORIGINAL MOBILE HEADER ---
  Widget _buildMobileHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen())),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _cardBg,
                      backgroundImage: UserSession.photoUrl.isNotEmpty ? NetworkImage(UserSession.photoUrl) : null,
                      child: UserSession.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white70) : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hi, ${UserSession.name.split(" ")[0]}!', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text('Campus Explorer', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              _buildTopIcon(Icons.settings_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()))),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16)),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => _applyFilters(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search by keyword...',
                hintStyle: const TextStyle(color: Colors.white38),
                icon: const Icon(Icons.search, color: Colors.white38),
                suffixIcon: IconButton(icon: Icon(Icons.camera_alt_rounded, color: _vibrantBlue), onPressed: _runAISearch),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _categories.map((c) => _buildChip(c)).toList()),
          ),
        ],
      ),
    );
  }

  // --- SIDEBAR: Alibaba Web Style ---
  Widget _buildWebSidebar() {
    return Container(
      width: 240,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 25, bottom: 15),
            child: Text("CATEGORIES", style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                String cat = _categories[index];
                bool isSel = _selectedCategory == cat;
                return ListTile(
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    _applyFilters();
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                  title: Text(cat, style: TextStyle(color: isSel ? _vibrantBlue : Colors.white70, fontSize: 14, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  leading: Icon(Icons.chevron_right_rounded, color: isSel ? _vibrantBlue : Colors.white10, size: 18),
                  tileColor: isSel ? _vibrantBlue.withValues(alpha:0.05) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    bool isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          setState(() => _selectedCategory = label);
          _applyFilters();
        },
        backgroundColor: _cardBg,
        selectedColor: _vibrantBlue,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> item, bool isWeb) {
    bool isFound = item['item_type'] == 'FOUND';
    String imageUrl = item['image'] ?? "";
    String fullImageUrl = "";

    if (imageUrl.isNotEmpty) {
      String baseUrl = kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";
      fullImageUrl = imageUrl.startsWith('http') ? imageUrl : "$baseUrl${imageUrl.startsWith('/') ? '' : '/'}$imageUrl";
      if (!fullImageUrl.contains('/media/')) {
        fullImageUrl = fullImageUrl.replaceFirst('/item_images', '/media/item_images');
      }
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailScreen(itemData: item))),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3748),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: fullImageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(fullImageUrl), fit: BoxFit.cover) : null,
                ),
                child: fullImageUrl.isEmpty ? const Icon(Icons.image_not_supported, color: Colors.white24) : null,
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item['title'] ?? "Unknown", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.location_on, size: 10, color: _vibrantBlue),
                        const SizedBox(width: 4),
                        Expanded(child: Text(item['location'] ?? "UOG", style: const TextStyle(color: Colors.white54, fontSize: 10), maxLines: 1)),
                      ]),
                    ]),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isFound ? _foundGreen.withValues(alpha:0.1) : _lostRed.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: isFound ? _foundGreen : _lostRed, width: 0.5),
                          ),
                          child: Text(isFound ? "FOUND" : "LOST", style: TextStyle(color: isFound ? _foundGreen : _lostRed, fontWeight: FontWeight.bold, fontSize: 9)),
                        ),
                        Text(TimeManager.formatTimestamp(item['date_reported'] ?? ""), style: const TextStyle(color: Colors.white24, fontSize: 9)),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No matches found", style: TextStyle(color: Colors.white38)));
  }

  Widget _buildTopIcon(IconData icon, VoidCallback tap) {
    return Container(
        decoration: BoxDecoration(color: _cardBg, shape: BoxShape.circle),
        child: IconButton(icon: Icon(icon, size: 20, color: Colors.white), onPressed: tap));
  }
}