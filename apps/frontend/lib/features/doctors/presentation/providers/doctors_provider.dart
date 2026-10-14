import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/doctors_repository.dart';
import '../../domain/models/doctor.dart';

final doctorsRepositoryProvider = Provider<DoctorsRepository>((ref) {
  return DoctorsRepository();
});

final doctorsListProvider = FutureProvider<List<Doctor>>((ref) async {
  final repo = ref.watch(doctorsRepositoryProvider);
  return repo.fetchDoctors();
});
