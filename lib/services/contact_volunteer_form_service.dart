import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact_volunteer_form_model.dart';

class ContactVolunteerFormService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get contact/volunteer forms by shelter owner ID
  Future<List<ContactVolunteerFormModel>> getFormsByShelterOwnerId(String shelterOwnerId) async {
    try {
      print('🔍 Fetching contact/volunteer forms for shelter owner ID: $shelterOwnerId');
      
      // First, let's check if there are ANY forms in the collection
      final allFormsSnapshot = await _firestore
          .collection('contact_volunteer_forms')
          .get();
      
      print('📊 Total forms in collection: ${allFormsSnapshot.docs.length}');
      
      if (allFormsSnapshot.docs.isNotEmpty) {
        print('📋 Sample form data:');
        for (int i = 0; i < allFormsSnapshot.docs.length && i < 3; i++) {
          final doc = allFormsSnapshot.docs[i];
          print('  Form ${i + 1}: ${doc.data()}');
        }
      }
      
      // Get forms for the specific shelter owner
      final specificQuerySnapshot = await _firestore
          .collection('contact_volunteer_forms')
          .where('shelterOwnerId', isEqualTo: shelterOwnerId)
          .where('isActive', isEqualTo: true)
          .get();

      // Also get forms for the default shelter owner (for demo purposes)
      final defaultQuerySnapshot = await _firestore
          .collection('contact_volunteer_forms')
          .where('shelterOwnerId', isEqualTo: 'default_shelter_owner')
          .where('isActive', isEqualTo: true)
          .get();

      print('📈 Found ${specificQuerySnapshot.docs.length} specific forms and ${defaultQuerySnapshot.docs.length} default forms');

      // Get ALL active forms regardless of shelter owner ID
      final activeFormsSnapshot = await _firestore
          .collection('contact_volunteer_forms')
          .where('isActive', isEqualTo: true)
          .get();

      print('🌍 Found ${activeFormsSnapshot.docs.length} total active forms in collection');

      // Combine all results and remove duplicates
      final allDocs = [...specificQuerySnapshot.docs, ...defaultQuerySnapshot.docs, ...activeFormsSnapshot.docs];
      
      // Remove duplicates based on document ID
      final uniqueDocs = <String, QueryDocumentSnapshot>{};
      for (final doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }
      final finalDocs = uniqueDocs.values.toList();
      
      print('🔄 After removing duplicates: ${finalDocs.length} unique forms');

      final forms = finalDocs.map((doc) {
        try {
          print('🔄 Processing form document: ${doc.id}');
          return ContactVolunteerFormModel.fromFirestore(doc);
        } catch (e) {
          print('❌ Error processing form ${doc.id}: $e');
          return null;
        }
      }).where((form) => form != null).cast<ContactVolunteerFormModel>().toList();

      // Sort manually in code instead of Firestore
      forms.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Successfully parsed ${forms.length} total forms');
      return forms;
    } catch (e) {
      print('❌ Error getting forms: $e');
      print('📊 Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get form by ID
  Future<ContactVolunteerFormModel?> getFormById(String formId) async {
    try {
      print('Fetching form with ID: $formId');
      final doc = await _firestore.collection('contact_volunteer_forms').doc(formId).get();
      
      if (doc.exists && doc.data() != null) {
        print('Form found: ${doc.data()}');
        return ContactVolunteerFormModel.fromFirestore(doc);
      } else {
        print('Form not found or has no data');
      }
    } catch (e) {
      print('Error getting form: $e');
    }
    return null;
  }

  // Add new form
  Future<String?> addForm(ContactVolunteerFormModel form) async {
    try {
      print('=== ADDING FORM TO FIRESTORE ===');
      print('Form type: ${form.formType}');
      print('Subject: ${form.subject}');
      print('Shelter Owner ID: ${form.shelterOwnerId}');
      print('Submitter: ${form.submitterName} (${form.submitterEmail})');
      
      // Validate required fields
      if (form.shelterOwnerId.isEmpty) {
        print('❌ Error: shelterOwnerId is empty');
        return null;
      }
      if (form.submitterName.isEmpty) {
        print('❌ Error: submitterName is empty');
        return null;
      }
      if (form.submitterEmail.isEmpty) {
        print('❌ Error: submitterEmail is empty');
        return null;
      }
      if (form.subject.isEmpty) {
        print('❌ Error: subject is empty');
        return null;
      }
      if (form.message.isEmpty) {
        print('❌ Error: message is empty');
        return null;
      }
      
      print('✅ All validations passed');
      print('📝 Converting form to Firestore format...');
      
      final formData = form.toFirestore();
      print('📄 Form data for Firestore: $formData');
      
      print('🔥 Attempting to add to Firestore collection: contact_volunteer_forms');
      
      final docRef = await _firestore.collection('contact_volunteer_forms').add(formData);
      
      print('✅ Form added successfully!');
      print('📋 Document ID: ${docRef.id}');
      print('🔗 Document path: ${docRef.path}');
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      print('❌ Error adding form to Firestore: $e');
      print('🔍 Error type: ${e.runtimeType}');
      print('📊 Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Update form
  Future<bool> updateForm(ContactVolunteerFormModel form) async {
    try {
      print('Updating form: ${form.id}');
      
      final updatedForm = form.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('contact_volunteer_forms')
          .doc(form.id)
          .update(updatedForm.toFirestore());
      
      print('Form updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating form: $e');
      return false;
    }
  }

  // Delete form (soft delete)
  Future<bool> deleteForm(String formId) async {
    try {
      print('Soft deleting form: $formId');
      
      await _firestore.collection('contact_volunteer_forms').doc(formId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('Form deleted successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting form: $e');
      return false;
    }
  }

  // Search forms
  Future<List<ContactVolunteerFormModel>> searchForms({
    required String query,
    String? shelterOwnerId,
    FormType? formType,
    FormStatus? status,
  }) async {
    try {
      print('Searching forms with query: $query');
      
      Query baseQuery = _firestore.collection('contact_volunteer_forms');
      
      if (shelterOwnerId != null) {
        baseQuery = baseQuery.where('shelterOwnerId', isEqualTo: shelterOwnerId);
      }

      if (formType != null) {
        baseQuery = baseQuery.where('formType', isEqualTo: formType.toString().split('.').last);
      }

      if (status != null) {
        baseQuery = baseQuery.where('status', isEqualTo: status.toString().split('.').last);
      }

      final querySnapshot = await baseQuery
          .where('isActive', isEqualTo: true)
          .get();

      final forms = querySnapshot.docs
          .map((doc) {
            try {
              return ContactVolunteerFormModel.fromFirestore(doc);
            } catch (e) {
              print('Error parsing form in search: $e');
              return null;
            }
          })
          .where((form) => form != null)
          .cast<ContactVolunteerFormModel>()
          .toList();

      // Filter by search query
      final filteredForms = forms.where((form) {
        final searchText = query.toLowerCase();
        return form.subject.toLowerCase().contains(searchText) ||
               form.message.toLowerCase().contains(searchText) ||
               form.submitterName.toLowerCase().contains(searchText) ||
               form.submitterEmail.toLowerCase().contains(searchText) ||
               form.formTypeDisplayName.toLowerCase().contains(searchText);
      }).toList();

      print('Found ${filteredForms.length} forms matching search');
      return filteredForms;
    } catch (e) {
      print('Error searching forms: $e');
      return [];
    }
  }

  // Get forms by type
  Future<List<ContactVolunteerFormModel>> getFormsByType(FormType formType, {String? shelterOwnerId}) async {
    try {
      print('Fetching forms by type: $formType');
      
      Query query = _firestore
          .collection('contact_volunteer_forms')
          .where('formType', isEqualTo: formType.toString().split('.').last)
          .where('isActive', isEqualTo: true);
      
      if (shelterOwnerId != null) {
        query = query.where('shelterOwnerId', isEqualTo: shelterOwnerId);
      }

      final querySnapshot = await query.get();

      final forms = querySnapshot.docs
          .map((doc) {
            try {
              return ContactVolunteerFormModel.fromFirestore(doc);
            } catch (e) {
              print('Error parsing form by type: $e');
              return null;
            }
          })
          .where((form) => form != null)
          .cast<ContactVolunteerFormModel>()
          .toList();

      print('Found ${forms.length} forms of type $formType');
      return forms;
    } catch (e) {
      print('Error getting forms by type: $e');
      return [];
    }
  }

  // Get forms by status
  Future<List<ContactVolunteerFormModel>> getFormsByStatus(FormStatus status, {String? shelterOwnerId}) async {
    try {
      print('Fetching forms by status: $status');
      
      Query query = _firestore
          .collection('contact_volunteer_forms')
          .where('status', isEqualTo: status.toString().split('.').last)
          .where('isActive', isEqualTo: true);
      
      if (shelterOwnerId != null) {
        query = query.where('shelterOwnerId', isEqualTo: shelterOwnerId);
      }

      final querySnapshot = await query.get();

      final forms = querySnapshot.docs
          .map((doc) {
            try {
              return ContactVolunteerFormModel.fromFirestore(doc);
            } catch (e) {
              print('Error parsing form by status: $e');
              return null;
            }
          })
          .where((form) => form != null)
          .cast<ContactVolunteerFormModel>()
          .toList();

      print('Found ${forms.length} forms with status $status');
      return forms;
    } catch (e) {
      print('Error getting forms by status: $e');
      return [];
    }
  }

  // Stream forms by shelter owner ID (real-time updates)
  Stream<List<ContactVolunteerFormModel>> streamFormsByShelterOwnerId(String shelterOwnerId) {
    print('Setting up stream for forms of shelter owner: $shelterOwnerId');
    
    return _firestore
        .collection('contact_volunteer_forms')
        .where('shelterOwnerId', isEqualTo: shelterOwnerId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Stream received ${snapshot.docs.length} forms');
          
          return snapshot.docs
              .map((doc) {
                try {
                  return ContactVolunteerFormModel.fromFirestore(doc);
                } catch (e) {
                  print('Error parsing form in stream: $e');
                  return null;
                }
              })
              .where((form) => form != null)
              .cast<ContactVolunteerFormModel>()
              .toList();
        });
  }

  // Update form status
  Future<bool> updateFormStatus(String formId, FormStatus status, {String? response}) async {
    try {
      print('Updating form status: $formId to $status');
      
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (response != null) {
        updateData['response'] = response;
        updateData['responseDate'] = Timestamp.fromDate(DateTime.now());
      }
      
      await _firestore.collection('contact_volunteer_forms').doc(formId).update(updateData);
      
      print('Form status updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating form status: $e');
      return false;
    }
  }

  // Get form statistics
  Future<Map<String, int>> getFormStatistics(String shelterOwnerId) async {
    try {
      final allForms = await getFormsByShelterOwnerId(shelterOwnerId);
      
      final stats = <String, int>{
        'total': allForms.length,
        'contact': allForms.where((f) => f.formType == FormType.contact).length,
        'volunteer': allForms.where((f) => f.formType == FormType.volunteer).length,
        'donation': allForms.where((f) => f.formType == FormType.donation).length,
        'pending': allForms.where((f) => f.status == FormStatus.pending).length,
        'responded': allForms.where((f) => f.status == FormStatus.responded).length,
        'closed': allForms.where((f) => f.status == FormStatus.closed).length,
        'thisMonth': allForms.where((f) => 
          f.createdAt.month == DateTime.now().month && 
          f.createdAt.year == DateTime.now().year
        ).length,
        'thisWeek': allForms.where((f) => 
          f.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))
        ).length,
      };
      
      return stats;
    } catch (e) {
      print('Error getting form statistics: $e');
      return {};
    }
  }

  // Get recent forms (last 7 days)
  Future<List<ContactVolunteerFormModel>> getRecentForms(String shelterOwnerId, {int days = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final querySnapshot = await _firestore
          .collection('contact_volunteer_forms')
          .where('shelterOwnerId', isEqualTo: shelterOwnerId)
          .where('isActive', isEqualTo: true)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .get();

      final forms = querySnapshot.docs
          .map((doc) {
            try {
              return ContactVolunteerFormModel.fromFirestore(doc);
            } catch (e) {
              print('Error parsing recent form: $e');
              return null;
            }
          })
          .where((form) => form != null)
          .cast<ContactVolunteerFormModel>()
          .toList();

      forms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return forms;
    } catch (e) {
      print('Error getting recent forms: $e');
      return [];
    }
  }
}
