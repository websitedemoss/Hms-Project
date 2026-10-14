import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/patients_repository.dart';
import '../../domain/models/patient.dart';

final patientsRepositoryProvider = Provider<PatientsRepository>((ref) {
  return PatientsRepository();
});

class PatientsState {
  final List<Patient> patients;
  final int total;
  final int page;
  final int totalPages;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const PatientsState({
    this.patients = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  PatientsState copyWith({
    List<Patient>? patients,
    int? total,
    int? page,
    int? totalPages,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PatientsState(
      patients: patients ?? this.patients,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class PatientsNotifier extends Notifier<PatientsState> {
  late final PatientsRepository _repository;

  @override
  PatientsState build() {
    _repository = ref.watch(patientsRepositoryProvider);
    Future.microtask(() => loadPatients());
    return const PatientsState(isLoading: true);
  }

  Future<void> loadPatients({int? page, String? query}) async {
    final targetPage = page ?? state.page;
    final targetQuery = query ?? state.searchQuery;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final res = await _repository.fetchPatients(
        q: targetQuery,
        page: targetPage,
      );

      state = state.copyWith(
        patients: res['patients'] as List<Patient>,
        total: res['total'] as int,
        page: res['page'] as int,
        totalPages: res['totalPages'] as int,
        searchQuery: targetQuery,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> search(String query) async {
    await loadPatients(page: 1, query: query);
  }

  Future<void> setPage(int page) async {
    if (page < 1 || page > state.totalPages) return;
    await loadPatients(page: page);
  }

  Future<Patient> registerPatient(Map<String, dynamic> data) async {
    final patient = await _repository.createPatient(data);
    await loadPatients(page: 1); // Refresh page 1 to include new patient
    return patient;
  }
}

final patientsProvider = NotifierProvider<PatientsNotifier, PatientsState>(PatientsNotifier.new);

final patientDossierProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final repo = ref.watch(patientsRepositoryProvider);
  return repo.getDossier(id);
});
