import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/user_provider.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = AppProvider.of(context);
    final theme = Theme.of(context);
    final userName = Provider.of<UserProvider>(context).userName;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1000;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lp.t('dash.welcome')} $userName',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy', lp.lang).format(DateTime.now()),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Grid
          GridView.count(
            crossAxisCount: screenWidth > 1200 ? 3 : (screenWidth > 800 ? 2 : 1),
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: screenWidth > 1200 ? 1.8 : 1.6,
            children: [
              _StatCard(
                title: lp.t('dash.total_projects'),
                stream: FirebaseFirestore.instance.collection('projects').snapshots(),
                icon: Icons.rocket_launch_outlined,
                color: theme.colorScheme.primary,
                sparklineData: [0.2, 0.5, 0.4, 0.8, 0.6, 0.9, 0.7],
              ),
              _StatCard(
                title: lp.t('dash.total_messages'),
                stream: FirebaseFirestore.instance.collection('contact_requests').snapshots(),
                icon: Icons.chat_bubble_outline_rounded,
                color: Colors.orangeAccent,
                sparklineData: [0.4, 0.3, 0.6, 0.5, 0.8, 0.4, 0.9],
              ),
              _StatCard(
                title: lp.t('dash.total_users'),
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                icon: Icons.people_outline_rounded,
                color: Colors.purpleAccent,
                sparklineData: [0.1, 0.3, 0.5, 0.4, 0.7, 0.8, 1.0],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Main Layout: Responsive Row or Column
          Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent Activity Section
              Expanded(
                flex: isDesktop ? 3 : 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lp.t('dash.recent_activity'),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildActivitySection(theme, lp),
                  ],
                ),
              ),
              if (isDesktop) const SizedBox(width: 24),
              if (!isDesktop) const SizedBox(height: 32),
              
              // Quick Actions Section (Always visible now)
              Expanded(
                flex: isDesktop ? 1 : 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lp.t('dash.quick_actions'),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _QuickActionTile(
                      icon: Icons.add_rounded,
                      title: lp.t('dash.add_project_btn'),
                      onTap: () => context.go('/projects'),
                      color: theme.colorScheme.primary,
                    ),
                    _QuickActionTile(
                      icon: Icons.person_add_outlined,
                      title: lp.t('user.add'),
                      onTap: () => context.go('/users'),
                      color: Colors.greenAccent,
                    ),
                    _QuickActionTile(
                      icon: Icons.message_outlined,
                      title: lp.t('dash.view_messages_btn'),
                      onTap: () => context.go('/messages'),
                      color: Colors.orangeAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(ThemeData theme, AppProvider lp) {
    return Column(
      children: [
        // Performance Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lp.isAr ? 'الأداء الأسبوعي' : 'Weekly Performance', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Icon(Icons.insights_rounded, color: theme.colorScheme.primary),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _ActivityChartPainter(
                      color: theme.colorScheme.primary,
                      isDark: theme.brightness == Brightness.dark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Real Activity Feed
        Align(
          alignment: lp.isAr ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            lp.isAr ? 'آخر الرسائل المستلمة' : 'Latest Messages',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('contact_requests')
              .orderBy('createdAt', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Text('No recent activity');
            
            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orangeAccent.withOpacity(0.1),
                      child: const Icon(Icons.mail_outline, color: Colors.orangeAccent, size: 20),
                    ),
                    title: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(data['message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text(
                      data['createdAt'] != null ? DateFormat('HH:mm', lp.lang).format((data['createdAt'] as Timestamp).toDate()) : '--:--',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Stream<QuerySnapshot> stream;
  final IconData icon;
  final Color color;
  final List<double> sparklineData;

  const _StatCard({
    required this.title,
    required this.stream,
    required this.icon,
    required this.color,
    required this.sparklineData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Icon(Icons.trending_up, color: Colors.green, size: 20),
            ],
          ),
          const Spacer(),
          StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Text(
                '$count',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              );
            },
          ),
          Text(
            title, 
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          // Mini Chart
          SizedBox(
            height: 30,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(data: sparklineData, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionTile({required this.icon, required this.title, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// Lightweight Chart Painter for mini charts
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Lightweight Painter for Large Activity Chart
class _ActivityChartPainter extends CustomPainter {
  final Color color;
  final bool isDark;
  _ActivityChartPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final data = [0.4, 0.6, 0.5, 0.8, 0.7, 0.9, 0.85];
    final stepX = size.width / (data.length - 1);

    path.moveTo(0, size.height - (data[0] * size.height));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height - (data[0] * size.height));

    for (var i = 1; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * size.height);
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw Grid Lines (Lightly)
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.05)
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = i * (size.height / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
