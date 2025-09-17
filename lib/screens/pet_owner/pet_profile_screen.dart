import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/pet_service.dart';
import '../../services/appointment_service.dart';
import '../../services/health_record_service.dart';
import '../../models/pet_model.dart';
import '../../models/appointment_model.dart';
import '../../models/health_record_model.dart';
import '../../theme/pet_care_theme.dart';
import '../../widgets/universal_image_widget.dart';
import 'edit_pet_screen.dart';
import 'health_records_screen.dart';
import 'add_health_record_screen.dart';

class PetProfileScreen extends StatefulWidget {
  final PetModel pet;

  const PetProfileScreen({super.key, required this.pet});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppointmentModel> _appointments = [];
  List<HealthRecordModel> _healthRecords = [];
  List<HealthRecordModel> _dueRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);

    final appointmentService = Provider.of<AppointmentService>(context, listen: false);
    final healthService = Provider.of<HealthRecordService>(context, listen: false);
    
    final appointments = await appointmentService.getAppointmentsByPet(widget.pet.id);
    final healthRecords = await healthService.getHealthRecordsByPetId(widget.pet.id);
    final dueRecords = await healthService.getDueHealthRecords(widget.pet.id);

    setState(() {
      _appointments = appointments;
      _healthRecords = healthRecords;
      _dueRecords = dueRecords;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: PetCareTheme.backgroundGradient,
          ),
        ),
        child: Column(
          children: [
            _buildModernAppBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(),
                  _buildHealthTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: PetCareTheme.primaryGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: PetCareTheme.primaryBeige,
                  size: 24,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pet.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: PetCareTheme.primaryBeige,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSpeciesName(widget.pet.species),
                      style: TextStyle(
                        fontSize: 16,
                        color: PetCareTheme.primaryBeige.withOpacity( 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: PetCareTheme.primaryBeige.withOpacity( 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPetScreen(pet: widget.pet),
                          ),
                        ).then((_) {
                          Navigator.pop(context);
                        });
                      },
                      icon: Icon(
                        Icons.edit_rounded,
                        color: PetCareTheme.primaryBeige,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: PetCareTheme.primaryBeige.withOpacity( 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: PetCareTheme.primaryBeige,
                        size: 24,
                      ),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteDialog();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded, color: PetCareTheme.warmRed),
                              const SizedBox(width: 8),
                              Text('Delete Pet', style: TextStyle(color: PetCareTheme.warmRed)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [PetCareTheme.elevatedShadow],
        border: Border.all(
          color: PetCareTheme.primaryBrown.withOpacity( 0.1),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(colors: PetCareTheme.accentGradient),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: PetCareTheme.textLight,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(
            text: 'Profile',
            icon: Icon(Icons.pets_rounded, size: 20),
          ),
          Tab(
            text: 'Health',
            icon: Icon(Icons.health_and_safety_rounded, size: 20),
          ),
          Tab(
            text: 'History',
            icon: Icon(Icons.history_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo Gallery
          if (widget.pet.photoUrls.isNotEmpty) ...[
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [PetCareTheme.elevatedShadow],
              ),
              child: PageView.builder(
                itemCount: widget.pet.photoUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: PetCareTheme.shadowColor,
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: PetImageWidget(
                          imageUrl: widget.pet.photoUrls[index],
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: PetCareTheme.cardWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [PetCareTheme.elevatedShadow],
                border: Border.all(
                  color: PetCareTheme.primaryBrown.withOpacity( 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          PetCareTheme.primaryBrown.withOpacity( 0.1),
                          PetCareTheme.lightBrown.withOpacity( 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pets_rounded,
                      size: 40,
                      color: PetCareTheme.primaryBrown.withOpacity( 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No photos added',
                    style: TextStyle(
                      color: PetCareTheme.textLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Basic Information Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PetCareTheme.cardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [PetCareTheme.elevatedShadow],
              border: Border.all(
                color: PetCareTheme.primaryBrown.withOpacity( 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            PetCareTheme.primaryBrown.withOpacity( 0.1),
                            PetCareTheme.primaryBrown.withOpacity( 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.info_rounded,
                        color: PetCareTheme.primaryBrown,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: PetCareTheme.textDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoRow('Name', widget.pet.name, Icons.pets_rounded),
                _buildInfoRow('Species', _getSpeciesName(widget.pet.species), Icons.category_rounded),
                _buildInfoRow('Breed', widget.pet.breed, Icons.info_outline_rounded),
                _buildInfoRow('Gender', _getGenderName(widget.pet.gender), Icons.wc_rounded),
                if (widget.pet.dateOfBirth != null)
                  _buildInfoRow('Age', widget.pet.ageString, Icons.cake_rounded),
                if (widget.pet.weight != null)
                  _buildInfoRow('Weight', '${widget.pet.weight} kg', Icons.monitor_weight_rounded),
                if (widget.pet.color != null)
                  _buildInfoRow('Color', widget.pet.color!, Icons.palette_rounded),
                if (widget.pet.microchipId != null)
                  _buildInfoRow('Microchip ID', widget.pet.microchipId!, Icons.qr_code_rounded),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Health Status Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PetCareTheme.cardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [PetCareTheme.elevatedShadow],
              border: Border.all(
                color: _getHealthStatusColor(widget.pet.healthStatus).withOpacity( 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getHealthStatusColor(widget.pet.healthStatus).withOpacity( 0.1),
                            _getHealthStatusColor(widget.pet.healthStatus).withOpacity( 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.health_and_safety_rounded,
                        color: _getHealthStatusColor(widget.pet.healthStatus),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Health Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: PetCareTheme.textDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getHealthStatusColor(widget.pet.healthStatus).withOpacity( 0.1),
                            _getHealthStatusColor(widget.pet.healthStatus).withOpacity( 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.health_and_safety_rounded,
                        color: _getHealthStatusColor(widget.pet.healthStatus),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getHealthStatusName(widget.pet.healthStatus),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _getHealthStatusColor(widget.pet.healthStatus),
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (widget.pet.medicalNotes != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.pet.medicalNotes!,
                              style: TextStyle(
                                fontSize: 14,
                                color: PetCareTheme.textLight,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Status Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PetCareTheme.cardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [PetCareTheme.elevatedShadow],
              border: Border.all(
                color: _getHealthStatusColor(widget.pet.healthStatus).withOpacity( 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getHealthStatusColor(widget.pet.healthStatus).withOpacity( 0.1),
                            _getHealthStatusColor(widget.pet.healthStatus).withOpacity( 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.health_and_safety_rounded,
                        color: _getHealthStatusColor(widget.pet.healthStatus),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Health Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: PetCareTheme.textDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getHealthStatusColor(widget.pet.healthStatus).withOpacity( 0.1),
                        _getHealthStatusColor(widget.pet.healthStatus).withOpacity( 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getHealthStatusColor(widget.pet.healthStatus).withOpacity( 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getHealthStatusText(widget.pet.healthStatus),
                    style: TextStyle(
                      color: _getHealthStatusColor(widget.pet.healthStatus),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Due Records Alert
          if (_dueRecords.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: PetCareTheme.cardWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [PetCareTheme.elevatedShadow],
                border: Border.all(
                  color: PetCareTheme.accentGold.withOpacity( 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              PetCareTheme.accentGold.withOpacity( 0.1),
                              PetCareTheme.accentGold.withOpacity( 0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.warning_rounded,
                          color: PetCareTheme.accentGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Due Records (${_dueRecords.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PetCareTheme.textDark,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._dueRecords.take(3).map((record) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PetCareTheme.accentGold.withOpacity( 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: PetCareTheme.accentGold.withOpacity( 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: PetCareTheme.accentGold,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${record.title} - Due: ${_formatDate(record.nextDueDate!)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: PetCareTheme.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (_dueRecords.length > 3)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PetCareTheme.primaryBeige.withOpacity( 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'And ${_dueRecords.length - 3} more...',
                        style: TextStyle(
                          fontSize: 14,
                          color: PetCareTheme.textLight,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Medical Notes
          if (widget.pet.medicalNotes != null && widget.pet.medicalNotes!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: PetCareTheme.cardWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [PetCareTheme.elevatedShadow],
                border: Border.all(
                  color: PetCareTheme.softGreen.withOpacity( 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              PetCareTheme.softGreen.withOpacity( 0.1),
                              PetCareTheme.softGreen.withOpacity( 0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.note_alt_rounded,
                          color: PetCareTheme.softGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Medical Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PetCareTheme.textDark,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: PetCareTheme.softGreen.withOpacity( 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: PetCareTheme.softGreen.withOpacity( 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.pet.medicalNotes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: PetCareTheme.textDark,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Health Records Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PetCareTheme.cardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [PetCareTheme.elevatedShadow],
              border: Border.all(
                color: PetCareTheme.primaryBrown.withOpacity( 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            PetCareTheme.primaryBrown.withOpacity( 0.1),
                            PetCareTheme.primaryBrown.withOpacity( 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medical_services_rounded,
                        color: PetCareTheme.primaryBrown,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Health Records',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: PetCareTheme.textDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: PetCareTheme.accentGradient),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: PetCareTheme.shadowColor,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HealthRecordsScreen(petId: widget.pet.id),
                            ),
                          );
                          if (result == true) {
                            _loadAppointments();
                          }
                        },
                        icon: const Icon(Icons.visibility_rounded, size: 16),
                        label: const Text('View All'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                if (_healthRecords.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: PetCareTheme.primaryBeige.withOpacity( 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: PetCareTheme.primaryBrown.withOpacity( 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                PetCareTheme.primaryBrown.withOpacity( 0.1),
                                PetCareTheme.lightBrown.withOpacity( 0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.medical_services_outlined,
                            size: 40,
                            color: PetCareTheme.primaryBrown.withOpacity( 0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No health records yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: PetCareTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add health records to track your pet\'s health',
                          style: TextStyle(
                            fontSize: 14,
                            color: PetCareTheme.textLight,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: PetCareTheme.accentGradient),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: PetCareTheme.shadowColor,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddHealthRecordScreen(petId: widget.pet.id),
                                ),
                              );
                              if (result == true) {
                                _loadAppointments();
                              }
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add First Record'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      ..._healthRecords.take(3).map((record) => _buildHealthRecordTile(record)),
                      if (_healthRecords.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'And ${_healthRecords.length - 3} more records...',
                            style: TextStyle(
                              fontSize: 14,
                              color: PetCareTheme.textLight,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: PetCareTheme.accentGradient),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: PetCareTheme.shadowColor,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddHealthRecordScreen(petId: widget.pet.id),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadAppointments();
                                  }
                                },
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Add Record'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide.none,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HealthRecordsScreen(petId: widget.pet.id),
                                  ),
                                );
                                if (result == true) {
                                  _loadAppointments();
                                }
                              },
                              icon: const Icon(Icons.visibility_rounded, size: 16),
                              label: const Text('View All'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: PetCareTheme.primaryBrown,
                                side: BorderSide(
                                  color: PetCareTheme.primaryBrown.withOpacity( 0.3),
                                  width: 1,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return _isLoading
        ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(PetCareTheme.primaryBrown),
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: PetCareTheme.cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [PetCareTheme.elevatedShadow],
                    border: Border.all(
                      color: PetCareTheme.primaryBrown.withOpacity( 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  PetCareTheme.primaryBrown.withOpacity( 0.1),
                                  PetCareTheme.primaryBrown.withOpacity( 0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.history_rounded,
                              color: PetCareTheme.primaryBrown,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Appointment History',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: PetCareTheme.textDark,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_appointments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: PetCareTheme.primaryBeige.withOpacity( 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: PetCareTheme.primaryBrown.withOpacity( 0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      PetCareTheme.primaryBrown.withOpacity( 0.1),
                                      PetCareTheme.lightBrown.withOpacity( 0.1),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.calendar_today_outlined,
                                  size: 40,
                                  color: PetCareTheme.primaryBrown.withOpacity( 0.6),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No appointments yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: PetCareTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Appointments will appear here once scheduled',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: PetCareTheme.textLight,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: _appointments.take(5).map((appointment) => _buildAppointmentTile(appointment)).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PetCareTheme.primaryBeige.withOpacity( 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PetCareTheme.primaryBrown.withOpacity( 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: PetCareTheme.primaryBrown.withOpacity( 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: PetCareTheme.primaryBrown,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: PetCareTheme.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: PetCareTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRecordTile(HealthRecordModel record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PetCareTheme.primaryBeige.withOpacity( 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PetCareTheme.primaryBrown.withOpacity( 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: PetCareTheme.softGreen.withOpacity( 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.medical_services_rounded,
              color: PetCareTheme.softGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PetCareTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_getRecordTypeName(record.type)} • ${_formatDate(record.recordDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: PetCareTheme.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (record.nextDueDate != null && record.isDue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: record.isOverdue ? PetCareTheme.warmRed.withOpacity( 0.1) : PetCareTheme.accentGold.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: record.isOverdue ? PetCareTheme.warmRed.withOpacity( 0.3) : PetCareTheme.accentGold.withOpacity( 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                record.isOverdue ? 'Overdue' : 'Due',
                style: TextStyle(
                  color: record.isOverdue ? PetCareTheme.warmRed : PetCareTheme.accentGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentTile(AppointmentModel appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PetCareTheme.primaryBeige.withOpacity( 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PetCareTheme.primaryBrown.withOpacity( 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: PetCareTheme.primaryBrown.withOpacity( 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: PetCareTheme.primaryBrown,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.reason,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PetCareTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(appointment.appointmentDate)} • ${appointment.status}',
                  style: TextStyle(
                    fontSize: 12,
                    color: PetCareTheme.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Pet',
          style: TextStyle(
            color: PetCareTheme.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${widget.pet.name}? This action cannot be undone.',
          style: TextStyle(
            color: PetCareTheme.textLight,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: PetCareTheme.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: PetCareTheme.accentGradient),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final petService = Provider.of<PetService>(context, listen: false);
                await petService.deletePet(widget.pet.id);
                Navigator.pop(context);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSpeciesName(PetSpecies species) {
    switch (species) {
      case PetSpecies.dog:
        return 'Dog';
      case PetSpecies.cat:
        return 'Cat';
      case PetSpecies.bird:
        return 'Bird';
      case PetSpecies.fish:
        return 'Fish';
      case PetSpecies.rabbit:
        return 'Rabbit';
      case PetSpecies.hamster:
        return 'Hamster';
      case PetSpecies.reptile:
        return 'Reptile';
      case PetSpecies.other:
        return 'Other';
    }
  }

  String _getGenderName(PetGender gender) {
    switch (gender) {
      case PetGender.male:
        return 'Male';
      case PetGender.female:
        return 'Female';
      case PetGender.unknown:
        return 'Unknown';
    }
  }

  Color _getHealthStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return PetCareTheme.softGreen;
      case HealthStatus.sick:
        return Colors.orange;
      case HealthStatus.recovering:
        return PetCareTheme.accentGold;
      case HealthStatus.critical:
        return PetCareTheme.warmRed;
      case HealthStatus.unknown:
        return PetCareTheme.textLight;
    }
  }

  String _getHealthStatusName(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return 'Healthy';
      case HealthStatus.sick:
        return 'Sick';
      case HealthStatus.recovering:
        return 'Recovering';
      case HealthStatus.critical:
        return 'Critical';
      case HealthStatus.unknown:
        return 'Unknown';
    }
  }

  String _getHealthStatusText(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return 'Your pet is in excellent health!';
      case HealthStatus.sick:
        return 'Your pet needs medical attention.';
      case HealthStatus.recovering:
        return 'Your pet is recovering well.';
      case HealthStatus.critical:
        return 'Your pet needs immediate medical attention.';
      case HealthStatus.unknown:
        return 'Health status is unknown.';
    }
  }

  String _getRecordTypeName(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccination:
        return 'Vaccination';
      case HealthRecordType.checkup:
        return 'Checkup';
      case HealthRecordType.medication:
        return 'Medication';
      case HealthRecordType.surgery:
        return 'Surgery';
      case HealthRecordType.allergy:
        return 'Allergy';
      case HealthRecordType.injury:
        return 'Injury';
      case HealthRecordType.other:
        return 'Other';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}