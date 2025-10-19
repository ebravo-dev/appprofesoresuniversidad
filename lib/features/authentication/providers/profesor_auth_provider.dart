import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/profesor.dart';
import '../../../shared/models/grupo.dart';
import '../../../services/api_service.dart';
import '../../../core/utils/utils.dart';

/// Estado de la autenticación del profesor
enum ProfesorAuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Estado del profesor autenticado
class ProfesorAuthState {
  final ProfesorAuthStatus status;
  final Profesor? profesor;
  final List<Grupo> grupos;
  final String? token;
  final String? errorMessage;

  const ProfesorAuthState({
    this.status = ProfesorAuthStatus.initial,
    this.profesor,
    this.grupos = const [],
    this.token,
    this.errorMessage,
  });

  ProfesorAuthState copyWith({
    ProfesorAuthStatus? status,
    Profesor? profesor,
    List<Grupo>? grupos,
    String? token,
    String? errorMessage,
  }) {
    return ProfesorAuthState(
      status: status ?? this.status,
      profesor: profesor ?? this.profesor,
      grupos: grupos ?? this.grupos,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isAuthenticated =>
      status == ProfesorAuthStatus.authenticated && profesor != null;
  bool get isLoading => status == ProfesorAuthStatus.loading;
  bool get hasError => status == ProfesorAuthStatus.error;
}

/// Provider del servicio de API
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Notifier para manejar la autenticación del profesor
class ProfesorAuthNotifier extends StateNotifier<ProfesorAuthState> {
  final ApiService _apiService;

  ProfesorAuthNotifier(this._apiService) : super(const ProfesorAuthState());

  /// Registrar un nuevo profesor
  Future<void> register(String name, String email, String password) async {
    try {
      Logger.info('Iniciando registro del profesor con email: $email');
      state = state.copyWith(
        status: ProfesorAuthStatus.loading,
        errorMessage: null,
      );

      final result = await _apiService.registerProfesor(
        name: name,
        email: email,
        password: password,
      );

      result.fold(
        (error) {
          Logger.error('Error en registro: $error');
          state = state.copyWith(
            status: ProfesorAuthStatus.error,
            errorMessage: error,
          );
        },
        (loginResponse) async {
          Logger.info(
            'Registro exitoso para: ${loginResponse.profesor.nombreCompleto}',
          );

          state = state.copyWith(
            status: ProfesorAuthStatus.authenticated,
            profesor: loginResponse.profesor,
            token: loginResponse.token,
          );

          // Cargar grupos del profesor
          await _loadGrupos();
        },
      );
    } catch (e, stackTrace) {
      Logger.error('Error inesperado en registro', e, stackTrace);
      state = state.copyWith(
        status: ProfesorAuthStatus.error,
        errorMessage: 'Error inesperado durante el registro',
      );
    }
  }

  /// Iniciar sesión del profesor
  Future<void> login(String email, String password) async {
    try {
      Logger.info('Iniciando login del profesor con email: $email');
      state = state.copyWith(
        status: ProfesorAuthStatus.loading,
        errorMessage: null,
      );

      final result = await _apiService.loginProfesor(
        email: email,
        password: password,
      );

      result.fold(
        (error) {
          Logger.error('Error en login: $error');
          state = state.copyWith(
            status: ProfesorAuthStatus.error,
            errorMessage: error,
          );
        },
        (loginResponse) async {
          Logger.info(
            'Login exitoso para: ${loginResponse.profesor.nombreCompleto}',
          );

          state = state.copyWith(
            status: ProfesorAuthStatus.authenticated,
            profesor: loginResponse.profesor,
            token: loginResponse.token,
          );

          // Cargar grupos del profesor
          await _loadGrupos();
        },
      );
    } catch (e, stackTrace) {
      Logger.error('Error inesperado en login', e, stackTrace);
      state = state.copyWith(
        status: ProfesorAuthStatus.error,
        errorMessage: 'Error inesperado durante el login',
      );
    }
  }

  /// Cargar grupos del profesor autenticado
  Future<void> _loadGrupos() async {
    if (state.profesor == null || state.token == null) return;

    try {
      Logger.info('Cargando clases del profesor: ${state.profesor!.id}');

      final result = await _apiService.getGruposProfesor(state.token!);

      result.fold(
        (error) {
          Logger.error('Error cargando clases: $error');
          // No cambiar el estado de autenticación, solo log del error
        },
        (grupos) {
          Logger.info('Clases cargadas exitosamente: ${grupos.length} clases');
          state = state.copyWith(grupos: grupos);
        },
      );
    } catch (e, stackTrace) {
      Logger.error('Error inesperado cargando clases', e, stackTrace);
    }
  }

  /// Refrescar grupos del profesor
  Future<void> refreshGrupos() async {
    if (!state.isAuthenticated) return;
    await _loadGrupos();
  }

  /// Cerrar sesión
  void logout() {
    Logger.info('Cerrando sesión del profesor');
    state = const ProfesorAuthState(status: ProfesorAuthStatus.unauthenticated);
  }

  /// Limpiar error
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(
        status: state.profesor != null
            ? ProfesorAuthStatus.authenticated
            : ProfesorAuthStatus.unauthenticated,
        errorMessage: null,
      );
    }
  }
}

/// Provider del estado de autenticación del profesor
final profesorAuthProvider =
    StateNotifierProvider<ProfesorAuthNotifier, ProfesorAuthState>((ref) {
      final apiService = ref.watch(apiServiceProvider);
      return ProfesorAuthNotifier(apiService);
    });

/// Provider para verificar si el profesor está autenticado
final isProfesorAuthenticatedProvider = Provider<bool>((ref) {
  final state = ref.watch(profesorAuthProvider);
  return state.isAuthenticated;
});

/// Provider para obtener el profesor actual
final currentProfesorProvider = Provider<Profesor?>((ref) {
  final state = ref.watch(profesorAuthProvider);
  return state.profesor;
});

/// Provider para obtener los grupos del profesor actual
final profesorGruposProvider = Provider<List<Grupo>>((ref) {
  final state = ref.watch(profesorAuthProvider);
  return state.grupos;
});

/// Provider para obtener el estado de carga
final profesorAuthLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(profesorAuthProvider);
  return state.isLoading;
});

/// Provider para obtener el error actual
final profesorAuthErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(profesorAuthProvider);
  return state.errorMessage;
});
