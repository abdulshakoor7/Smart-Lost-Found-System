import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../user_session.dart';
import 'chat_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;

  const ItemDetailScreen({super.key, required this.itemData});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final Color _bg = const Color(0xFF121212);
  final Color _cardColor = const Color(0xFF1E1E1E);
  final Color _primaryBlue = const Color(0xFF2563EB);

  int _currentImageIndex = 0;

  Map<String, dynamic>? _liveItemData;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    // Logic: If passed data is just an ID (from Notification), fetch full details
    if (widget.itemData.containsKey('id') && widget.itemData.length <= 2) {
      _fetchFullItemDetails();
    } else {
      _liveItemData = widget.itemData;
    }
  }

  // --- LOGIC: Fetch full item details from server ---
  Future<void> _fetchFullItemDetails() async {
    if (!mounted) return;
    setState(() => _isFetching = true);

    String id = widget.itemData['id'].toString().trim();
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/items/$id/"),
        headers: ApiService.headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _liveItemData = json.decode(response.body);
            _isFetching = false;
          });
        }
      } else {
        if (mounted) setState(() => _isFetching = false);
      }
    } catch (e) {
      debugPrint("❌ Detail Fetch Error: $e");
      if (mounted) setState(() => _isFetching = false);
    }
  }

  // --- LOGIC: Submit a claim for a FOUND item ---
  void submitClaim() async {
    // Show loading
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator())
    );

    try {
      // Logic: Standardize the ID and ensure trailing slash
      final itemId = _liveItemData!['id'];

      // ✅ GENIUS FIX: Use ApiService.apiUrl and ensure the final '/' is present
      final url = "${ApiService.apiUrl}/items/$itemId/claim_item/";

      debugPrint("🚀 VIVA-TEST: Calling Claim URL: $url");

      final response = await http.post(
        Uri.parse(url),
        headers: ApiService.headers, // This includes Ngrok bypass
        body: jsonEncode({
          "claimant_email": UserSession.email,
          "proof": "Claimed during system demonstration."
        }),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close spinner

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Success: Claim sent to Admin!")),
        );
      } else {
        debugPrint("❌ Server Error ${response.statusCode}: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to claim: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Connection error. Check your Ngrok link.")),
      );
    }
  }

  // --- LOGIC: Notify owner that someone found their LOST item ---
  void notifyOwnerFound() async {
    // Check if session email is valid
    if (UserSession.email == null || UserSession.email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error: You must be logged in.")),
      );
      return;
    }

    // Show a loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Processing..."), duration: Duration(seconds: 1)),
    );

    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/items/${_liveItemData!['id']}/found_it/"),
        headers: ApiService.headers,
        body: jsonEncode({
          "finder_email": UserSession.email, // Ensure this is not null
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Success: Owner has been notified!")),
        );
      } else {
        // Logic: Extract error message from backend if available
        String errorMsg = "Failed to notify owner.";
        try {
          var data = jsonDecode(response.body);
          errorMsg = data['error'] ?? errorMsg;
        } catch(_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error ${response.statusCode}: $errorMsg")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Connection Error. check Ngrok/Internet.")),
      );
    }
  }

  String _formatUrl(String url) {
    if (url.isEmpty) return "";
    if (url.startsWith('http')) return url;
    return ApiService.getFullImageUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching || _liveItemData == null) {
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    // Robust identity check (handling multiple possible JSON keys from Django)
    bool isMine = (_liveItemData!['reported_by_email']?.toString().toLowerCase() == UserSession.email?.toLowerCase()) ||
        (_liveItemData!['user_email']?.toString().toLowerCase() == UserSession.email?.toLowerCase());

    bool isFoundItem = _liveItemData!['item_type'] == 'FOUND';

    List<String> imageList = [];
    String mainImage = _formatUrl(_liveItemData!['image'] ?? "");
    if (mainImage.isNotEmpty) imageList.add(mainImage);

    if (_liveItemData!['gallery'] != null) {
      for (var gal in _liveItemData!['gallery']) {
        String galImg = _formatUrl(gal['image'] ?? "");
        if (galImg.isNotEmpty) imageList.add(galImg);
      }
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: Colors.white,
            onPressed: () => Navigator.pop(context)),
        title: Text(isMine ? "My Report Details" : "Item Details",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: imageList.isEmpty
                        ? Container(
                        decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(20)),
                        child: const Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey)))
                        : PageView.builder(
                      itemCount: imageList.length,
                      onPageChanged: (index) => setState(() => _currentImageIndex = index),
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(image: NetworkImage(imageList[index]), fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                  ),
                  if (imageList.length > 1) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(imageList.length, (index) => _buildDot(index == _currentImageIndex)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(_liveItemData!['title'] ?? "No Title",
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTag(isFoundItem ? "Found" : "Lost", isFoundItem ? Colors.blue : Colors.red),
                      const SizedBox(width: 8),
                      _buildTag(_liveItemData!['category'] ?? "General", Colors.grey.shade800),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection("Description", _liveItemData!['description']),
                  _buildSection("Location", _liveItemData!['location']),

                  // ✅ ADDED: PRIVACY GUARD LOGIC
                  _buildPrivacySection(),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _bg, border: Border(top: BorderSide(color: Colors.grey[900]!))),
            child: _buildActionButtons(context, isFoundItem, isMine),
          )
        ],
      ),
    );
  }

  // ✅ NEW WIDGET: Logic to show/hide phone number based on owner preference
  Widget _buildPrivacySection() {
    // We check the 'owner_show_phone' key returned from the Django Serializer
    bool canShowPhone = _liveItemData!['owner_show_phone'] ?? false;
    String ownerPhone = _liveItemData!['owner_phone'] ?? "Not available";

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Contact Information",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Icon(
                  canShowPhone ? Icons.phone_enabled_rounded : Icons.phonelink_lock_rounded,
                  color: canShowPhone ? Colors.green : _primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    canShowPhone ? "Call Owner: $ownerPhone" : "Contact via Secure Chat Only",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String? content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content ?? "No details provided.", style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  // --- LOGIC: UI BUTTONS ---
  Widget _buildActionButtons(BuildContext context, bool isFoundItem, bool isMine) {
    // SCENARIO 1: IT IS MY OWN REPORT
    if (isMine) {
      return Row(
        children: [
          Expanded(child: _buildChatButton(context)), // Owners can see messages sent to them
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                bool success = await ApiService.deleteItem(_liveItemData!['id']);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report Deleted")));
                  Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text("Delete"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    // SCENARIO 2: SOMEONE ELSE LOST THIS ITEM
    if (!isFoundItem) {
      return Row(
        children: [
          Expanded(child: _buildChatButton(context)),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: notifyOwnerFound,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("I Found This!"),
            ),
          ),
        ],
      );
    }

    // SCENARIO 3: SOMEONE ELSE FOUND THIS ITEM (I WANT TO CLAIM)
    return Row(
      children: [
        Expanded(child: _buildChatButton(context)),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: submitClaim,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Claim Item"),
          ),
        ),
      ],
    );
  }

  Widget _buildChatButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: "room_${_liveItemData!['id']}",
              title: "Chat",
              receiverEmail: _liveItemData!['reported_by_email'] ?? _liveItemData!['user_email'] ?? "",
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
          backgroundColor: _cardColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: const Text("Chat"),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha:0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha:0.5))),
        child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)));
  }

  Widget _buildDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(color: isActive ? Colors.white : Colors.grey[800], borderRadius: BorderRadius.circular(4)),
    );
  }
}