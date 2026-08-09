import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/contact_request.dart';
import '../../providers/app_provider.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = AppProvider.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lp.t('dash.messages'), style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 32),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('contact_requests').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final messages = snapshot.data!.docs.map((d) => ContactRequest.fromFirestore(d.data() as Map<String, dynamic>, d.id)).toList();
              
              return ListView.separated(
                itemCount: messages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final m = messages[index];
                  return Card(
                    child: ExpansionTile(
                      leading: const CircleAvatar(child: Icon(Icons.mail_outline)),
                      title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(m.email),
                      trailing: Text(DateFormat('yMMMd').format(m.timestamp)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(m.message, style: const TextStyle(height: 1.6)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
