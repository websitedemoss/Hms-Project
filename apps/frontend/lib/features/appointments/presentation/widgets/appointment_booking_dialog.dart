import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../doctors/presentation/providers/doctors_provider.dart';
import '../../../doctors/domain/models/doctor.dart';
import '../../../patients/presentation/providers/patients_provider.dart';
import '../providers/appointments_provider.dart';

class AppointmentBookingDialog extends ConsumerStatefulWidget {
  const AppointmentBookingDialog({super.key});

  @override
  ConsumerState<AppointmentBookingDialog> createState() => _AppointmentBookingDialogState();
}

class _AppointmentBookingDialogState extends ConsumerState<AppointmentBookingDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPatientId;
  Doctor? _selectedDoctor;
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlotTime;
  String _appointmentType = 'Consultation';
  String _priority = 'Normal';
  final _symptomsController = TextEditingController();

  List<DoctorSlotItem> _slots = [];
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;
  String? _slotError;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final patientsState = ref.read(patientsProvider);
      if (patientsState.patients.isNotEmpty) {
        setState(() {
          _selectedPatientId = patientsState.patients.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots() async {
    if (_selectedDoctor == null) return;

    setState(() {
      _isLoadingSlots = true;
      _slotError = null;
      _selectedSlotTime = null;
    });

    try {
      final repo = ref.read(doctorsRepositoryProvider);
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      final res = await repo.fetchAvailableSlots(_selectedDoctor!.id, dateStr);

      if (mounted) {
        setState(() {
          _slots = (res['slots'] as List<dynamic>?)?.cast<DoctorSlotItem>() ?? [];
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _slotError = e.toString().replaceFirst('Exception: ', '');
          _isLoadingSlots = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient')),
      );
      return;
    }
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a doctor')),
      );
      return;
    }
    if (_selectedSlotTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'patientId': _selectedPatientId,
        'doctorId': _selectedDoctor!.id,
        'departmentId': _selectedDoctor!.departmentId,
        'date': _selectedDate.toIso8601String().split('T')[0],
        'slotTime': _selectedSlotTime,
        'type': _appointmentType,
        'priority': _priority,
        'chiefComplaints': _symptomsController.text.trim(),
      };

      final appt = await ref.read(appointmentsProvider.notifier).bookAppointment(data);
      // Also refresh live queue
      ref.read(queueProvider.notifier).loadQueue();

      if (mounted) {
        Navigator.pop(context, appt);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              'Appointment booked successfully! Allocated Token #${appt.tokenNumber}',
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
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientsState = ref.watch(patientsProvider);
    final doctorsAsync = ref.watch(doctorsListProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_month, color: AppColors.primary, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Book Appointment Slot',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Anti-collision scheduling with sequential token allocation',
                  style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Patient Selection
                DropdownButtonFormField<String>(
                  initialValue: _selectedPatientId,
                  decoration: const InputDecoration(
                    labelText: 'Select Patient *',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  items: patientsState.patients.map((p) {
                    return DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.mrn} - ${p.fullName} (${p.phone ?? ""})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedPatientId = val);
                  },
                  validator: (v) => v == null ? 'Patient required' : null,
                ),
                const SizedBox(height: 14),

                // Doctor & Date Selection
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: doctorsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (err, _) => Text('Error: $err', style: const TextStyle(color: AppColors.danger)),
                        data: (doctors) {
                          return DropdownButtonFormField<Doctor>(
                            initialValue: _selectedDoctor,
                            decoration: const InputDecoration(
                              labelText: 'Consultant Doctor *',
                              prefixIcon: Icon(Icons.medical_services_outlined, size: 20),
                            ),
                            items: doctors.map((doc) {
                              return DropdownMenuItem(
                                value: doc,
                                child: Text('${doc.name} (${doc.departmentName ?? "OPD"})'),
                              );
                            }).toList(),
                            onChanged: (doc) {
                              setState(() => _selectedDoctor = doc);
                              _fetchSlots();
                            },
                            validator: (v) => v == null ? 'Doctor required' : null,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 60)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                            _fetchSlots();
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date *',
                            prefixIcon: Icon(Icons.event, size: 20),
                          ),
                          child: Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Available Time Slots Section
                const Text(
                  'Select Available Time Slot *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryLight),
                ),
                const SizedBox(height: 8),

                if (_isLoadingSlots)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_slotError != null)
                  Text(_slotError!, style: const TextStyle(color: AppColors.danger, fontSize: 12))
                else if (_slots.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Text(
                      _selectedDoctor == null
                          ? 'Please select a consultant doctor to view available slots.'
                          : 'No slots configured for this doctor on selected date.',
                      style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _slots.map((slot) {
                      final isSelected = _selectedSlotTime == slot.time;
                      return ChoiceChip(
                        label: Text(
                          slot.isBooked ? '${slot.time} (Booked)' : slot.time,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: slot.isBooked
                                ? AppColors.textSecondaryLight
                                : (isSelected ? Colors.white : AppColors.textPrimaryLight),
                          ),
                        ),
                        selected: isSelected,
                        disabledColor: Colors.grey.shade200,
                        selectedColor: AppColors.primary,
                        onSelected: slot.isBooked
                            ? null
                            : (selected) {
                                setState(() {
                                  _selectedSlotTime = selected ? slot.time : null;
                                });
                              },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),

                // Appointment Type & Priority
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _appointmentType,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: ['Consultation', 'Walk-in', 'Follow-up', 'Emergency']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _appointmentType = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _priority,
                        decoration: const InputDecoration(labelText: 'Priority'),
                        items: ['Normal', 'Urgent', 'Emergency']
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _priority = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Chief Complaints
                TextFormField(
                  controller: _symptomsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Chief Complaints / Symptoms',
                    hintText: 'e.g. Chest pain for 2 days, dyspnea on exertion...',
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size(140, 44)),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Confirm Booking'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
