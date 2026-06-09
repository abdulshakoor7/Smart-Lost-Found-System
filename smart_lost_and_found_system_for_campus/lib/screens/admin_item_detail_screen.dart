import 'package:flutter/material.dart';
import '../services/api_service.dart';


class AdminItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;

  const AdminItemDetailScreen({super.key, required this.itemData});

  @override
  State<AdminItemDetailScreen> createState() => _AdminItemDetailScreenState();
}

class _AdminItemDetailScreenState extends State<AdminItemDetailScreen> {
  final Color _bg = const Color(0xFFF9FAFB);
  final Color _primaryBlue = const Color(0xFF2563EB);
  bool _isProcessing = false;

  // --- 1. UPDATE STATUS (Approve/Reject) ---
  Future<void> _updateStatus(String status) async {
    setState(() => _isProcessing = true);
    bool success = await ApiService.updateItemStatus(widget.itemData['id'], status);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Item status updated to $status"), backgroundColor: Colors.green)
      );
      Navigator.pop(context, true); // Return true to refresh queue
    }
  }

  // --- 2. BAN USER LOGIC (Task 3) ---
  Future<void> _manageUserAccount(String action) async {
    String userEmail = widget.itemData['user_email'] ?? "";
    if (userEmail.isEmpty) return;

    // Confirmation Dialog
    bool confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("${action.toUpperCase()} User?"),
        content: Text("Are you sure you want to $action the user: $userEmail?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: Text("Yes, $action"),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isProcessing = true);

    // Call the ban function in api_service
    bool success = await ApiService.toggleUserStatus(userEmail, action);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User has been ${action}ned successfully."), backgroundColor: Colors.black)
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update user status."), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = widget.itemData['image'] ?? "";
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = "http://10.0.2.2:8000$imageUrl";
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text("Item Audit", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. IMAGE EVIDENCE
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    image: imageUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.contain)
                        : null,
                  ),
                  child: imageUrl.isEmpty ? const Icon(Icons.image_not_supported, size: 50, color: Colors.grey) : null,
                ),
                const SizedBox(height: 24),

                // 2. INFORMATION TABLE
                _buildSectionHeader("Item Information"),
                _buildInfoRow("Title", widget.itemData['title']),
                _buildInfoRow("Category", widget.itemData['category']),
                _buildInfoRow("Status", widget.itemData['status']),
                const SizedBox(height: 24),

                _buildSectionHeader("User Details"),
                _buildInfoRow("Reported By", widget.itemData['user_email'] ?? 'Unknown'),
                _buildInfoRow("Student ID", widget.itemData['student_id'] ?? 'N/A'),
                const SizedBox(height: 24),

                // 3. CLAIM PROOF (If applicable)
                if (widget.itemData['status'] == 'CLAIM_REQUESTED' && widget.itemData['claim_proof'] != null) ...[
                  _buildSectionHeader("Claimant's Proof"),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha:0.3)),
                    ),
                    child: Text(widget.itemData['claim_proof'], style: const TextStyle(fontStyle: FontStyle.italic)),
                  ),
                  const SizedBox(height: 24),
                ],

                // 4. DANGER ZONE (Task 3: User Management)
                const Divider(height: 40),
                _buildSectionHeader("Danger Zone"),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha:.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha:0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Suspicious User?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 8),
                      const Text("If this user is posting fake items, you can ban their account from the system.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _manageUserAccount('ban'),
                          icon: const Icon(Icons.block, size: 18),
                          label: const Text("BAN THIS USER"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Padding for buttons
              ],
            ),
          ),

          // 5. FIXED BOTTOM ACTIONS
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus("REJECTED"),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text("REJECT ITEM"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus("PUBLISHED"),
                      style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text("APPROVE POST", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isProcessing)
            Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value ?? "N/A", style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}