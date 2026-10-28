import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image/image.dart' as image;

import 'firebase_config.dart';

class UserProfile {
  const UserProfile({this.fullName = '', this.phone = '', this.address = ''});

  final String fullName;
  final String phone;
  final String address;

  factory UserProfile.fromDatabase(Object? value) {
    if (value is! Map) return const UserProfile();
    return UserProfile(
      fullName: value['fullName']?.toString() ?? '',
      phone: value['phone']?.toString() ?? '',
      address: value['address']?.toString() ?? '',
    );
  }
}

class FirebaseProfileRepository {
  FirebaseProfileRepository({
    FirebaseDatabase? database,
    FirebaseFirestore? firestore,
  }) : _database =
           database ??
           FirebaseDatabase.instanceFor(
             app: Firebase.app(),
             databaseURL: FirebaseConfig.databaseUrl,
           ),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseDatabase _database;
  final FirebaseFirestore _firestore;

  DatabaseReference _profileRef(String uid) =>
      _database.ref('users/$uid/profile');
  DocumentReference<Map<String, dynamic>> _avatarRef(String uid) =>
      _firestore.collection('avatars').doc(uid);

  Stream<UserProfile> watchProfile(String uid) =>
      _profileRef(uid).onValue
          .map((event) => UserProfile.fromDatabase(event.snapshot.value));

  Future<void> saveProfile(String uid, UserProfile profile) =>
      _profileRef(uid).update({
        'fullName': profile.fullName.trim(),
        'phone': profile.phone.trim(),
        'address': profile.address.trim(),
        'updatedAt': ServerValue.timestamp,
      });

  Stream<Uint8List?> watchAvatar(String uid) =>
      _avatarRef(uid).snapshots().map((snapshot) {
        final data = snapshot.data()?['bytes'];
        return data is Blob ? data.bytes : null;
      });

  Future<void> saveAvatar(String uid, Uint8List originalBytes) async {
    if (originalBytes.lengthInBytes > 10 * 1024 * 1024) {
      throw const FormatException('Ảnh gốc phải nhỏ hơn 10 MB.');
    }
    final decoded = image.decodeImage(originalBytes);
    if (decoded == null) {
      throw const FormatException('Không đọc được ảnh này.');
    }
    final resized = decoded.width >= decoded.height
        ? image.copyResize(decoded, width: 256)
        : image.copyResize(decoded, height: 256);
    final jpeg = Uint8List.fromList(image.encodeJpg(resized, quality: 75));
    if (jpeg.lengthInBytes > 750 * 1024) {
      throw const FormatException(
        'Ảnh sau khi nén vẫn quá lớn. Hãy chọn ảnh khác.',
      );
    }
    await _avatarRef(uid).set({
      'bytes': Blob(jpeg),
      'contentType': 'image/jpeg',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
