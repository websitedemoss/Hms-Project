import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/appointments_repository.dart';
import '../../domain/models/appointment.dart';

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  return AppointmentsRepository();
});

class AppointmentsState {
  final List<Appointment> appointments;
  final String selectedDate;
  final bool isLoading;
  final String? errorMessage;

  const AppointmentsState({
    this.appointments = const [],
    required this.selectedDate,
    this.isLoading = false,
    this.errorMessage,
  });

  AppointmentsState copyWith({
    List<Appointment>? appointments,
    String? selectedDate,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AppointmentsState(
      appointments: appointments ?? this.appointments,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AppointmentsNotifier extends Notifier<AppointmentsState> {
  late final AppointmentsRepository _repository;

  @override
  AppointmentsState build() {
    _repository = ref.watch(appointmentsRepositoryProvider);
    final today = DateTime.now().toIso8601String().split('T')[0];
    Future.microtask(() => loadAppointments(today));
    return AppointmentsState(selectedDate: today, isLoading: true);
  }

  Future<void> loadAppointments(String date) async {
    state = state.copyWith(isLoading: true, errorMessage: null, selectedDate: date);
    try {
      final list = await _repository.fetchAppointments(date: date);
      state = state.copyWith(appointments: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<Appointment> bookAppointment(Map<String, dynamic> data) async {
    final created = await _repository.bookAppointment(data);
    await loadAppointments(state.selectedDate);
    return created;
  }
}

final appointmentsProvider =
    NotifierProvider<AppointmentsNotifier, AppointmentsState>(AppointmentsNotifier.new);

// Queue Triage State
class QueueState {
  final List<Appointment> waiting;
  final List<Appointment> inConsultation;
  final List<Appointment> observation;
  final List<Appointment> completed;
  final Map<String, dynamic> counts;
  final bool isLoading;
  final String? errorMessage;

  const QueueState({
    this.waiting = const [],
    this.inConsultation = const [],
    this.observation = const [],
    this.completed = const [],
    this.counts = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  QueueState copyWith({
    List<Appointment>? waiting,
    List<Appointment>? inConsultation,
    List<Appointment>? observation,
    List<Appointment>? completed,
    Map<String, dynamic>? counts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return QueueState(
      waiting: waiting ?? this.waiting,
      inConsultation: inConsultation ?? this.inConsultation,
      observation: observation ?? this.observation,
      completed: completed ?? this.completed,
      counts: counts ?? this.counts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class QueueNotifier extends Notifier<QueueState> {
  late final AppointmentsRepository _repository;

  @override
  QueueState build() {
    _repository = ref.watch(appointmentsRepositoryProvider);
    Future.microtask(() => loadQueue());
    return const QueueState(isLoading: true);
  }

  Future<void> loadQueue([String? date]) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.fetchQueue(date: date);
      state = state.copyWith(
        waiting: res['waiting'] as List<Appointment>,
        inConsultation: res['inConsultation'] as List<Appointment>,
        observation: res['observation'] as List<Appointment>,
        completed: res['completed'] as List<Appointment>,
        counts: res['counts'] as Map<String, dynamic>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> updateStage(
    int id,
    int stage, {
    String? status,
    String? doctorNotes,
  }) async {
    await _repository.updateStage(id, stage, status: status, doctorNotes: doctorNotes);
    await loadQueue();
  }

  Future<Map<String, dynamic>> saveConsultation(
    int appointmentId,
    Map<String, dynamic> data,
  ) async {
    final res = await _repository.saveConsultation(appointmentId, data);
    await loadQueue();
    return res;
  }
}

final queueProvider = NotifierProvider<QueueNotifier, QueueState>(QueueNotifier.new);
