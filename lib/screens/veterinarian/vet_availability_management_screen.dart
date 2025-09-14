import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';

class VetAvailabilityManagementScreen extends StatefulWidget {
  const VetAvailabilityManagementScreen({super.key});

  @override
  State<VetAvailabilityManagementScreen> createState() => _VetAvailabilityManagementScreenState();
}

class _VetAvailabilityManagementScreenState extends State<VetAvailabilityManagementScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  int _slotDuration = 30; // minutes
  bool _isLoading = false;
  
  List<AvailabilitySlot> _availabilitySlots = [];
  List<AvailabilitySlot> _selectedDaySlots = [];

  @override
  void initState() {
    super.initState();
    _loadAvailabilitySlots();
  }

  Future<void> _loadAvailabilitySlots() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser == null) return;

      // Load availability slots for the selected date
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // This would typically come from a service
      // For now, we'll generate some sample slots
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability Management'),
        actions: [
          IconButton(
            onPressed: _saveAvailability,
            icon: const Icon(Icons.save),
            tooltip: 'Save Availability',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Date',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _selectDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Time Settings
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Working Hours',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _selectStartTime,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Start Time',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.access_time),
                                    ),
                                    child: Text(_startTime.format(context)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: _selectEndTime,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'End Time',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.access_time),
                                    ),
                                    child: Text(_endTime.format(context)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text('Slot Duration: '),
                              DropdownButton<int>(
                                value: _slotDuration,
                                items: const [
                                  DropdownMenuItem(value: 15, child: Text('15 minutes')),
                                  DropdownMenuItem(value: 30, child: Text('30 minutes')),
                                  DropdownMenuItem(value: 45, child: Text('45 minutes')),
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
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Availability Slots
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Availability Slots',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              TextButton.icon(
                                onPressed: _generateSampleSlots,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Regenerate'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_selectedDaySlots.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text('No slots available for selected date'),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _selectedDaySlots.length,
                              itemBuilder: (context, index) {
                                final slot = _selectedDaySlots[index];
                                return _buildSlotCard(slot, index);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quick Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _markAllAvailable,
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Mark All Available'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _markAllUnavailable,
                                  icon: const Icon(Icons.cancel),
                                  label: const Text('Mark All Unavailable'),
                                ),
                              ),
                            ],
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

  Widget _buildSlotCard(AvailabilitySlot slot, int index) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    if (slot.isBooked) {
      backgroundColor = Colors.red.shade100;
      textColor = Colors.red.shade700;
      icon = Icons.event_busy;
    } else if (slot.isAvailable) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
      icon = Icons.event_available;
    } else {
      backgroundColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
      icon = Icons.event_busy;
    }
    
    return GestureDetector(
      onTap: () => _toggleSlotAvailability(index),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: textColor.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(slot.startTime),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              DateFormat('HH:mm').format(slot.endTime),
              style: TextStyle(
                color: textColor,
                fontSize: 10,
              ),
            ),
          ],
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
  }

  void _markAllAvailable() {
    setState(() {
      for (final slot in _selectedDaySlots) {
        if (!slot.isBooked) {
          slot.isAvailable = true;
        }
      }
    });
  }

  void _markAllUnavailable() {
    setState(() {
      for (final slot in _selectedDaySlots) {
        if (!slot.isBooked) {
          slot.isAvailable = false;
        }
      }
    });
  }

  Future<void> _saveAvailability() async {
    try {
      // Here you would save the availability slots to your backend
      // For now, we'll just show a success message
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Availability saved for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving availability: $e'),
          backgroundColor: Colors.red,
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