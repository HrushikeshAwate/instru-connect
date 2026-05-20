import 'package:cloud_functions/cloud_functions.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';

class AccountDeletionService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> deleteCurrentAccount() async {
    final callable = _functions.httpsCallable('deleteOwnAccount');
    await callable.call<void>();
    await AuthService().signOut();
  }
}
