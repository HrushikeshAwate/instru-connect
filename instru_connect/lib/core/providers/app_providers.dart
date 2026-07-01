import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instru_connect/core/services/account_deletion_service.dart';
import 'package:instru_connect/core/services/activity_notification_service.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';
import 'package:instru_connect/core/services/firestore_service.dart';
import 'package:instru_connect/core/services/firestore/batch_services.dart'
    as firestore_batch;
import 'package:instru_connect/core/services/firestore/role_service.dart'
    as firestore_role;
import 'package:instru_connect/core/services/notification_service.dart';
import 'package:instru_connect/core/services/notification_token_service.dart';
import 'package:instru_connect/core/services/push_notification_service.dart';
import 'package:instru_connect/core/services/role_service.dart';
import 'package:instru_connect/core/services/session_cache_service.dart';
import 'package:instru_connect/core/services/storage_service.dart';
import 'package:instru_connect/core/services/theme_controller.dart';
import 'package:instru_connect/features/admin/services/admin_service.dart';
import 'package:instru_connect/features/attendance/services/attendance_service.dart';
import 'package:instru_connect/features/auth/domain/repositories/auth_repository.dart';
import 'package:instru_connect/features/auth/domain/repositories/user_bootstrap_repository.dart';
import 'package:instru_connect/features/batches/services/batch_service.dart';
import 'package:instru_connect/features/complaints/services/complaint_service.dart';
import 'package:instru_connect/features/events/services/events_service.dart';
import 'package:instru_connect/features/legal/services/legal_acceptance_service.dart';
import 'package:instru_connect/features/notices/services/notice_service.dart';
import 'package:instru_connect/features/profile/services/achievement_service.dart';
import 'package:instru_connect/features/profile/services/profile_service.dart';
import 'package:instru_connect/features/resources/services/resource_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firebaseFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final firebaseMessagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthService());

final authServiceProvider = authRepositoryProvider;

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

final userBootstrapRepositoryProvider = Provider<UserBootstrapRepository>(
  (ref) => FirestoreService(),
);

final firestoreServiceProvider = userBootstrapRepositoryProvider;

final roleServiceProvider = Provider<RoleService>((ref) => RoleService());

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final activityNotificationServiceProvider =
    Provider<ActivityNotificationService>(
      (ref) => ActivityNotificationService(),
    );

final accountDeletionServiceProvider = Provider<AccountDeletionService>(
  (ref) => AccountDeletionService(),
);

final notificationTokenServiceProvider = Provider<NotificationTokenService>(
  (ref) => NotificationTokenService(),
);

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) => PushNotificationService(),
);

final sessionCacheServiceProvider = Provider<SessionCacheService>(
  (ref) => SessionCacheService.instance,
);

final themeControllerProvider = Provider<ThemeController>(
  (ref) => ThemeController.instance,
);

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

final attendanceServiceProvider = Provider<AttendanceService>(
  (ref) => AttendanceService(),
);

final batchServiceProvider = Provider<BatchService>((ref) => BatchService());

final firestoreBatchServiceProvider = Provider<firestore_batch.BatchService>(
  (ref) => firestore_batch.BatchService(),
);

final firestoreRoleServiceProvider = Provider<firestore_role.RoleService>(
  (ref) => firestore_role.RoleService(),
);

final complaintServiceProvider = Provider<ComplaintService>(
  (ref) => ComplaintService(),
);

final eventServiceProvider = Provider<EventService>((ref) => EventService());

final legalAcceptanceServiceProvider = Provider<LegalAcceptanceService>(
  (ref) => LegalAcceptanceService(),
);

final noticeServiceProvider = Provider<NoticeService>((ref) => NoticeService());

final achievementServiceProvider = Provider<AchievementService>(
  (ref) => AchievementService(),
);

final profileServiceProvider = Provider<ProfileService>(
  (ref) => ProfileService(),
);

final resourceServiceProvider = Provider<ResourceService>(
  (ref) => ResourceService(),
);
