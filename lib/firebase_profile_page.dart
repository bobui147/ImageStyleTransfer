import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_messaging_service.dart';
import 'firebase_profile_repository.dart';

class FirebaseProfilePage extends StatefulWidget {
  const FirebaseProfilePage({super.key, required this.user});

  final User user;

  @override
  State<FirebaseProfilePage> createState() => _FirebaseProfilePageState();
}

class _FirebaseProfilePageState extends State<FirebaseProfilePage> {
  final _repository = FirebaseProfileRepository();
  final _messaging = FirebaseMessagingService();
  String? _fcmToken;
  String? _fcmError;
  String? _lastNotification;
  bool _avatarBusy = false;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMessaging());
  }

  @override
  void dispose() {
    _messaging.stop();
    super.dispose();
  }

  Future<void> _startMessaging() async {
    try {
      final token = await _messaging.start(
        uid: widget.user.uid,
        onToken: (token) {
          if (mounted) {
            setState(() {
              _fcmToken = token;
              _fcmError = null;
            });
          }
        },
        onNotification: _onNotification,
        onError: (error) {
          if (mounted) setState(() => _fcmError = error.toString());
        },
      );
      if (mounted && token == null) {
        setState(
          () => _fcmError = 'Firebase chưa cấp FCM Token cho thiết bị này.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _fcmError = e.toString());
    }
  }

  void _onNotification(RemoteMessage message) {
    if (!mounted) return;
    final title = message.notification?.title ?? 'Thông báo mới';
    final body = message.notification?.body ?? message.data.toString();
    setState(() => _lastNotification = '$title\n$body');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$title: $body')));
  }

  Future<void> _changeAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() => _avatarBusy = true);
    try {
      await _repository.saveAvatar(widget.user.uid, await picked.readAsBytes());
      if (mounted) _showMessage('Đã cập nhật avatar trên Firestore.');
    } catch (e) {
      if (mounted) _showMessage('Không lưu được avatar: $e');
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await _messaging.signOut(widget.user.uid);
    } catch (_) {
      // The local session must still be closed if token cleanup is unavailable.
    } finally {
      await FirebaseAuth.instance.signOut();
      if (mounted) setState(() => _signingOut = false);
    }
  }

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    StreamBuilder<Uint8List?>(
                      stream: _repository.watchAvatar(widget.user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const CircleAvatar(
                            radius: 48,
                            child: Icon(Icons.error_outline),
                          );
                        }
                        final avatar = snapshot.data;
                        return CircleAvatar(
                          radius: 48,
                          backgroundImage: avatar == null
                              ? null
                              : MemoryImage(avatar),
                          child: avatar == null
                              ? const Icon(Icons.person, size: 48)
                              : null,
                        );
                      },
                    ),
                    TextButton.icon(
                      onPressed: _avatarBusy ? null : _changeAvatar,
                      icon: _avatarBusy
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined),
                      label: const Text('Đổi avatar'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.user.email ?? '',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UID: ${widget.user.uid}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Divider(height: 32),
                    StreamBuilder<UserProfile>(
                      stream: _repository.watchProfile(widget.user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            'Không đọc được profile: ${snapshot.error}',
                          );
                        }
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final profile = snapshot.data!;
                        return Column(
                          children: [
                            _infoRow(
                              Icons.badge_outlined,
                              'Họ tên',
                              profile.fullName,
                            ),
                            _infoRow(
                              Icons.phone_outlined,
                              'Số điện thoại',
                              profile.phone,
                            ),
                            _infoRow(
                              Icons.home_outlined,
                              'Địa chỉ',
                              profile.address,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => EditFirebaseProfilePage(
                                    uid: widget.user.uid,
                                    initial: profile,
                                    repository: _repository,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Cập nhật thông tin'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase Cloud Messaging',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_fcmToken != null) ...[
                      Text(
                        'FCM Token: ${_fcmToken!.substring(0, _fcmToken!.length.clamp(0, 28))}…',
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: _fcmToken!),
                          );
                          if (context.mounted) {
                            _showMessage('Đã sao chép FCM Token.');
                          }
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text(
                          'Sao chép token để gửi thông báo thử',
                        ),
                      ),
                    ] else ...[
                      Text(
                        _fcmError ?? 'Đang đăng ký thiết bị nhận thông báo…',
                      ),
                      if (_fcmError != null)
                        TextButton(
                          onPressed: _startMessaging,
                          child: const Text('Thử lại'),
                        ),
                    ],
                    if (_lastNotification != null) ...[
                      const Divider(),
                      Text('Thông báo gần nhất:\n$_lastNotification'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _signingOut ? null : _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, size: 21),
        const SizedBox(width: 12),
        SizedBox(width: 110, child: Text(label)),
        Expanded(child: Text(value.isEmpty ? 'Chưa cập nhật' : value)),
      ],
    ),
  );
}

class EditFirebaseProfilePage extends StatefulWidget {
  const EditFirebaseProfilePage({
    super.key,
    required this.uid,
    required this.initial,
    required this.repository,
  });

  final String uid;
  final UserProfile initial;
  final FirebaseProfileRepository repository;

  @override
  State<EditFirebaseProfilePage> createState() =>
      _EditFirebaseProfilePageState();
}

class _EditFirebaseProfilePageState extends State<EditFirebaseProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial.fullName);
  late final _phone = TextEditingController(text: widget.initial.phone);
  late final _address = TextEditingController(text: widget.initial.address);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveProfile(
        widget.uid,
        UserProfile(
          fullName: _name.text,
          phone: _phone.text,
          address: _address.text,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = 'Không lưu được profile: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cập nhật profile')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Họ tên'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập họ tên'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập số điện thoại'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Địa chỉ'),
                  maxLines: 2,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập địa chỉ'
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const CircularProgressIndicator()
                      : const Text('Lưu thông tin'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
