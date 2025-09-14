import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';

// Color constants
class AppColors {
  static const Color primaryBeige = Color.fromARGB(255, 255, 255, 255);
  static const Color primaryBrown = Color(0xFF7D4D20);
  static const Color lightBrown = Color(0xFF9B6B3A);
  static const Color darkBrown = Color(0xFF5A3417);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color softGreen = Color(0xFF8FBC8F);
  static const Color warmRed = Color(0xFFCD853F);
  static const Color warmPurple = Color(0xFFBC9A6A);
  static const Color cardWhite = Color(0xFFFFFDF7);
  static const Color shadowColor = Color(0x1A7D4D20);
}

class VetAvailabilityManagementScreen extends StatefulWidget {
  const VetAvailabilityManagementScreen({super.key});

  @override
  State<VetAvailabilityManagementScreen> createState() => _VetAvailabilityManagementScreenState();
}

class _VetAvailabilityManagementScreenState extends State<VetAvailabilityManagementScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  int _slotDuration = 30;
  bool _isLoading = false;
  
  List<AvailabilitySlot> _availabilitySlots = [];
  List<AvailabilitySlot> _selectedDaySlots = [];

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAvailabilitySlots();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailabilitySlots() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser == null) return;

      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      _generateSampleSlots();
      
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading availability slots: $e');
      setState(() => _isLoading = false);
    }
  }

  void _generateSampleSlots() {
    _selectedDaySlots = [];
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    
    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );
    
    DateTime currentSlot = startDateTime;
    while (currentSlot.isBefore(endDateTime)) {
      final slotEnd = currentSlot.add(Duration(minutes: _slotDuration));
      if (slotEnd.isBefore(endDateTime) || slotEnd.isAtSameMomentAs(endDateTime)) {
        _selectedDaySlots.add(AvailabilitySlot(
          id: '${currentSlot.millisecondsSinceEpoch}',
          veterinarianId: 'current_user',
          date: _selectedDate,
          startTime: currentSlot,
          endTime: slotEnd,
          isAvailable: true,
          isBooked: false,
        ));
      }
      currentSlot = slotEnd;
    }

    // Trigger slot animation
    _scaleController.reset();
    _scaleController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBeige,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingWidget()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateSelectionCard(),
                      const SizedBox(height: 20),
                      _buildTimeSettingsCard(),
                      const SizedBox(height: 20),
                      _buildAvailabilitySlotsCard(),
                      const SizedBox(height: 20),
                      _buildQuickActionsCard(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primaryBrown,
      foregroundColor: AppColors.primaryBeige,
      title: const Text(
        'Availability Management',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      actions: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: IconButton(
            onPressed: _saveAvailability,
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save Availability',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.accentGold.withOpacity(0.2),
              foregroundColor: AppColors.primaryBeige,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBrown),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading availability...',
            style: TextStyle(
              color: AppColors.lightBrown,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDateSelectionCard() {
    return _buildModernCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.primaryBrown,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightBrown.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.primaryBeige.withOpacity(0.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: AppColors.primaryBrown,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.lightBrown,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSettingsCard() {
    return _buildModernCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.softGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.access_time_outlined,
                    color: AppColors.softGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Working Hours',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildTimeSelector('Start Time', _startTime, _selectStartTime)),
                const SizedBox(width: 16),
                Expanded(child: _buildTimeSelector('End Time', _endTime, _selectEndTime)),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: AppColors.accentGold,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Slot Duration: ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _slotDuration,
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15 min')),
                          DropdownMenuItem(value: 30, child: Text('30 min')),
                          DropdownMenuItem(value: 45, child: Text('45 min')),
                          DropdownMenuItem(value: 60, child: Text('1 hour')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _slotDuration = value;
                              _generateSampleSlots();
                            });
                          }
                        },
                        style: TextStyle(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildTimeSelector(String label, TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lightBrown.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
          color: AppColors.primaryBeige.withOpacity(0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.lightBrown,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time.format(context),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySlotsCard() {
    return _buildModernCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warmPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.view_timeline_outlined,
                          color: AppColors.warmPurple,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          'Availability Slots',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: TextButton.icon(
                    onPressed: _generateSampleSlots,
                    icon: Icon(Icons.refresh, color: AppColors.primaryBrown, size: 18),
                    label: Text(
                      'Regenerate',
                      style: TextStyle(
                        color: AppColors.primaryBrown,
                        fontSize: 14,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primaryBrown.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_selectedDaySlots.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy_outlined,
                        color: AppColors.lightBrown,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No slots available for selected date',
                        style: TextStyle(
                          color: AppColors.lightBrown,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ScaleTransition(
                scale: _scaleAnimation,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _selectedDaySlots.length,
                  itemBuilder: (context, index) {
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 200 + (index * 50)),
                      curve: Curves.easeOutBack,
                      child: _buildSlotCard(_selectedDaySlots[index], index),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotCard(AvailabilitySlot slot, int index) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    IconData icon;
    
    if (slot.isBooked) {
      backgroundColor = AppColors.warmRed.withOpacity(0.1);
      textColor = AppColors.warmRed;
      borderColor = AppColors.warmRed.withOpacity(0.3);
      icon = Icons.event_busy;
    } else if (slot.isAvailable) {
      backgroundColor = AppColors.softGreen.withOpacity(0.1);
      textColor = AppColors.softGreen;
      borderColor = AppColors.softGreen.withOpacity(0.3);
      icon = Icons.event_available;
    } else {
      backgroundColor = AppColors.lightBrown.withOpacity(0.1);
      textColor = AppColors.lightBrown;
      borderColor = AppColors.lightBrown.withOpacity(0.3);
      icon = Icons.event_busy;
    }
    
    return GestureDetector(
      onTap: () => _toggleSlotAvailability(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                icon,
                key: ValueKey(icon),
                color: textColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('HH:mm').format(slot.startTime),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              DateFormat('HH:mm').format(slot.endTime),
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return _buildModernCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.flash_on_outlined,
                    color: AppColors.accentGold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    onPressed: _markAllAvailable,
                    icon: Icons.check_circle_outline,
                    label: 'Mark All Available',
                    color: AppColors.softGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    onPressed: _markAllUnavailable,
                    icon: Icons.cancel_outlined,
                    label: 'Mark All Unavailable',
                    color: AppColors.warmRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBrown,
              onPrimary: AppColors.primaryBeige,
              surface: AppColors.cardWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _generateSampleSlots();
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBrown,
              onPrimary: AppColors.primaryBeige,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (time != null) {
      setState(() {
        _startTime = time;
        _generateSampleSlots();
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBrown,
              onPrimary: AppColors.primaryBeige,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (time != null) {
      setState(() {
        _endTime = time;
        _generateSampleSlots();
      });
    }
  }

  void _toggleSlotAvailability(int index) {
    setState(() {
      final slot = _selectedDaySlots[index];
      if (!slot.isBooked) {
        slot.isAvailable = !slot.isAvailable;
      }
    });

    // Add haptic feedback
    HapticFeedback.selectionClick();
  }

  void _markAllAvailable() {
    setState(() {
      for (final slot in _selectedDaySlots) {
        if (!slot.isBooked) {
          slot.isAvailable = true;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All slots marked as available'),
        backgroundColor: AppColors.softGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _markAllUnavailable() {
    setState(() {
      for (final slot in _selectedDaySlots) {
        if (!slot.isBooked) {
          slot.isAvailable = false;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All slots marked as unavailable'),
        backgroundColor: AppColors.warmRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _saveAvailability() async {
    try {
      // Show loading state
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBeige),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Saving availability...'),
            ],
          ),
          backgroundColor: AppColors.primaryBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.primaryBeige),
              const SizedBox(width: 12),
              Text('Availability saved for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}'),
            ],
          ),
          backgroundColor: AppColors.softGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: AppColors.primaryBeige),
              const SizedBox(width: 12),
              Text('Error saving availability: $e'),
            ],
          ),
          backgroundColor: AppColors.warmRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

class AvailabilitySlot {
  final String id;
  final String veterinarianId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  bool isAvailable;
  bool isBooked;

  AvailabilitySlot({
    required this.id,
    required this.veterinarianId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.isBooked,
  });
}