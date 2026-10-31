import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmTokenService {
  FcmTokenService._();
  static final FcmTokenService instance = FcmTokenService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      return null;
    }
  }

  Future<void> registerToken(String userId) async {
    final token = await getToken();
    if (token == null) return;

    final tokenRef = _db
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .doc(token);

    await tokenRef.set({
      'token': token,
      'platform': 'android',
      'appVersion': '1.0.0',
      'createdAt': FieldValue.serverTimestamp(),
      'lastUsedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateLastUsed(String userId, String token) async {
    final tokenRef = _db
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .doc(token);

    await tokenRef.update({
      'lastUsedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeToken(String userId, String token) async {
    final tokenRef = _db
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .doc(token);

    await tokenRef.delete();
  }

  Future<void> removeAllTokens(String userId) async {
    final tokensSnapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .get();

    final batch = _db.batch();
    for (final doc in tokensSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Stream<String?> get tokenStream => _messaging.onTokenRefresh.asyncMap((token) => token);
}