import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/analytics_service.dart';
import '../../services/store_service.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  Map<String, dynamic> _analyticsData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      final data = await analyticsService.getAnalyticsData();
      
      debugPrint('Analytics Dashboard: Received data: $data');
      
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading analytics: ${e.toString()}', isError: true);
    }
  }

  Future<void> _generateSampleData() async {
    try {
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      await analyticsService.generateSampleData();
      _showSnackBar('Sample data generated successfully!', isError: false);
      await _loadAnalyticsData(); // Refresh the data
    } catch (e) {
      _showSnackBar('Error generating sample data: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
          IconButton(
            icon: const Icon(Icons.data_usage),
            onPressed: _generateSampleData,
            tooltip: 'Generate Sample Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalyticsData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    _buildMostViewedItems(),
                    const SizedBox(height: 24),
                    _buildMostClickedItems(),
                    const SizedBox(height: 24),
                    _buildCategoryPopularity(),
                    const SizedBox(height: 24),
                    _buildUserActivity(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    final totalViews = _analyticsData['mostViewed']?.fold<int>(0, (int sum, dynamic item) => sum + ((item['viewCount'] as int?) ?? 0)) ?? 0;
    final totalClicks = _analyticsData['mostClicked']?.fold<int>(0, (int sum, dynamic item) => sum + ((item['clickCount'] as int?) ?? 0)) ?? 0;
    final activeUsers = _analyticsData['totalActiveUsers'] ?? 0;
    final categories = _analyticsData['categoryPopularity']?.length ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            'Total Views',
            totalViews.toString(),
            Icons.visibility,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Total Clicks',
            totalClicks.toString(),
            Icons.mouse,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMostViewedItems() {
    final items = _analyticsData['mostViewed'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Most Viewed Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Text('No data available')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(item['itemName'] ?? 'Unknown Item'),
                    subtitle: Text('Category: ${item['category']}'),
                    trailing: Text(
                      '${item['viewCount']} views',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMostClickedItems() {
    final items = _analyticsData['mostClicked'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Most Clicked Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Text('No data available')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(item['itemName'] ?? 'Unknown Item'),
                    subtitle: Text('Category: ${item['category']}'),
                    trailing: Text(
                      '${item['clickCount']} clicks',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPopularity() {
    final categories = _analyticsData['categoryPopularity'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Popularity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (categories.isEmpty)
              const Text('No data available')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final viewCount = category['viewCount'] as int? ?? 0;
                  final totalViews = categories.fold<int>(0, (int sum, dynamic cat) => sum + ((cat['viewCount'] as int?) ?? 0));
                  final percentage = totalViews > 0 ? (viewCount / totalViews * 100) : 0.0;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            category['category'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getCategoryColor(category['category']),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserActivity() {
    final activeUsers = _analyticsData['totalActiveUsers'] ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.people, color: Colors.purple, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Users',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      activeUsers.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Users who have interacted with store items (viewed, clicked, or favorited)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'grooming':
        return Colors.blue;
      case 'toys':
        return Colors.purple;
      case 'health':
        return Colors.red;
      case 'accessories':
        return Colors.green;
      case 'other':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
