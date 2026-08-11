import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../providers/app_provider.dart';
import '../../widgets/toast_helper.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _openUserDialog({Map<String, dynamic>? user, String? docId}) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(
        user: user,
        docId: docId,
        onSaved: () => setState(() {}),
      ),
    );
  }

  Future<void> _deleteUser(String docId, String name) async {
    final lp = AppProvider.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lp.t('user.delete')),
        content: Text('${lp.t('user.delete_confirm')} ($name)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(lp.t('user.cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: Text(lp.t('user.delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('users').doc(docId).delete();
      if (mounted) VivumToast.show(context, lp.isAr ? 'تم حذف المستخدم بنجاح' : 'User deleted successfully');
    }
  }

  Future<void> _confirmQuickResetPassword(String email) async {
    final lp = AppProvider.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lp.t('user.reset_pass')),
        content: Text(lp.t('user.reset_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(lp.t('user.cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(lp.t('user.reset_pass')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        if (mounted) VivumToast.show(context, lp.t('user.reset_sent'));
      } catch (e) {
        if (mounted) VivumToast.show(context, 'Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = AppProvider.of(context);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lp.t('dash.users'),
                style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _openUserDialog(),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                label: Text(lp.t('user.add')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text(lp.isAr ? 'لا يوجد مستخدمين حالياً' : 'No users found'));
                  }

                  final users = snapshot.data!.docs;

                  if (isMobile) {
                    return _buildMobileList(users, lp, theme);
                  } else {
                    return _buildDesktopTable(users, lp, theme);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(List<QueryDocumentSnapshot> users, AppProvider lp, ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: users.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final doc = users[index];
        final user = doc.data() as Map<String, dynamic>;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Text(user['name']?[0]?.toUpperCase() ?? '?', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          title: Text(user['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(user['email'] ?? ''),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _openUserDialog(user: user, docId: doc.id)),
              IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => _deleteUser(doc.id, user['name'] ?? '')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(List<QueryDocumentSnapshot> users, AppProvider lp, ThemeData theme) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.05),
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text(lp.t('user.name'), style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Text(lp.t('user.email'), style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text(lp.t('user.role'), style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text(lp.t('user.status'), style: const TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 120, child: Text(lp.t('user.actions'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        // Rows
        Expanded(
          child: ListView.separated(
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = users[index];
              final user = doc.data() as Map<String, dynamic>;
              final isActive = user['isActive'] ?? true;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            child: Text(user['name']?[0]?.toUpperCase() ?? '?', style: TextStyle(color: theme.colorScheme.primary, fontSize: 14)),
                          ),
                          const SizedBox(width: 12),
                          Text(user['name'] ?? ''),
                        ],
                      ),
                    ),
                    Expanded(flex: 3, child: Text(user['email'] ?? '', style: theme.textTheme.bodyMedium)),
                    Expanded(flex: 2, child: _buildRoleBadge(user['role'] ?? 'User', theme, lp)),
                    Expanded(
                      flex: 2,
                      child: Text(
                        isActive ? lp.t('user.active') : lp.t('user.inactive'),
                        style: TextStyle(color: isActive ? Colors.green : Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.vpn_key_outlined, size: 18),
                            tooltip: lp.t('user.reset_pass'),
                            onPressed: () => _confirmQuickResetPassword(user['email']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _openUserDialog(user: user, docId: doc.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                            onPressed: () => _deleteUser(doc.id, user['name'] ?? ''),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role, ThemeData theme, AppProvider lp) {
    final isAdmin = role == 'Admin';
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: (isAdmin ? theme.colorScheme.primary : theme.colorScheme.secondary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isAdmin ? lp.t('user.admin') : lp.t('user.messaging'),
          style: TextStyle(
            color: isAdmin ? theme.colorScheme.primary : theme.colorScheme.secondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class UserFormDialog extends StatefulWidget {
  final Map<String, dynamic>? user;
  final String? docId;
  final VoidCallback onSaved;

  const UserFormDialog({super.key, this.user, this.docId, required this.onSaved});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _passCtrl;
  late TextEditingController _confirmPassCtrl;
  late String _role;
  late bool _isActive;
  bool _loading = false;
  bool _resetLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?['name'] ?? '');
    _emailCtrl = TextEditingController(text: widget.user?['email'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.user?['phone'] ?? '');
    _passCtrl = TextEditingController();
    _confirmPassCtrl = TextEditingController();
    _role = widget.user?['role'] ?? 'Messaging';
    _isActive = widget.user?['isActive'] ?? true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    final lp = AppProvider.of(context);
    try {
      final userData = {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'role': _role,
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.docId == null) {
        try {
          FirebaseApp tempApp = await Firebase.initializeApp(
            name: 'tempApp',
            options: Firebase.app().options,
          );
          FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
          
          await tempAuth.createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
          );
          await tempApp.delete();
        } on FirebaseAuthException catch (e) {
          if (e.code != 'email-already-in-use') rethrow;
        }

        await FirebaseFirestore.instance.collection('users').add({
          ...userData,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance.collection('users').doc(widget.docId).update(userData);
      }

      if (mounted) {
        VivumToast.show(context, lp.isAr ? 'تم حفظ البيانات بنجاح' : 'Data saved successfully');
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) VivumToast.show(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendResetEmail() async {
    final lp = AppProvider.of(context);
    setState(() => _resetLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailCtrl.text.trim());
      if (mounted) {
        Navigator.pop(context);
        VivumToast.show(context, lp.t('user.reset_sent'));
      }
    } catch (e) {
      if (mounted) VivumToast.show(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _resetLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, ThemeData theme, {bool enabled = true}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: theme.colorScheme.primary, size: 20),
      filled: true,
      fillColor: theme.cardTheme.color,
      enabled: enabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = AppProvider.of(context);
    final theme = Theme.of(context);
    final isEdit = widget.docId != null;
    final screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      title: Text(isEdit ? lp.t('user.edit') : lp.t('user.add'), style: const TextStyle(fontWeight: FontWeight.bold)),
      scrollable: true,
      content: SizedBox(
        width: screenWidth > 700 ? 500 : screenWidth * 0.9, 
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: _buildInputDecoration(lp.t('user.name'), Icons.person_outline, theme),
                validator: (v) => v!.isEmpty ? lp.t('user.val.name') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                enabled: !isEdit,
                decoration: _buildInputDecoration(lp.t('user.email'), Icons.email_outlined, theme, enabled: !isEdit),
                validator: (v) => v!.isEmpty ? lp.t('user.val.email') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: _buildInputDecoration(lp.t('user.phone'), Icons.phone_outlined, theme),
              ),
              const SizedBox(height: 16),
              if (!isEdit) ...[
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: _buildInputDecoration(lp.t('user.password'), Icons.lock_outline, theme),
                  validator: (v) => v!.length < 4 ? lp.t('user.val.pass_short') : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: true,
                  decoration: _buildInputDecoration(lp.t('user.confirm_password'), Icons.lock_reset, theme),
                  validator: (v) => v != _passCtrl.text ? lp.t('user.val.pass_match') : null,
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<String>(
                value: _role,
                decoration: _buildInputDecoration(lp.t('user.role'), Icons.security, theme),
                items: [
                  DropdownMenuItem(value: 'Admin', child: Text(lp.t('user.admin'))),
                  DropdownMenuItem(value: 'Messaging', child: Text(lp.t('user.messaging'))),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(lp.t('user.status'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: Text(_isActive ? lp.t('user.active') : lp.t('user.inactive'), style: TextStyle(color: _isActive ? Colors.green : Colors.red, fontSize: 12)),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeColor: theme.colorScheme.primary,
              ),
              if (isEdit) ...[
                const Divider(),
                if (_resetLoading)
                  const CircularProgressIndicator()
                else
                  TextButton.icon(
                    onPressed: _sendResetEmail,
                    icon: const Icon(Icons.mail_outline),
                    label: Text(lp.t('user.reset_pass')),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(lp.t('user.cancel'))),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _loading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
              : Text(lp.t('user.save')),
        ),
      ],
    );
  }
}
