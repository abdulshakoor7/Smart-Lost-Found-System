import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../user_session.dart';
import 'item_detail_screen.dart';

class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- FIGMA STYLE COLORS ---
  final Color _bg = const Color(0xFF0F172A); // Deep Navy
  final Color _cardBg = const Color(0xFF1E293B); // Charcoal
  final Color _primaryBlue = const Color(0xFF3B82F6); // Vibrant Blue
  final Color _lostRed = const Color(0xFFEF4444); // Rose Red
  final Color _foundGreen = const Color(0xFF10B981); // Emerald Green

  List<dynamic> _lostItems = [];
  List<dynamic> _foundItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMyItems();
  }

  // --- LOGIC (REMAINS UNCHANGED) ---
  Future<void> _fetchMyItems() async {
    try {
      final allItems = await ApiService.fetchItems();
      if (mounted) {
        setState(() {
          String myEmail = UserSession.email.trim().toLowerCase();
          final myItems = allItems.where((item) {
            String itemEmail = (item['user_email'] ?? '').toString().trim().toLowerCase();
            return itemEmail == myEmail;
          }).toList();

          _lostItems = myItems.where((item) =>
          item['item_type'].toString().toUpperCase() == 'LOST').toList();

          _foundItems = myItems.where((item) =>
          item['item_type'].toString().toUpperCase() == 'FOUND').toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg, // Figma Background
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
            'My Activity',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryBlue,
          unselectedLabelColor: Colors.blueAccent.shade100,
          indicatorColor: _primaryBlue,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Reported Lost'),
            Tab(text: 'Reported Found'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryBlue))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildList(_lostItems, isLostTab: true),
          _buildList(_foundItems, isLostTab: false),
        ],
      ),
    );
  }

  Widget _buildList(List<dynamic> items, {required bool isLostTab}) {
    if (items.isEmpty) {
      return _buildEmptyState(isLostTab);
    }
    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _fetchMyItems,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildItemCard(items[index], isLostTab);
        },
      ),
    );
  }

  // --- STYLED FIGMA ITEM CARD ---
  Widget _buildItemCard(Map<String, dynamic> item, bool isLostTab) {
    String status = item['status'] ?? 'PENDING';
    Color statusColor = status == 'VERIFIED' ? _foundGreen : (status == 'MATCH_FOUND' ? _primaryBlue : Colors.orange);

    String dateStr = item['date_reported'] ?? "";
    if (dateStr.length > 10) dateStr = dateStr.substring(0, 10);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ItemDetailScreen(itemData: item)),
        );
        if (result == true) _fetchMyItems();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _cardBg, // Figma Card Background
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon Container
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: _primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                      isLostTab ? Icons.search_off_rounded : Icons.check_circle_outline_rounded,
                      color: _primaryBlue,
                      size: 32
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          item['title'] ?? "Unknown",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)
                      ),
                      const SizedBox(height: 4),
                      Text(
                          'Reported: $dateStr',
                          style: TextStyle(color: Colors.blueAccent.shade400, fontSize: 12)
                      ),
                      const SizedBox(height: 10),
                      // Status Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withValues(alpha: 0.2))
                        ),
                        child: Text(
                            status,
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.blueAccent.shade100),
              ],
            ),
            const SizedBox(height: 20),
            // DELETE ACTION
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  bool confirm = await showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: _cardBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text("Delete Report?", style: TextStyle(color: Colors.white)),
                        content: const Text("This action cannot be undone.", style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: Text("Delete", style: TextStyle(color: _lostRed, fontWeight: FontWeight.bold))),
                        ],
                      )
                  ) ?? false;

                  if (confirm) {
                    bool success = await ApiService.deleteItem(item['id']);
                    if (mounted && success) {
                      _fetchMyItems();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report removed"), backgroundColor: Colors.black));
                    }
                  }
                },
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: _lostRed),
                label: Text("Delete Report", style: TextStyle(color: _lostRed, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _lostRed.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isLost) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.blueAccent.shade400),
          const SizedBox(height: 16),
          Text(
              isLost ? "No lost items reported yet" : "No found items reported yet",
              style: TextStyle(color: Colors.blueAccent.shade400, fontSize: 16)
          ),
        ],
      ),
    );
  }
}