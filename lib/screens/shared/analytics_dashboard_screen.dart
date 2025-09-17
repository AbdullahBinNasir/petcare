import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/analytics_service.dart';
import '../../services/store_service.dart';
import '../../theme/pet_care_theme.dart';

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
      backgroundColor: Colors.transparent,
      appBar: _buildModernAppBar(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: PetCareTheme.backgroundGradient,
          ),
        ),
        child: _isLoading
            ? _buildLoadingState()
            : RefreshIndicator(
                onRefresh: _loadAnalyticsData,
                color: PetCareTheme.primaryBrown,
                backgroundColor: PetCareTheme.cardWhite,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildWelcomeSection(),
                      const SizedBox(height: 32),
                      _buildOverviewHeader(),
                      const SizedBox(height: 20),
                      _buildOverviewCards(),
                      const SizedBox(height: 36),
                      _buildMostViewedItems(),
                      const SizedBox(height: 32),
                      _buildMostClickedItems(),
                      const SizedBox(height: 32),
                      _buildCategoryPopularity(),
                      const SizedBox(height: 32),
                      _buildUserActivity(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: PetCareTheme.primaryGradient,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: PetCareTheme.primaryBeige,
      title: Text(
        'Analytics Dashboard',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: PetCareTheme.primaryBeige,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: PetCareTheme.primaryBeige.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: PetCareTheme.primaryBeige.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: PetCareTheme.primaryBeige,
              size: 20,
            ),
            onPressed: _loadAnalyticsData,
            tooltip: 'Refresh Data',
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [PetCareTheme.accentGold, PetCareTheme.lightBrown],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: PetCareTheme.accentGold.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _generateSampleData,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.auto_fix_high_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: PetCareTheme.cardWhite.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(PetCareTheme.primaryBrown),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading Analytics...',
              style: TextStyle(
                color: PetCareTheme.primaryBrown,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: PetCareTheme.accentGradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: PetCareTheme.primaryBeige.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: PetCareTheme.primaryBeige.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.analytics_rounded,
                color: PetCareTheme.primaryBeige,
                size: 36,
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Store Performance',
                    style: TextStyle(
                      color: PetCareTheme.primaryBeige.withOpacity(0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Analytics Dashboard',
                    style: TextStyle(
                      color: PetCareTheme.primaryBeige,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PetCareTheme.primaryBeige.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Real-time Insights',
                      style: TextStyle(
                        color: PetCareTheme.primaryBeige,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewHeader() {
    return Text(
      'Performance Overview',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: PetCareTheme.primaryBrown,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildOverviewCards() {
    final totalViews = _analyticsData['mostViewed']?.fold<int>(0, (int sum, dynamic item) => sum + ((item['viewCount'] as int?) ?? 0)) ?? 0;
    final totalClicks = _analyticsData['mostClicked']?.fold<int>(0, (int sum, dynamic item) => sum + ((item['clickCount'] as int?) ?? 0)) ?? 0;
    final activeUsers = _analyticsData['totalActiveUsers'] ?? 0;
    final categories = _analyticsData['categoryPopularity']?.length ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final spacing = 16.0;
        
        return Column(
          children: [
            // First Row
            Row(
              children: [
                Expanded(
                  child: _buildResponsiveStatCard(
                    'Total Views',
                    totalViews.toString(),
                    Icons.visibility_rounded,
                    PetCareTheme.accentGold,
                    screenWidth,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _buildResponsiveStatCard(
                    'Total Clicks',
                    totalClicks.toString(),
                    Icons.touch_app_rounded,
                    PetCareTheme.softGreen,
                    screenWidth,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            // Second Row
            Row(
              children: [
                Expanded(
                  child: _buildResponsiveStatCard(
                    'Active Users',
                    activeUsers.toString(),
                    Icons.people_rounded,
                    PetCareTheme.warmPurple,
                    screenWidth,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _buildResponsiveStatCard(
                    'Categories',
                    categories.toString(),
                    Icons.category_rounded,
                    PetCareTheme.warmRed,
                    screenWidth,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildResponsiveStatCard(String title, String value, IconData icon, Color color, double screenWidth) {
    // Calculate responsive dimensions
    final isSmallScreen = screenWidth < 400;
    
    return Container(
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.05),
              color.withOpacity(0.02),
              Colors.white.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12.0 : 16.0,
            vertical: isSmallScreen ? 16.0 : 20.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Section
              Container(
                width: isSmallScreen ? 48.0 : 56.0,
                height: isSmallScreen ? 48.0 : 56.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isSmallScreen ? 24.0 : 28.0,
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 12.0 : 16.0),
              
              // Value Section
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24.0 : 28.0,
                      fontWeight: FontWeight.w900,
                      color: PetCareTheme.primaryBrown,
                      letterSpacing: -0.5,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 4.0 : 6.0),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11.0 : 12.0,
                      fontWeight: FontWeight.w600,
                      color: PetCareTheme.lightBrown.withOpacity(0.9),
                      letterSpacing: 0.2,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMostViewedItems() {
    final items = _analyticsData['mostViewed'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Most Viewed Items',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: PetCareTheme.primaryBrown,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: PetCareTheme.cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [PetCareTheme.cardShadow],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: items.isEmpty
                ? _buildEmptyAnalyticsState(
                    'No View Data',
                    'No items have been viewed yet',
                    Icons.visibility_off_rounded,
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildAnalyticsListItem(
                        index + 1,
                        item['itemName'] ?? 'Unknown Item',
                        'Category: ${item['category']}',
                        '${item['viewCount']} views',
                        PetCareTheme.accentGold,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMostClickedItems() {
    final items = _analyticsData['mostClicked'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Most Clicked Items',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: PetCareTheme.primaryBrown,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: PetCareTheme.cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [PetCareTheme.cardShadow],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: items.isEmpty
                ? _buildEmptyAnalyticsState(
                    'No Click Data',
                    'No items have been clicked yet',
                    Icons.touch_app_rounded,
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildAnalyticsListItem(
                        index + 1,
                        item['itemName'] ?? 'Unknown Item',
                        'Category: ${item['category']}',
                        '${item['clickCount']} clicks',
                        PetCareTheme.softGreen,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAnalyticsState(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PetCareTheme.primaryBrown.withOpacity(0.1),
                  PetCareTheme.lightBrown.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: PetCareTheme.primaryBrown.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: PetCareTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: PetCareTheme.textLight,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsListItem(
    int rank,
    String title,
    String subtitle,
    String trailing,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.4),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: PetCareTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: PetCareTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              trailing,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPopularity() {
    final categories = _analyticsData['categoryPopularity'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Popularity',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: PetCareTheme.primaryBrown,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: PetCareTheme.cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [PetCareTheme.cardShadow],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: categories.isEmpty
                ? _buildEmptyAnalyticsState(
                    'No Category Data',
                    'No category analytics available',
                    Icons.category_rounded,
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final viewCount = category['viewCount'] as int? ?? 0;
                      final totalViews = categories.fold<int>(0, (int sum, dynamic cat) => sum + ((cat['viewCount'] as int?) ?? 0));
                      final percentage = totalViews > 0 ? (viewCount / totalViews * 100) : 0.0;
                      final color = _getCategoryColor(category['category']);
                      
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: color.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    category['category'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: PetCareTheme.textDark,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: PetCareTheme.lightBrown.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: percentage / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        color.withOpacity(0.6),
                                        color,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$viewCount views',
                              style: TextStyle(
                                fontSize: 14,
                                color: PetCareTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserActivity() {
    final activeUsers = _analyticsData['totalActiveUsers'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Activity',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: PetCareTheme.primaryBrown,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: PetCareTheme.cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [PetCareTheme.cardShadow],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        PetCareTheme.warmPurple.withOpacity(0.2),
                        PetCareTheme.warmPurple.withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: PetCareTheme.warmPurple.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.people_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Users',
                        style: TextStyle(
                          fontSize: 16,
                          color: PetCareTheme.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeUsers.toString(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: PetCareTheme.primaryBrown,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: PetCareTheme.warmPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Interacted with store',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: PetCareTheme.warmPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return PetCareTheme.warmRed;
      case 'grooming':
        return PetCareTheme.accentGold;
      case 'toys':
        return PetCareTheme.warmPurple;
      case 'health':
        return PetCareTheme.softGreen;
      case 'accessories':
        return PetCareTheme.primaryBrown;
      case 'other':
        return PetCareTheme.lightBrown;
      default:
        return PetCareTheme.lightBrown;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? PetCareTheme.warmRed : PetCareTheme.softGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
