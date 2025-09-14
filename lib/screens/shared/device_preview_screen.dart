import 'package:flutter/material.dart';

class DevicePreviewScreen extends StatefulWidget {
  final Widget child;
  
  const DevicePreviewScreen({
    super.key,
    required this.child,
  });

  @override
  State<DevicePreviewScreen> createState() => _DevicePreviewScreenState();
}

class _DevicePreviewScreenState extends State<DevicePreviewScreen> {
  String _selectedDevice = 'iPhone 14 Pro';
  double _scale = 1.0;
  bool _isPreviewMode = true;

  final Map<String, Map<String, double>> _devices = {
    'iPhone 14 Pro': {'width': 393, 'height': 852},
    'iPhone 14 Pro Max': {'width': 430, 'height': 932},
    'iPhone SE': {'width': 375, 'height': 667},
    'Samsung Galaxy S23': {'width': 360, 'height': 780},
    'Samsung Galaxy S23 Ultra': {'width': 412, 'height': 915},
    'iPad': {'width': 768, 'height': 1024},
    'iPad Pro': {'width': 1024, 'height': 1366},
    'Desktop': {'width': 1200, 'height': 800},
    'Desktop Large': {'width': 1920, 'height': 1080},
  };

  @override
  Widget build(BuildContext context) {
    if (!_isPreviewMode) {
      return widget.child;
    }

    final device = _devices[_selectedDevice]!;
    final deviceWidth = device['width']!;
    final deviceHeight = device['height']!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // Device Preview Panel
          Container(
            width: 300,
            color: Colors.grey[200],
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[600],
                  child: Row(
                    children: [
                      const Icon(Icons.phone_android, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'Device Preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isPreviewMode = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                // Device Selection
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Device:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: _selectedDevice,
                        isExpanded: true,
                        items: _devices.keys.map((String device) {
                          return DropdownMenuItem<String>(
                            value: device,
                            child: Text(device),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedDevice = newValue;
                            });
                          }
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Scale Control
                      const Text(
                        'Scale:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _scale,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        label: '${(_scale * 100).round()}%',
                        onChanged: (double value) {
                          setState(() {
                            _scale = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Device Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device: $_selectedDevice',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Size: ${deviceWidth.toInt()} × ${deviceHeight.toInt()}'),
                            Text('Scale: ${(_scale * 100).round()}%'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Preview Area
          Expanded(
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Transform.scale(
                    scale: _scale,
                    child: SizedBox(
                      width: deviceWidth,
                      height: deviceHeight,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
