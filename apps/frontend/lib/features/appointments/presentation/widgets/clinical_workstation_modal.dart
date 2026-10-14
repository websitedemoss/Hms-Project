import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/appointment.dart';
import '../providers/appointments_provider.dart';

class ClinicalWorkstationModal extends ConsumerStatefulWidget {
  final Appointment appointment;

  const ClinicalWorkstationModal({super.key, required this.appointment});

  static Future<void> show(BuildContext context, Appointment appointment) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860, maxHeight: 780),
          child: ClinicalWorkstationModal(appointment: appointment),
        ),
      ),
    );
  }

  @override
  ConsumerState<ClinicalWorkstationModal> createState() => _ClinicalWorkstationModalState();
}

class _ClinicalWorkstationModalState extends ConsumerState<ClinicalWorkstationModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Step 1: Diagnoses
  final List<Map<String, String>> _diagnoses = [];
  final _icdCodeController = TextEditingController();
  final _icdDescController = TextEditingController();

  // Step 2: Prescriptions
  final List<Map<String, String>> _prescriptions = [];
  final _medNameController = TextEditingController();
  final _medDosageController = TextEditingController(text: '1 Tab');
  String _medFrequency = 'BID';
  final _medDurationController = TextEditingController(text: '5 Days');
  final _medInstructionsController = TextEditingController(text: 'After meals');

  // Step 3: Disposition
  String _disposition = 'Discharged';
  String? _selectedBed;
  final _labTestsController = TextEditingController();

  // Step 4: Notes
  final _doctorNotesController = TextEditingController();

  bool _isSaving = false;

  final List<String> _bedOptions = [
    'ICU-01',
    'ICU-02',
    'PVT-01',
    'PVT-02',
    'GEN-01',
    'GEN-02',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // If appointment already had complaints, seed doctor notes or diagnoses
    if (widget.appointment.diagnoses.isNotEmpty) {
      for (final d in widget.appointment.diagnoses) {
        _diagnoses.add({
          'icd10Code': d.icd10Code ?? '',
          'description': d.description,
        });
      }
    }
    if (widget.appointment.prescriptions.isNotEmpty) {
      for (final p in widget.appointment.prescriptions) {
        _prescriptions.add({
          'medicineName': p.medicineName,
          'dosage': p.dosage,
          'frequency': p.frequency,
          'duration': p.duration,
          'instructions': p.instructions ?? '',
        });
      }
    }
    if (widget.appointment.doctorNotes != null) {
      _doctorNotesController.text = widget.appointment.doctorNotes!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _icdCodeController.dispose();
    _icdDescController.dispose();
    _medNameController.dispose();
    _medDosageController.dispose();
    _medDurationController.dispose();
    _medInstructionsController.dispose();
    _labTestsController.dispose();
    _doctorNotesController.dispose();
    super.dispose();
  }

  void _addDiagnosis(String code, String desc) {
    if (desc.trim().isEmpty) return;
    setState(() {
      _diagnoses.add({'icd10Code': code.trim(), 'description': desc.trim()});
      _icdCodeController.clear();
      _icdDescController.clear();
    });
  }

  void _addPrescription() {
    final name = _medNameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _prescriptions.add({
        'medicineName': name,
        'dosage': _medDosageController.text.trim(),
        'frequency': _medFrequency,
        'duration': _medDurationController.text.trim(),
        'instructions': _medInstructionsController.text.trim(),
      });
      _medNameController.clear();
    });
  }

  Future<void> _saveConsultation() async {
    setState(() => _isSaving = true);

    try {
      final payload = {
        'diagnoses': _diagnoses,
        'prescriptions': _prescriptions,
        'disposition': _disposition,
        if (_disposition.contains('Admit')) 'bedNumber': _selectedBed,
        if (_labTestsController.text.isNotEmpty) 'labTests': _labTestsController.text.trim(),
        if (_doctorNotesController.text.isNotEmpty) 'doctorNotes': _doctorNotesController.text.trim(),
      };

      await ref.read(queueProvider.notifier).saveConsultation(widget.appointment.id, payload);
      // Also refresh appointment list
      ref.read(appointmentsProvider.notifier).loadAppointments(widget.appointment.date);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              'Consultation saved successfully for ${widget.appointment.patientName}!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Failed to save consultation: ${e.toString().replaceFirst("Exception: ", "")}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinical Header Banner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    radius: 20,
                    child: Text('#${appt.tokenNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinical Workstation • ${appt.patientName}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${appt.patientMrn} • Dr. ${appt.doctorName} (${appt.departmentName}) • Slot: ${appt.slotTime}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          if (appt.chiefComplaints != null && appt.chiefComplaints!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chief Complaint: ${appt.chiefComplaints}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // 4 Step Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondaryLight,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(
                text: '1. Diagnoses (${_diagnoses.length})',
                icon: const Icon(Icons.assignment_outlined, size: 18),
              ),
              Tab(
                text: '2. Rx Prescriptions (${_prescriptions.length})',
                icon: const Icon(Icons.medication_outlined, size: 18),
              ),
              Tab(
                text: '3. Disposition & Beds',
                icon: const Icon(Icons.hotel_outlined, size: 18),
              ),
              Tab(
                text: '4. Summary Notes',
                icon: const Icon(Icons.notes_outlined, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Step 1: Diagnoses
                _buildDiagnosesTab(),

                // Step 2: Prescriptions
                _buildPrescriptionsTab(),

                // Step 3: Disposition & Beds
                _buildDispositionTab(),

                // Step 4: Summary Notes
                _buildSummaryTab(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Footer Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      if (_tabController.index > 0) {
                        _tabController.animateTo(_tabController.index - 1);
                      }
                    },
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_tabController.index < 3) {
                        _tabController.animateTo(_tabController.index + 1);
                      }
                    },
                    child: const Text('Next Step'),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(160, 44),
                ),
                onPressed: _isSaving ? null : _saveConsultation,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Complete & Sign Consultation'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 1: DIAGNOSES ---
  Widget _buildDiagnosesTab() {
    final quickPicks = [
      {'code': 'I10', 'desc': 'Essential (Primary) Hypertension'},
      {'code': 'E11.9', 'desc': 'Type 2 Diabetes Mellitus'},
      {'code': 'G43.9', 'desc': 'Migraine, unspecified'},
      {'code': 'M54.5', 'desc': 'Low back pain'},
      {'code': 'J06.9', 'desc': 'Acute upper respiratory infection'},
      {'code': 'K21.9', 'desc': 'Gastro-esophageal reflux disease'},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Diagnosis Selection (ICD-10)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: quickPicks.map((qp) {
              return ActionChip(
                label: Text('${qp['code']} - ${qp['desc']}', style: const TextStyle(fontSize: 11)),
                onPressed: () => _addDiagnosis(qp['code']!, qp['desc']!),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _icdCodeController,
                  decoration: const InputDecoration(labelText: 'ICD-10 Code', hintText: 'e.g. I20.9'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _icdDescController,
                  decoration: const InputDecoration(
                    labelText: 'Clinical Diagnosis Description *',
                    hintText: 'e.g. Angina Pectoris',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _addDiagnosis(_icdCodeController.text, _icdDescController.text),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Active Diagnoses for this Visit:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          if (_diagnoses.isEmpty)
            const Text('No diagnoses added yet. Please add at least one diagnosis.',
                style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12))
          else
            ..._diagnoses.asMap().entries.map((entry) {
              final idx = entry.key;
              final d = entry.value;
              return Card(
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                    child: Text('${idx + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(d['description']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text('ICD-10: ${d['icd10Code']!.isNotEmpty ? d['icd10Code'] : "Unspecified"}',
                      style: const TextStyle(fontSize: 11)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                    onPressed: () => setState(() => _diagnoses.removeAt(idx)),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // --- TAB 2: PRESCRIPTIONS ---
  Widget _buildPrescriptionsTab() {
    final latinOptions = [
      {'code': 'TID', 'label': 'TID (3 times daily / morning-noon-night)'},
      {'code': 'BID', 'label': 'BID (2 times daily / morning-night)'},
      {'code': 'OD', 'label': 'OD (Once daily)'},
      {'code': 'QID', 'label': 'QID (4 times daily)'},
      {'code': 'HS', 'label': 'HS (At bedtime)'},
      {'code': 'SOS', 'label': 'SOS (As needed / emergency)'},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _medNameController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name & Strength *',
                    hintText: 'e.g. Tab. Telmisartan 40mg',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _medDosageController,
                  decoration: const InputDecoration(labelText: 'Dosage', hintText: '1 Tab'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _medFrequency,
                  decoration: const InputDecoration(labelText: 'Frequency (Latin)'),
                  items: latinOptions
                      .map((o) => DropdownMenuItem(value: o['code'], child: Text(o['label']!, style: const TextStyle(fontSize: 11))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _medFrequency = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _medDurationController,
                  decoration: const InputDecoration(labelText: 'Duration', hintText: '5 Days'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _medInstructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Patient Instructions',
                    hintText: 'e.g. After meals with water',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _addPrescription,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Rx'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Prescribed Medication Regimen:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          if (_prescriptions.isEmpty)
            const Text('No medicines prescribed yet.', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12))
          else
            ..._prescriptions.asMap().entries.map((entry) {
              final idx = entry.key;
              final rx = entry.value;
              return Card(
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.medication, color: AppColors.primary, size: 20),
                  title: Text('${rx['medicineName']} - ${rx['dosage']}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text('${rx['frequency']} • ${rx['duration']} • Instructions: ${rx['instructions']}',
                      style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                    onPressed: () => setState(() => _prescriptions.removeAt(idx)),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // --- TAB 3: DISPOSITION & BEDS ---
  Widget _buildDispositionTab() {
    final dispositions = [
      'Discharged',
      'Waiting for Reports',
      'Admitted to Ward',
      'Admitted to ICU',
    ];

    final isAdmission = _disposition.contains('Admit');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Patient Clinical Disposition *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: dispositions.map((disp) {
              final isSel = _disposition == disp;
              return ChoiceChip(
                label: Text(disp),
                selected: isSel,
                selectedColor: disp.contains('ICU')
                    ? AppColors.danger
                    : (disp.contains('Ward') ? AppColors.warning : AppColors.success),
                labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.bold),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _disposition = disp;
                      if (!disp.contains('Admit')) {
                        _selectedBed = null;
                      } else if (_selectedBed == null && _bedOptions.isNotEmpty) {
                        _selectedBed = _bedOptions.first;
                      }
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Inpatient Bed Assignment if admitted
          if (isAdmission) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.hotel, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('IPD Admission & Bed Allocation',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBed,
                    decoration: const InputDecoration(labelText: 'Select Inpatient Bed *'),
                    items: _bedOptions.map((b) => DropdownMenuItem(value: b, child: Text('Bed: $b'))).toList(),
                    onChanged: (b) => setState(() => _selectedBed = b),
                  ),
                  const SizedBox(height: 8),
                  const Text('Note: Assigning this bed will automatically update live hospital bed occupancy in Supabase.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Lab Tests Ordered
          TextField(
            controller: _labTestsController,
            decoration: const InputDecoration(
              labelText: 'Diagnostic Lab & Imaging Tests Ordered',
              hintText: 'e.g. Complete Blood Count (CBC), Serum Creatinine, 2D Echo',
              prefixIcon: Icon(Icons.biotech, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 4: SUMMARY & NOTES ---
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Doctor Clinical Summary Notes & Follow-up Advice:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _doctorNotesController,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText:
                  'Enter clinical review notes, lifestyle recommendations, dietary advice, and follow-up consultation timeframe...',
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppColors.infoLight,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(Icons.security, size: 20, color: AppColors.info),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Saving this consultation will sign off the appointment, translate Latin frequencies to clinical directions, update bed occupancy, and register the longitudinal event to the patient dossier.',
                      style: TextStyle(fontSize: 12, color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
