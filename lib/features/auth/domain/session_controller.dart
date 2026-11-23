import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/user_model.dart';
import '../data/auth_repository.dart';

enum SessionStatus { unknown, unauthenticated, authenticated }

class SessionState {
  final SessionStatus status;
  final UserModel? user;
  const SessionState(this.status, [this.user]);

  bool get isClientMode => user?.activeRole != UserRole.technician;
}

/// Fuente de verdad de la sesión y del modo activo (cliente/técnico).
class SessionController extends StateNotifier<SessionState> {
  SessionController(this._repo)
      : super(const SessionState(SessionStatus.unknown)) {
    _restore();
  }

  final AuthRepository _repo;

  Future<void> _restore() async {
    try {
      final user = await _repo.me();
      state = user == null
          ? const SessionState(SessionStatus.unauthenticated)
          : SessionState(SessionStatus.authenticated, user);
    } catch (e) {
      final err = ApiException.from(e);
      // Sin red conservamos los tokens y dejamos reintentar desde login.
      state = const SessionState(SessionStatus.unauthenticated);
      if (!err.isNetwork) await _repo.logout().catchError((_) {});
    }
  }

  /// Aplica el usuario autenticado y, si eligió otro modo y lo tiene, cambia.
  /// Devuelve false si pidió modo técnico y la cuenta no lo tiene.
  Future<bool> signedIn(UserModel user, UserRole desired) async {
    var u = user;
    var ok = true;
    if (desired != u.activeRole) {
      if (u.roles.contains(desired)) {
        u = await _repo.switchMode(desired);
      } else {
        ok = false;
      }
    }
    state = SessionState(SessionStatus.authenticated, u);
    return ok;
  }

  Future<void> switchMode(UserRole role,
      {Map<String, dynamic>? businessData}) async {
    final u = await _repo.switchMode(role, businessData: businessData);
    state = SessionState(SessionStatus.authenticated, u);
  }

  /// Actualiza la cuenta en el servidor (p. ej. país e idioma) y refleja el
  /// usuario devuelto, para que pagos y moneda sigan al país de la cuenta.
  Future<void> updateAccount(Map<String, dynamic> fields) async {
    final updated = await _repo.updateMe(fields);
    final current = state.user;
    if (updated == null || current == null) return;
    state = SessionState(SessionStatus.authenticated,
        updated.copyWith(activeRole: current.activeRole));
  }

  Future<void> logout() async {
    await _repo.logout().catchError((_) {});
    state = const SessionState(SessionStatus.unauthenticated);
  }

  void expired() {
    state = const SessionState(SessionStatus.unauthenticated);
  }
}

final sessionProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
  final controller = SessionController(ref.watch(authRepositoryProvider));
  ref.listen<int>(sessionExpiredProvider, (_, __) => controller.expired());
  return controller;
});

final currentUserProvider =
    Provider<UserModel?>((ref) => ref.watch(sessionProvider).user);
