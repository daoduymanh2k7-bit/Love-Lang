// lib/core/constants/firestore_paths.dart
// Tập trung tất cả đường dẫn Firestore vào một nơi.
// Giúp tránh typo và dễ refactor khi cần đổi tên collection.

abstract final class FirestorePaths {
  // ─── Collections ──────────────────────────────────────────────────────────
  static const String users = 'users';
  static const String couples = 'couples';
  static const String invites = 'invites';
  static const String chats = 'chats';
  static const String diaries = 'diaries';
  static const String albums = 'albums';

  // ─── Document Paths (Helpers) ──────────────────────────────────────────────
  static String userDoc(String uid) => '$users/$uid';
  static String coupleDoc(String coupleId) => '$couples/$coupleId';
  static String inviteDoc(String inviteId) => '$invites/$inviteId';

  // ─── Subcollections ────────────────────────────────────────────────────────
  static String messages(String coupleId) => '$chats/$coupleId/messages';
  static String diaryEntries(String coupleId) => '$diaries/$coupleId/entries';
  static String photos(String coupleId) => '$albums/$coupleId/photos';
  static String milestones(String coupleId) => '$couples/$coupleId/milestones';
  static String bucketItems(String coupleId) => '$couples/$coupleId/bucketItems';

  // ─── Field Names: Invite Document ─────────────────────────────────────────
  static const String inviteCode = 'code';
  static const String inviteStatus = 'status';
  static const String inviteCreatorUid = 'creatorUid';
  static const String inviteCreatedAt = 'createdAt';
  static const String inviteExpiresAt = 'expiresAt';

  // ─── Field Names: Couple Document ─────────────────────────────────────────
  static const String coupleUid1 = 'uid1';
  static const String coupleUid2 = 'uid2';
  static const String couplePairedAt = 'pairedAt';
  static const String coupleStatus = 'status';
  static const String coupleNudgeCount = 'nudgeCount';

  // ─── Field Names: User Document ───────────────────────────────────────────
  static const String userCoupleId = 'coupleId';
  static const String userPairingStatus = 'pairingStatus';

  // ─── Invite Status Values ──────────────────────────────────────────────────
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusExpired = 'expired';

  // ─── Couple Status Values ──────────────────────────────────────────────────
  static const String coupleStatusActive = 'active';
  static const String coupleStatusUnpaired = 'unpaired';

  // ─── User Pairing Status Values ───────────────────────────────────────────
  static const String pairingStatusNone = 'none';
  static const String pairingStatusPaired = 'paired';
}
