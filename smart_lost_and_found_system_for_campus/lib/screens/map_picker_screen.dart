import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _pickedLocation;
  final MapController _mapController = MapController();

  // --- 1. DEFINE NAMES AS CONSTANTS TO PREVENT MISMATCH ERRORS ---
  static const String fallbackName = "University of Gujrat";

  final List<Map<String, dynamic>> _buildings = [
    {"name": "7-Block Circle", "lat": 32.6421, "lng": 74.1593},
    {"name": "Al-Farabi Block", "lat": 32.6435, "lng": 74.1590},
    {"name": "Arfa Karim Block", "lat": 32.6438, "lng": 74.1605},
    {"name": "Al-Khwarizmi Block", "lat": 32.6425, "lng": 74.1615},
    {"name": "Omar-Al-Khayyam Block", "lat": 32.6410, "lng": 74.1612},
    {"name": "Jabir Bin Hayan Block", "lat": 32.6402, "lng": 74.1598},
    {"name": "Al-Jazari Block", "lat": 32.6408, "lng": 74.1582},
    {"name": "Medical Block", "lat": 32.6430, "lng": 74.1580},
    {"name": "Quaid-e-Azam Library", "lat": 32.6385, "lng": 74.1615},
    {"name": "Engineering Block", "lat": 32.6415, "lng": 74.1555},
    {"name": "SADA Department", "lat": 32.6420, "lng": 74.1635},
    {"name": "New Block 1", "lat": 32.6375, "lng": 74.1585},
    {"name": "New Block 2", "lat": 32.6375, "lng": 74.1595},
    {"name": "VC Secretariat", "lat": 32.6388, "lng": 74.1630},
    {"name": "Admin Block", "lat": 32.6355, "lng": 74.1602},
    {"name": "SSC Block", "lat": 32.6345, "lng": 74.1598},
    {"name": "UOG Mart", "lat": 32.6372, "lng": 74.1552},
    {"name": "Bank of Punjab", "lat": 32.6335, "lng": 74.1565},
    {"name": "Cafeteria", "lat": 32.6408, "lng": 74.1578},
    {"name": "UOG Mosque", "lat": 32.6360, "lng": 74.1560},
    {"name": "Hafiz Hayat Shrine", "lat": 32.6378, "lng": 74.1542},
    {"name": "Allama Iqbal Hall", "lat": 32.6338, "lng": 74.1605},
    {"name": "Boys Hostel", "lat": 32.6325, "lng": 74.1602},
    {"name": "NSMC Girls Hostel", "lat": 32.6445, "lng": 74.1645},
    {"name": fallbackName, "lat": 0.0, "lng": 0.0}, // The fallback
  ];

  String? _selectedBuilding;
  final TextEditingController _floorController = TextEditingController();

  // --- 2. THE REFINED AUTO-DETECT LOGIC ---
  void _autoDetectBuilding(LatLng point) {
    double minDistance = double.infinity;
    String closestBuilding = fallbackName; // Start with default

    double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
      const p = 0.017453292519943295;
      final a = 0.5 - math.cos((lat2 - lat1) * p)/2 +
          math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p))/2;
      return 12742 * math.asin(math.sqrt(a)) * 1000;
    }

    for (var b in _buildings) {
      if (b['lat'] == 0.0) continue;
      double dist = calculateDistance(point.latitude, point.longitude, b['lat'], b['lng']);

      if (dist < 150 && dist < minDistance) {
        minDistance = dist;
        closestBuilding = b['name'];
      }
    }

    setState(() {
      _pickedLocation = point;
      _selectedBuilding = closestBuilding;
    });
  }
  // --- 3. THE REFINED DIALOG (Safe Dropdown) ---
  Future<void> _showRefineDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1E293B),
                title: const Text("Confirm Location", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF0F172A),
                      value: _selectedBuilding, // Matches one of the items exactly
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Building",
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      ),
                      // We build items from the same master list
                      items: _buildings.map((b) => DropdownMenuItem<String>(
                          value: b['name'],
                          child: Text(b['name'])
                      )).toList(),
                      onChanged: (val) => setStateDialog(() => _selectedBuilding = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _floorController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Specifics (e.g. 2nd Floor)",
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Confirm"),
                  ),
                ],
              );
            }
        );
      },
    ).then((confirmed) {
      if (confirmed == true && _pickedLocation != null) {
        String finalLoc = _selectedBuilding ?? fallbackName;
        if (_floorController.text.isNotEmpty) finalLoc += " (${_floorController.text})";
        Navigator.pop(context, {'text': finalLoc});
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. THE MAP (OpenStreetMap - Crash-Proof)
          // 1. THE MAP LAYER
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(32.6421, 74.1593),
              initialZoom: 16.5,
              onTap: (tapPos, point) => _autoDetectBuilding(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                // --- ADD THIS LINE TO REMOVE THE 403 BLOCKED ERROR ---
                userAgentPackageName: 'com.example.smart_lost_and_found',
                // ----------------------------------------------------
              ),
              if (_pickedLocation != null)
                MarkerLayer(markers: [
                  Marker(point: _pickedLocation!, child: const Icon(Icons.location_pin, color: Colors.red, size: 45)),
                ]),
            ],
          ),

          // 2. BACK BUTTON (Positioned to avoid gesture conflict)
          Positioned(
            top: 50, left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
            ),
          ),

          // 3. CONFIRM BUTTON
          if (_pickedLocation != null)
            Positioned(
              bottom: 30, left: 20, right: 20,
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _showRefineDialog,
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text("NEXT: REFINE DETAILS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
            ),
        ],
      ),
    );
  }
}