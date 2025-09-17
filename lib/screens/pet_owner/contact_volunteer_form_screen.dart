import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/contact_volunteer_form_service.dart';
import '../../models/contact_volunteer_form_model.dart';
import '../../theme/pet_care_theme.dart';

class ContactVolunteerFormScreen extends StatefulWidget {
  final FormType formType;

  const ContactVolunteerFormScreen({
    super.key,
    required this.formType,
  });

  @override
  State<ContactVolunteerFormScreen> createState() => _ContactVolunteerFormScreenState();
}

class _ContactVolunteerFormScreenState extends State<ContactVolunteerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _volunteerInterestsController = TextEditingController();
  final _availableDaysController = TextEditingController();
  final _availableTimesController = TextEditingController();
  final _skillsController = TextEditingController();
  final _donationAmountController = TextEditingController();
  final _donationTypeController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setDefaultSubject();
  }

  void _setDefaultSubject() {
    switch (widget.formType) {
      case FormType.contact:
        _subjectController.text = 'General Inquiry';
        break;
      case FormType.volunteer:
        _subjectController.text = 'Volunteer Application';
        break;
      case FormType.donation:
        _subjectController.text = 'Donation Inquiry';
        break;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _volunteerInterestsController.dispose();
    _availableDaysController.dispose();
    _availableTimesController.dispose();
    _skillsController.dispose();
    _donationAmountController.dispose();
    _donationTypeController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUserModel;
      
      if (user == null) {
        _showErrorSnackBar('Please log in to submit this form');
        return;
      }

      const String placeholderShelterOwnerId = 'default_shelter_owner';

      final form = ContactVolunteerFormModel(
        id: '',
        shelterOwnerId: placeholderShelterOwnerId,
        submitterName: user.fullName,
        submitterEmail: user.email,
        submitterPhone: user.phoneNumber ?? '',
        formType: widget.formType,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        volunteerInterests: widget.formType == FormType.volunteer 
            ? _volunteerInterestsController.text.trim().isEmpty 
                ? null 
                : _volunteerInterestsController.text.trim()
            : null,
        availableDays: widget.formType == FormType.volunteer 
            ? _availableDaysController.text.trim().isEmpty 
                ? null 
                : _availableDaysController.text.trim()
            : null,
        availableTimes: widget.formType == FormType.volunteer 
            ? _availableTimesController.text.trim().isEmpty 
                ? null 
                : _availableTimesController.text.trim()
            : null,
        skills: widget.formType == FormType.volunteer 
            ? _skillsController.text.trim().isEmpty 
                ? null 
                : _skillsController.text.trim()
            : null,
        donationAmount: widget.formType == FormType.donation 
            ? _donationAmountController.text.trim().isEmpty 
                ? null 
                : _donationAmountController.text.trim()
            : null,
        donationType: widget.formType == FormType.donation 
            ? _donationTypeController.text.trim().isEmpty 
                ? null 
                : _donationTypeController.text.trim()
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final formService = Provider.of<ContactVolunteerFormService>(context, listen: false);
      final formId = await formService.addForm(form);
      
      if (formId != null) {
        _showSuccessSnackBar('Form submitted successfully!');
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar('Failed to submit form');
      }
    } catch (e) {
      _showErrorSnackBar('Error submitting form: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: PetCareTheme.warmRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: PetCareTheme.softGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormHeader(),
                      const SizedBox(height: 24),
                      _buildFormField(
                        controller: _subjectController,
                        labelText: 'Subject *',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a subject';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildFormField(
                        controller: _messageController,
                        labelText: 'Message *',
                        hintText: _getMessageHint(),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your message';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      if (widget.formType == FormType.volunteer) ...[
                        _buildVolunteerFields(),
                      ] else if (widget.formType == FormType.donation) ...[
                        _buildDonationFields(),
                      ],
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: PetCareTheme.accentGradient),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: PetCareTheme.shadowColor,
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Submit ${_getFormTitle()}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
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
                child: Text(
                  _getFormTitle(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: PetCareTheme.primaryBeige,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: PetCareTheme.primaryBeige.withOpacity( 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(PetCareTheme.primaryBeige),
                    ),
                  ),
                )
              else
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
                  child: TextButton(
                    onPressed: _submitForm,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [PetCareTheme.elevatedShadow],
        border: Border.all(
          color: _getFormColor().withOpacity( 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getFormColor().withOpacity( 0.1),
                      _getFormColor().withOpacity( 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getFormIcon(),
                  color: _getFormColor(),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getFormTitle(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: PetCareTheme.textDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFormDescription(),
                      style: TextStyle(
                        color: PetCareTheme.textLight,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [PetCareTheme.elevatedShadow],
        border: Border.all(
          color: PetCareTheme.primaryBrown.withOpacity( 0.1),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixText: prefixText,
          labelStyle: TextStyle(
            color: PetCareTheme.primaryBrown,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(
            color: PetCareTheme.textLight,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: PetCareTheme.primaryBrown.withOpacity( 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: PetCareTheme.primaryBrown.withOpacity( 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: PetCareTheme.primaryBrown,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: PetCareTheme.primaryBeige.withOpacity( 0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          color: PetCareTheme.textDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildVolunteerFields() {
    return Container(
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
                  Icons.volunteer_activism_rounded,
                  color: PetCareTheme.softGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Volunteer Information',
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
          _buildFormField(
            controller: _volunteerInterestsController,
            labelText: 'What areas are you interested in volunteering?',
            hintText: 'e.g., animal care, administrative work, events...',
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            controller: _availableDaysController,
            labelText: 'What days are you available?',
            hintText: 'e.g., Weekends, Monday-Friday, etc...',
          ),
          const SizedBox(height: 20),
          _buildFormField(
            controller: _availableTimesController,
            labelText: 'What times are you available?',
            hintText: 'e.g., Mornings, Afternoons, Evenings...',
          ),
          const SizedBox(height: 20),
          _buildFormField(
            controller: _skillsController,
            labelText: 'What skills or experience do you have?',
            hintText: 'e.g., Animal handling, customer service, fundraising...',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDonationFields() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [PetCareTheme.elevatedShadow],
        border: Border.all(
          color: PetCareTheme.accentGold.withOpacity( 0.2),
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
                  Icons.attach_money_rounded,
                  color: PetCareTheme.accentGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Donation Information',
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
          _buildFormField(
            controller: _donationAmountController,
            labelText: 'Donation Amount',
            hintText: 'e.g., \$50, \$100, etc...',
            prefixText: '\$',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            controller: _donationTypeController,
            labelText: 'Type of Donation',
            hintText: 'e.g., Monetary, Supplies, Food, etc...',
          ),
        ],
      ),
    );
  }

  String _getFormTitle() {
    switch (widget.formType) {
      case FormType.contact:
        return 'Contact Us';
      case FormType.volunteer:
        return 'Volunteer Application';
      case FormType.donation:
        return 'Donation Inquiry';
    }
  }

  String _getFormDescription() {
    switch (widget.formType) {
      case FormType.contact:
        return 'Get in touch with us for any questions or concerns';
      case FormType.volunteer:
        return 'Join our team and help us care for animals in need';
      case FormType.donation:
        return 'Support our mission by making a donation';
    }
  }

  String _getMessageHint() {
    switch (widget.formType) {
      case FormType.contact:
        return 'How can we help you?';
      case FormType.volunteer:
        return 'Tell us about yourself and why you want to volunteer...';
      case FormType.donation:
        return 'Tell us about your donation or how you\'d like to help...';
    }
  }

  IconData _getFormIcon() {
    switch (widget.formType) {
      case FormType.contact:
        return Icons.contact_mail;
      case FormType.volunteer:
        return Icons.volunteer_activism;
      case FormType.donation:
        return Icons.attach_money;
    }
  }

  Color _getFormColor() {
    switch (widget.formType) {
      case FormType.contact:
        return PetCareTheme.primaryBrown;
      case FormType.volunteer:
        return PetCareTheme.softGreen;
      case FormType.donation:
        return PetCareTheme.accentGold;
    }
  }
}