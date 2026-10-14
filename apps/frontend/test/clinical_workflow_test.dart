import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_frontend/features/patients/domain/models/patient.dart';
import 'package:hospital_frontend/features/doctors/domain/models/doctor.dart';
import 'package:hospital_frontend/features/appointments/domain/models/appointment.dart';
import 'package:hospital_frontend/features/dashboard/domain/models/dashboard_overview.dart';

void main() {
  group('Phase 5 Domain Models Unit Tests', () {
    test('Patient model parses correctly and exposes clinical getters', () {
      final json = {
        'id': 'CP-2026-001',
        'name': 'Ramesh',
        'surname': 'Patel',
        'phone': '+91 98250 12345',
        'age': 54,
        'gender': 'Male',
        'bloodGroup': 'B+',
        'emergencyContactName': 'Geeta Patel',
        'emergencyContactPhone': '+91 98250 54321',
        'qrToken': 'a5b4c3d2-0001',
      };

      final patient = Patient.fromJson(json);

      expect(patient.id, 'CP-2026-001');
      expect(patient.mrn, 'CP-2026-001');
      expect(patient.fullName, 'Ramesh Patel');
      expect(patient.ageGender, '54 Yrs • Male');
      expect(patient.bloodGroup, 'B+');
      expect(patient.emergencyContact?['name'], 'Geeta Patel');
    });

    test('Doctor and Slot models parse properly with booking collision detection', () {
      final docJson = {
        'id': 'DOC001',
        'name': 'Dr. Rajesh Sharma',
        'departmentId': 'dept-cardio',
        'department': {'name': 'Cardiology'},
        'degree': 'MBBS, MD (Cardio)',
        'consultationFee': 800,
        'status': 'Available',
      };

      final doc = Doctor.fromJson(docJson);
      expect(doc.name, 'Dr. Rajesh Sharma');
      expect(doc.departmentName, 'Cardiology');
      expect(doc.consultationFee, 800.0);
      expect(doc.specialization, 'MBBS, MD (Cardio)');

      final slotAvailable = DoctorSlotItem.fromJson({
        'slot': '10:00 AM',
        'isAvailable': true,
        'status': 'Available',
      });
      expect(slotAvailable.time, '10:00 AM');
      expect(slotAvailable.isBooked, false);

      final slotBooked = DoctorSlotItem.fromJson({
        'slot': '10:30 AM',
        'isAvailable': false,
        'status': 'Booked',
      });
      expect(slotBooked.time, '10:30 AM');
      expect(slotBooked.isBooked, true);
    });

    test('Appointment model parses with diagnoses and prescriptions', () {
      final apptJson = {
        'id': 101,
        'patientId': 'CP-2026-001',
        'patient': {'name': 'Ramesh', 'surname': 'Patel', 'phone': '+91 98250 12345'},
        'doctorId': 'DOC001',
        'doctor': {
          'name': 'Dr. Rajesh Sharma',
          'department': {'name': 'Cardiology'}
        },
        'date': '2026-10-14',
        'slot': '10:00 AM',
        'tokenNumber': 1,
        'symptoms': 'Chest tightness',
        'status': 'Completed',
        'stage': 4,
        'bookingType': 'walk-in',
        'diagnoses': [
          {'id': 1, 'icd10Code': 'I20.9', 'description': 'Angina pectoris'},
        ],
        'prescriptions': [
          {
            'id': 1,
            'medicineName': 'Tab. Atorvastatin 20mg',
            'dosage': '1 Tab',
            'frequency': 'HS',
            'duration': '30 Days',
            'instructions': 'At bedtime',
          }
        ],
      };

      final appt = Appointment.fromJson(apptJson);
      expect(appt.id, 101);
      expect(appt.patientMrn, 'CP-2026-001');
      expect(appt.patientName, 'Ramesh Patel');
      expect(appt.tokenNumber, 1);
      expect(appt.slotTime, '10:00 AM');
      expect(appt.queueStage, 4);
      expect(appt.diagnoses.length, 1);
      expect(appt.diagnoses.first.icd10Code, 'I20.9');
      expect(appt.prescriptions.length, 1);
      expect(appt.prescriptions.first.frequency, 'HS');
    });

    test('DashboardOverview parses live aggregated KPIs', () {
      final overviewJson = {
        'kpis': {
          'totalPatients': 1428,
          'todayAppointments': 24,
          'waitingQueue': 4,
          'inConsultation': 2,
          'bedOccupancy': {
            'occupied': 8,
            'total': 10,
            'ratePercent': 80,
          },
          'activeDoctors': 4,
          'emergencyCases': 1,
        },
        'recentActivity': [
          {
            'id': 1,
            'patientMrn': 'CP-2026-001',
            'patientName': 'Ramesh Patel',
            'eventTime': '10:30 AM',
            'description': 'Consultation completed by Dr. Rajesh Sharma',
          }
        ],
      };

      final overview = DashboardOverview.fromJson(overviewJson);
      expect(overview.kpis.totalPatients, 1428);
      expect(overview.kpis.todayAppointments, 24);
      expect(overview.kpis.bedOccupancy.occupied, 8);
      expect(overview.kpis.bedOccupancy.ratePercent, 80);
      expect(overview.recentActivity.length, 1);
      expect(overview.recentActivity.first.patientMrn, 'CP-2026-001');
    });
  });
}
