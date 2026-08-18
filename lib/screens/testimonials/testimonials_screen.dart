import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/testimonial.dart';
import '../../providers/app_provider.dart';
import '../../widgets/toast_helper.dart';
import '../../widgets/error_state_widget.dart';

class TestimonialsManagerScreen extends StatefulWidget {
  const TestimonialsManagerScreen({super.key});

  @override
  State<TestimonialsManagerScreen> createState() => _TestimonialsManagerScreenState();
}

class _TestimonialsManagerScreenState extends State<TestimonialsManagerScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Pending, Approved
  int _ratingFilter = 0; // 0 means no filter, 1-5 for stars

  @override
  Widget build(BuildContext context) {
    final lp = AppProvider.of(context);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lp.t('dash.testimonials'),
          style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        
        // Search and Filters Bar
        _buildFiltersBar(theme, lp),
        
        const SizedBox(height: 32),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('testimonials')
                .orderBy('createdAt', descending: true)
                .snapshots(),
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

              // Apply Search and Filters on the list
              final testimonials = snapshot.data!.docs.map((d) {
                return Testimonial.fromFirestore(d.data() as Map<String, dynamic>, d.id);
              }).where((t) {
                final matchesSearch = t.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                     t.content.toLowerCase().contains(_searchQuery.toLowerCase());
                
                bool matchesStatus = true;
                if (_statusFilter == 'Pending') matchesStatus = t.status == 'pending';
                if (_statusFilter == 'Approved') matchesStatus = t.status == 'approved';

                bool matchesRating = true;
                if (_ratingFilter != 0) matchesRating = t.rating == _ratingFilter;

                return matchesSearch && matchesStatus && matchesRating;
              }).toList();

              if (testimonials.isEmpty) {
                return _buildEmptyState(theme, lp, isFilter: true);
              }

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 1, // 3 cards per row on web, 1 on mobile
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 280, // Fixed height to prevent overflow and maintain consistency
                ),
                itemCount: testimonials.length,
                padding: const EdgeInsets.only(bottom: 100),
                itemBuilder: (context, index) => _TestimonialCard(testimonial: testimonials[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersBar(ThemeData theme, AppProvider lp) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: lp.isAr ? 'بحث بالاسم أو النص...' : 'Search by name or content...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: theme.cardTheme.color,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lp.isAr ? 'الحالة' : 'Status', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterChip('All', lp.isAr ? 'الكل' : 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', lp.isAr ? 'قيد الانتظار' : 'Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Approved', lp.isAr ? 'معتمد' : 'Approved'),
              ],
            ),
          ],
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lp.isAr ? 'التقييم' : 'Rating', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _ratingFilter,
              dropdownColor: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              underline: Container(),
              onChanged: (val) => setState(() => _ratingFilter = val!),
              items: [
                DropdownMenuItem(value: 0, child: Text(lp.isAr ? 'كل النجوم' : 'All Stars')),
                ...List.generate(5, (i) => DropdownMenuItem(
                  value: 5 - i,
                  child: Row(
                    children: [
                      Text('${5 - i}'),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    ],
                  ),
                )),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => _statusFilter = value),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppProvider lp, {bool isFilter = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: theme.hintColor.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            isFilter 
              ? (lp.isAr ? 'لا توجد نتائج تطابق بحثك' : 'No results match your search')
              : (lp.isAr ? 'لا توجد مراجعات حالياً' : 'No testimonials found'),
            style: TextStyle(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final Testimonial testimonial;
  const _TestimonialCard({required this.testimonial});

  Future<void> _updateStatus(BuildContext context, String status) async {
    final lp = AppProvider.of(context);
    try {
      await FirebaseFirestore.instance
          .collection('testimonials')
          .doc(testimonial.id)
          .update({'status': status});
      if (context.mounted) {
        VivumToast.show(context, lp.isAr ? 'تم تحديث الحالة بنجاح' : 'Status updated successfully');
      }
    } catch (e) {
      if (context.mounted) VivumToast.show(context, 'Error: $e', isError: true);
    }
  }

  Future<void> _deleteTestimonial(BuildContext context) async {
    final lp = AppProvider.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(lp.isAr ? 'حذف المراجعة' : 'Delete Testimonial'),
        content: Text(lp.isAr ? 'هل أنت متأكد من حذف هذه المراجعة؟' : 'Are you sure you want to delete this testimonial?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(lp.t('dash.cancel_btn'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: Text(lp.isAr ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('testimonials').doc(testimonial.id).delete();
      if (context.mounted) VivumToast.show(context, lp.isAr ? 'تم الحذف بنجاح' : 'Deleted successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lp = AppProvider.of(context);
    final isApproved = testimonial.status == 'approved';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isApproved ? theme.colorScheme.primary.withValues(alpha: 0.5) : theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    testimonial.name.isNotEmpty ? testimonial.name[0].toUpperCase() : '?', 
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testimonial.name, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(DateFormat('MMM d, yyyy', lp.lang).format(testimonial.createdAt), style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                _buildStatusBadge(isApproved, lp),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) => Icon(
                index < testimonial.rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: Colors.amber,
                size: 18,
              )),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  testimonial.content.isEmpty ? (lp.isAr ? '(بدون نص)' : '(No content)') : testimonial.content, 
                  style: const TextStyle(height: 1.5, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isApproved)
                  _buildActionButton(
                    icon: Icons.check_rounded,
                    label: lp.isAr ? 'اعتماد' : 'Approve',
                    color: Colors.green,
                    onTap: () => _updateStatus(context, 'approved'),
                  ),
                if (isApproved)
                  _buildActionButton(
                    icon: Icons.undo_rounded,
                    label: lp.isAr ? 'تراجع' : 'Undo',
                    color: Colors.orange,
                    onTap: () => _updateStatus(context, 'pending'),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _deleteTestimonial(context),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isApproved, AppProvider lp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isApproved ? Colors.green : Colors.orange).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isApproved ? (lp.isAr ? 'معتمد' : 'Approved') : (lp.isAr ? 'قيد الانتظار' : 'Pending'),
        style: TextStyle(color: isApproved ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
