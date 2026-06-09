import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'admin_item_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- THEME COLORS (Deep Navy & Slate) ---
  final Color _bgDeep = const Color(0xFF0F172A);      // Deepest Navy
  final Color _cardSlate = const Color(0xFF1E293B);   // Dark Slate Blue
  final Color _accentBlue = const Color(0xFF3B82F6);  // Vibrant UI Blue
  final Color _textMuted = const Color(0xFF94A3B8);   // Muted Gray-Blue

  List<dynamic> _allItems = [];
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final items = await ApiService.fetchItems();
      final logs = await ApiService.fetchAuditLogs();
      if (mounted) {
        setState(() {
          _allItems = items;
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic: Filter items for different queues
    final pending = _allItems.where((i) => i['status'] == 'PENDING').toList();
    final claims = _allItems.where((i) => i['status'] == 'CLAIM_REQUESTED').toList();

    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: AppBar(
        backgroundColor: _cardSlate,
        elevation: 4,
        shadowColor: Colors.black45,
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: _accentBlue, size: 28),
            const SizedBox(width: 12),
            const Text(
              'ADMIN CONSOLE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.2),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _fetchData,
          ),
          const SizedBox(width: 10),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _accentBlue,
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: _textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(child: _buildTabLabel("Pending", pending.length)),
            Tab(child: _buildTabLabel("Claims", claims.length)),
            Tab(child: _buildTabLabel("Audit Logs", _logs.length)),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _accentBlue))
          : Column(
        children: [
          _buildStatsRibbon(pending.length, claims.length),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQueueList(pending, Icons.hourglass_empty_rounded, Colors.amber),
                _buildQueueList(claims, Icons.verified_user_rounded, _accentBlue, isClaim: true),
                _buildAuditList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- STATS RIBBON: Dashboard Overview ---
  Widget _buildStatsRibbon(int pCount, int cCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: _bgDeep,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha:0.05))),
      ),
      child: Row(
        children: [
          _buildStatCard("Active Reports", _allItems.length.toString(), Icons.layers_outlined),
          const SizedBox(width: 15),
          _buildStatCard("Queue Wait", "$pCount Items", Icons.timer_outlined),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _cardSlate,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha:0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _accentBlue, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(value, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTabLabel(String text, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
          child: Text(count.toString(), style: const TextStyle(fontSize: 10, color: Colors.white70)),
        )
      ],
    );
  }

  // --- AUDIT LOGS: Console Style ---
  Widget _buildAuditList() {
    if (_logs.isEmpty) return _buildEmptyState("No system activity recorded.");
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _cardSlate,
            borderRadius: BorderRadius.circular(8),
            border: const Border(left: BorderSide(color: Colors.greenAccent, width: 4)),
          ),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.code_rounded, color: Colors.greenAccent, size: 20),
            title: Text(log['action'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            subtitle: Text("Executor: ${log['admin']}", style: TextStyle(color: _textMuted, fontSize: 12)),
            trailing: Text(
              log['time'].toString().split('T').last.substring(0, 5),
              style: TextStyle(color: _accentBlue, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  // --- ITEM QUEUES: Polished List ---
  Widget _buildQueueList(List<dynamic> items, IconData icon, Color iconColor, {bool isClaim = false}) {
    if (items.isEmpty) return _buildEmptyState("Queue is currently clear.");
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: _cardSlate,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.2), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: iconColor.withValues(alpha:0.1),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            title: Text(
              item['title'].toString().toUpperCase(),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                isClaim ? "Claimant: ${item['claimant_email']}" : "Loc: ${item['location']}",
                style: TextStyle(color: _textMuted, fontSize: 12),
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
            onTap: () async {
              final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminItemDetailScreen(itemData: item))
              );
              if (result == true) _fetchData();
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, color: _cardSlate, size: 80),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: _textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}