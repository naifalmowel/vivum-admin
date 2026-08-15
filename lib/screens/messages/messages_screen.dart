import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/contact_request.dart';
import '../../providers/app_provider.dart';
import '../../widgets/toast_helper.dart';
import '../../widgets/error_state_widget.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _filter = 'All'; // All, Unread, Replied

  @override
  Widget build(BuildContext context) {
    final lp = AppProvider.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              lp.t('dash.messages'),
              style: theme.textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(lp.t('msg.filter_all'), 'All'),
              const SizedBox(width: 8),
              _buildFilterChip(lp.t('msg.filter_unread'), 'Unread'),
              const SizedBox(width: 8),
              _buildFilterChip(lp.t('msg.filter_replied'), 'Replied'),
            ],
          ),
        ),
        const SizedBox(height: 32),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getFilteredStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorStateWidget(
                  errorMessage: snapshot.error.toString(),
                  onRetry: () => setState(() {}),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(theme, lp);
              }

              final messages = snapshot.data!.docs.map((d) {
                return ContactRequest.fromFirestore(
                    d.data() as Map<String, dynamic>, d.id);
              }).toList();

              return ListView.separated(
                itemCount: messages.length,
                padding: const EdgeInsets.only(bottom: 100),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) =>
                    _MessageCard(message: messages[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => _filter = value),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: theme.colorScheme.primary,
    );
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    var query = FirebaseFirestore.instance
        .collection('contact_requests')
        .orderBy('createdAt', descending: true);

    if (_filter == 'Unread') {
      query = query.where('isRead', isEqualTo: false);
    } else if (_filter == 'Replied') {
      query = query.where('isReplied', isEqualTo: true);
    }

    return query.snapshots();
  }

  Widget _buildEmptyState(ThemeData theme, AppProvider lp) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline_rounded,
              size: 80, color: theme.hintColor.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            lp.isAr ? 'لا توجد رسائل حالياً' : 'No messages found',
            style: TextStyle(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final ContactRequest message;

  const _MessageCard({required this.message});

  Future<void> _updateStatus(String field, bool value) async {
    await FirebaseFirestore.instance
        .collection('contact_requests')
        .doc(message.id)
        .update({field: value});
  }

  Future<void> _deleteMessage(BuildContext context) async {
    final lp = AppProvider.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(lp.t('user.delete')),
        content: Text(lp.t('user.delete_confirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(lp.t('user.cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            child: Text(lp.t('user.delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('contact_requests')
          .doc(message.id)
          .delete();
      if (context.mounted) {
        VivumToast.show(
            context, lp.isAr ? 'تم حذف الرسالة بنجاح' : 'Message deleted');
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    VivumToast.show(context, '$label copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lp = AppProvider.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: message.isRead
              ? theme.colorScheme.outline
              : theme.colorScheme.primary.withValues(alpha: 0.5),
          width: message.isRead ? 1 : 2,
        ),
      ),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (expanded && !message.isRead) {
            _updateStatus('isRead', true);
          }
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor:
                  (message.isRead ? Colors.grey : theme.colorScheme.primary)
                      .withValues(alpha: 0.1),
              child: Icon(
                  message.isReplied
                      ? Icons.done_all_rounded
                      : Icons.email_outlined,
                  color:
                      message.isRead ? Colors.grey : theme.colorScheme.primary,
                  size: 20),
            ),
            if (!message.isRead)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.cardColor, width: 2))),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
                child: Text(message.name,
                    style: TextStyle(
                        fontWeight:
                            message.isRead ? FontWeight.bold : FontWeight.w900,
                        fontSize: 16))),
            if (message.isReplied)
              _buildSmallBadge(lp.t('msg.replied'), Colors.green, theme),
          ],
        ),
        subtitle: Text(message.email, style: theme.textTheme.bodySmall),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(DateFormat('MMM d, yyyy', lp.lang).format(message.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(DateFormat('HH:mm', lp.lang).format(message.createdAt),
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Badges & Actions
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (message.company.isNotEmpty)
                            _buildBadge(Icons.business, message.company,
                                Colors.blueGrey, theme),
                          _buildBadge(
                              Icons.settings_suggest_outlined,
                              message.service,
                              theme.colorScheme.primary,
                              theme),
                          if (message.phone.isNotEmpty)
                            _buildBadge(Icons.phone_android_rounded,
                                message.phone, Colors.orangeAccent, theme),
                        ],
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent),
                        onPressed: () => _deleteMessage(context)),
                  ],
                ),
                const Divider(height: 32),

                // Contact Actions
                Row(
                  children: [
                    _buildActionButton(
                        Icons.copy_rounded,
                        lp.t('msg.copy_email'),
                        () => _copyToClipboard(context, message.email, 'Email'),
                        theme),
                    const SizedBox(width: 12),
                    if (message.phone.isNotEmpty)
                      _buildActionButton(
                          Icons.copy_rounded,
                          lp.t('msg.copy_phone'),
                          () =>
                              _copyToClipboard(context, message.phone, 'Phone'),
                          theme),
                  ],
                ),
                const SizedBox(height: 24),

                Text('${lp.t('msg.from')}: ',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                SelectableText(message.message,
                    style: const TextStyle(height: 1.8, fontSize: 15)),
                const SizedBox(height: 32),

                // Final Actions
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () =>
                          _updateStatus('isReplied', !message.isReplied),
                      icon: Icon(
                          message.isReplied
                              ? Icons.undo_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 18),
                      label: Text(message.isReplied
                          ? lp.isAr
                              ? 'تراجع عن تم الرد'
                              : 'Undo Replied'
                          : lp.t('msg.mark_replied')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            message.isReplied ? Colors.grey : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        // In a real app, use url_launcher to open mailto:
                      },
                      icon: const Icon(Icons.reply_rounded, size: 18),
                      label:
                          Text(lp.isAr ? 'رد عبر الإيميل' : 'Reply via Email'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
      IconData icon, String label, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(String label, Color color, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onTap, ThemeData theme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon, size: 14, color: theme.hintColor),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12, color: theme.hintColor)),
          ],
        ),
      ),
    );
  }
}
