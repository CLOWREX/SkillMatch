import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get myUid => _auth.currentUser!.uid;

  String _chatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<void> addMatch(String targetUid) async {
    await _db.collection('users').doc(myUid).set({
      'matches': FieldValue.arrayUnion([targetUid]),
    }, SetOptions(merge: true));
    await _db.collection('users').doc(targetUid).set({
      'matches': FieldValue.arrayUnion([myUid]),
    }, SetOptions(merge: true));
    final chatId = _chatId(myUid, targetUid);
    await _db.collection('chats').doc(chatId).set({
      'participants': [myUid, targetUid],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastTime': FieldValue.serverTimestamp(),
      'unread_$myUid': 0,
      'unread_$targetUid': 0,
    }, SetOptions(merge: true));
  }

  Future<void> toggleFollow(String targetUid) async {
    final myDoc = await _db.collection('users').doc(myUid).get();
    final following = List<String>.from(myDoc.data()?['following'] ?? []);
    if (following.contains(targetUid)) {
      await _db.collection('users').doc(myUid).set({
        'following': FieldValue.arrayRemove([targetUid]),
      }, SetOptions(merge: true));
      await _db.collection('users').doc(targetUid).set({
        'followers': FieldValue.arrayRemove([myUid]),
      }, SetOptions(merge: true));
    } else {
      await _db.collection('users').doc(myUid).set({
        'following': FieldValue.arrayUnion([targetUid]),
      }, SetOptions(merge: true));
      await _db.collection('users').doc(targetUid).set({
        'followers': FieldValue.arrayUnion([myUid]),
      }, SetOptions(merge: true));
    }
  }

  Future<void> toggleLike(String targetUid) async {
    final myDoc = await _db.collection('users').doc(myUid).get();
    final liked = List<String>.from(myDoc.data()?['likedUsers'] ?? []);
    if (liked.contains(targetUid)) {
      await _db.collection('users').doc(myUid).set({
        'likedUsers': FieldValue.arrayRemove([targetUid]),
      }, SetOptions(merge: true));
      await _db.collection('users').doc(targetUid).set({
        'likes': FieldValue.arrayRemove([myUid]),
      }, SetOptions(merge: true));
    } else {
      await _db.collection('users').doc(myUid).set({
        'likedUsers': FieldValue.arrayUnion([targetUid]),
      }, SetOptions(merge: true));
      await _db.collection('users').doc(targetUid).set({
        'likes': FieldValue.arrayUnion([myUid]),
      }, SetOptions(merge: true));
    }
  }

  Stream<List<Map<String, dynamic>>> getMyChats() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .snapshots()
        .asyncMap((snapshot) async {
      final chats = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUid = participants.firstWhere(
          (uid) => uid != myUid,
          orElse: () => '',
        );
        if (otherUid.isEmpty) continue;
        final userDoc = await _db.collection('users').doc(otherUid).get();
        if (!userDoc.exists) continue;
        chats.add({
          'chatId': doc.id,
          'otherUid': otherUid,
          'lastMessage': data['lastMessage'] ?? '',
          'lastTime': data['lastTime'],
          'unreadCount': data['unread_$myUid'] ?? 0,
          ...userDoc.data()!,
          'id': otherUid,
        });
      }
      chats.sort((a, b) {
        final at = a['lastTime'];
        final bt = b['lastTime'];
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return (bt as dynamic).compareTo(at);
      });
      return chats;
    });
  }

  Future<void> sendMessage(String otherUid, String text) async {
    final chatId = _chatId(myUid, otherUid);
    final now = FieldValue.serverTimestamp();
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'from': myUid,
      'text': text,
      'createdAt': now,
    });
    await _db.collection('chats').doc(chatId).set({
      'participants': [myUid, otherUid],
      'lastMessage': text,
      'lastTime': now,
      'unread_$otherUid': FieldValue.increment(1),
      'unread_$myUid': 0,
    }, SetOptions(merge: true));
  }

  Future<void> clearUnread(String otherUid) async {
    final chatId = _chatId(myUid, otherUid);
    await _db.collection('chats').doc(chatId).set(
      {'unread_$myUid': 0},
      SetOptions(merge: true),
    );
  }

  Stream<List<Map<String, dynamic>>> getMessages(String otherUid) {
    final chatId = _chatId(myUid, otherUid);
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}