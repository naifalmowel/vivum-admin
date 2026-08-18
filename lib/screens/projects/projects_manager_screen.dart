import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/app_provider.dart';
import '../../widgets/toast_helper.dart';
import '../../widgets/error_state_widget.dart';

class ProjectsManagerScreen extends StatefulWidget {
  const ProjectsManagerScreen({super.key});

  @override
  State<ProjectsManagerScreen> createState() => _ProjectsManagerScreenState();
}

class _ProjectsManagerScreenState extends State<ProjectsManagerScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Branding', 'Web', 'App', 'AI'];

  void _openProjectForm({Map<String, dynamic>? project, String? docId}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProjectFormDialog(
        project: project,
        docId: docId,
        onSaved: () => setState(() {}),
      ),
    );
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
                lp.t('dash.projects'),
                style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _openProjectForm(),
                icon: const Icon(Icons.add_to_photos_rounded, size: 20),
                label: Text(lp.t('proj.add')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedCategory = cat),
                    selectedColor: theme.colorScheme.primary.withValues(alpha:0.2),
                    checkmarkColor: theme.colorScheme.primary,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedCategory == 'All'
                  ? FirebaseFirestore.instance.collection('projects').snapshots()
                  : FirebaseFirestore.instance.collection('projects').where('category', isEqualTo: _selectedCategory).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorStateWidget(
                    errorMessage: snapshot.error.toString(),
                    onRetry: () => setState(() {}),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No projects found.'));

                final projects = snapshot.data!.docs;

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: screenWidth > 1400 ? 4 : (screenWidth > 1000 ? 3 : (screenWidth > 600 ? 2 : 1)),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    mainAxisExtent: isMobile ? 140 : 380, // تحديد الارتفاع بدقة
                  ),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final doc = projects[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _ProjectCard(
                      data: data,
                      docId: doc.id,
                      isMobile: isMobile,
                      onEdit: () => _openProjectForm(project: data, docId: doc.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isMobile;
  final VoidCallback onEdit;

  const _ProjectCard({required this.data, required this.docId, required this.onEdit, this.isMobile = false});

  void _showFullImage(BuildContext context, List<dynamic> urls) {
    if (urls.isEmpty) {
      VivumToast.show(context, 'لا توجد صور لهذا المشروع', isError: true);
      return;
    }

    final PageController controller = PageController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.black.withValues(alpha: 0.1), // خلفية سوداء شفافة فخمة
            insetPadding: EdgeInsets.zero,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Close by clicking background
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(color: Colors.transparent),
                ),
                
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: controller,
                    itemCount: urls.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) => InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: Image.network(
                          urls[index],
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator(color: Colors.white24));
                          },
                          errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
                        ),
                      ),
                    ),
                  ),
                ),

                // Navigation Arrows
                if (urls.length > 1) ...[
                  Positioned(
                    left: 20,
                    child: IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                      ),
                      onPressed: () {
                        controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      },
                    ),
                  ),
                  Positioned(
                    right: 20,
                    child: IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                      ),
                      onPressed: () {
                        controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      },
                    ),
                  ),
                ],

                // Close button
                Positioned(
                  top: 40, right: 20,
                  child: IconButton(
                    icon: const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.close, color: Colors.white)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Pagination Indicator
                if (urls.length > 1)
                  Positioned(
                    bottom: 50,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                      child: ListenableBuilder(
                        listenable: controller,
                        builder: (context, _) {
                          int current = 0;
                          try {
                            current = controller.page?.round() ?? 0;
                          } catch (_) {}
                          return Row(
                            children: List.generate(urls.length, (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: current == i ? Colors.white : Colors.white24,
                                shape: BoxShape.circle,
                              ),
                            )),
                          );
                        }
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrls = data['imageUrls'] as List<dynamic>? ?? [];
    final tech = data['tech'] as List<dynamic>? ?? [];

    if (isMobile) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image with Preview Logic
              GestureDetector(
                onTap: () => _showFullImage(context, imageUrls),
                child: Stack(
                  children: [
                    Hero(
                      tag: 'proj_mob_$docId', // استخدام docId لضمان التفرد
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrls.isNotEmpty
                            ? Image.network(
                                imageUrls[0], 
                                width: 100, height: 100, 
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                              )
                            : Container(
                                width: 100, height: 100, 
                                color: theme.brightness == Brightness.dark 
                                    ? Colors.black.withValues(alpha:0.2) 
                                    : theme.colorScheme.surfaceContainerHighest, 
                                child: const Icon(Icons.image_not_supported),
                              ),
                      ),
                    ),
                    if (imageUrls.length > 1)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.7), borderRadius: BorderRadius.circular(8)),
                          child: Text('+${imageUrls.length - 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    // Zoom Icon Indicator
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: onEdit,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(data['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(data['category'] ?? '', style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          if (data['year'] != null)
                            Text(data['year'].toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(data['location'] ?? '', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: onEdit),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                    onPressed: () async {
                      final confirm = await _showConfirmDelete(context);
                      if (confirm) {
                        await FirebaseFirestore.instance.collection('projects').doc(docId).delete();
                        if (context.mounted) VivumToast.show(context, 'Project Deleted');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: () => _showFullImage(context, imageUrls),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: 'proj_desk_$docId', // استخدام docId لضمان التفرد
                      child: imageUrls.isNotEmpty
                          ? Image.network(
                              imageUrls[0],
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                            )
                          : Container(
                              color: theme.brightness == Brightness.dark 
                                  ? Colors.black.withValues(alpha:0.2)
                                  : theme.colorScheme.surfaceContainerHighest, 
                              child: const Icon(Icons.image_not_supported),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.6), borderRadius: BorderRadius.circular(20)),
                      child: Text(data['category'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (imageUrls.length > 1)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.7), borderRadius: BorderRadius.circular(8)),
                        child: Text('+${imageUrls.length - 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(data['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (data['year'] != null)
                        Text(data['year'].toString(), style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(data['location'] ?? '', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const Spacer(),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: tech.map((t) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha:0.05), borderRadius: BorderRadius.circular(8)),
                          child: Text(t.toString(), style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () async {
                          final confirm = await _showConfirmDelete(context);
                          if (confirm) {
                            await FirebaseFirestore.instance.collection('projects').doc(docId).delete();
                            if (context.mounted) VivumToast.show(context, 'Project Deleted');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDelete(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), child: const Text('Delete')),
        ],
      ),
    ) ?? false;
  }
}

class ProjectFormDialog extends StatefulWidget {
  final Map<String, dynamic>? project;
  final String? docId;
  final VoidCallback onSaved;

  const ProjectFormDialog({super.key, this.project, this.docId, required this.onSaved});

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl, _industryCtrl, _challengeCtrl, _solutionCtrl, _resultCtrl, _techCtrl, _yearCtrl;
  String _category = 'Web';
  String _location = 'UAE';
  String _generatedId = '';
  Color _accentColor = const Color(0xFF00B5CC);
  List<Color> _primaryColors = [const Color(0xFF00B5CC), const Color(0xFFF5A61A)];
  List<String> _imageUrls = [];
  bool _loading = false;
  final List<PlatformFile> _newFiles = [];

  final List<String> _locations = ['سوريا', 'الامارات', 'السعودية', 'لبنان', 'الاردن'];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.project?['title'] ?? '');
    _industryCtrl = TextEditingController(text: widget.project?['industry'] ?? '');
    _yearCtrl = TextEditingController(text: widget.project?['year']?.toString() ?? DateTime.now().year.toString());
    _challengeCtrl = TextEditingController(text: widget.project?['challenge'] ?? '');
    _solutionCtrl = TextEditingController(text: widget.project?['solution'] ?? '');
    _resultCtrl = TextEditingController(text: widget.project?['result'] ?? '');
    _techCtrl = TextEditingController(text: (widget.project?['tech'] as List?)?.join(', ') ?? '');
    
    _category = widget.project?['category'] ?? 'Web';
    _location = widget.project?['location'] ?? 'الامارات';
    
    // Safety check for Dropdowns
    if (!['Branding', 'Web', 'App', 'AI'].contains(_category)) _category = 'Web';
    if (!_locations.contains(_location)) {
      if (_location == 'UAE') {
        _location = 'الامارات';
      } else {
        _location = _locations.first;
      }
    }
    
    _generatedId = widget.project?['id'] ?? '';
    
    if (widget.project?['accentColor'] != null) {
      _accentColor = Color(widget.project!['accentColor']);
    }
    if (widget.project?['colors'] != null) {
      _primaryColors = (widget.project!['colors'] as List).map((c) => Color(c)).toList();
    }
    
    _imageUrls = List<String>.from(widget.project?['imageUrls'] ?? []);
    
    _titleCtrl.addListener(_updateId);
  }

  void _updateId() {
    if (widget.docId == null) {
      setState(() {
        _generatedId = _titleCtrl.text.trim().toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
      });
    }
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.image);
    if (result != null) {
      setState(() => _newFiles.addAll(result.files));
    }
  }

  Future<List<String>> _uploadToSupabase(String projectId) async {
    List<String> uploaded = [];
    final supabase = Supabase.instance.client;

    for (var file in _newFiles) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final path = '$projectId/$fileName';
      
      await supabase.storage.from('projects').uploadBinary(path, file.bytes!);
      final url = supabase.storage.from('projects').getPublicUrl(path);
      uploaded.add(url);
    }
    return uploaded;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final pId = widget.docId ?? _generatedId;
      final uploadedUrls = await _uploadToSupabase(pId);
      final finalUrls = [..._imageUrls, ...uploadedUrls];

      final data = {
        'title': _titleCtrl.text.trim(),
        'id': pId,
        'category': _category,
        'location': _location,
        'year': int.tryParse(_yearCtrl.text.trim()) ?? DateTime.now().year,
        'industry': _industryCtrl.text.trim(),
        'challenge': _challengeCtrl.text.trim(),
        'solution': _solutionCtrl.text.trim(),
        'result': _resultCtrl.text.trim(),
        'tech': _techCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'accentColor': _accentColor.toARGB32(),
        'colors': _primaryColors.map((c) => c.toARGB32()).toList(),
        'imageUrls': finalUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.docId == null) {
        await FirebaseFirestore.instance.collection('projects').doc(pId).set(data);
      } else {
        await FirebaseFirestore.instance.collection('projects').doc(widget.docId).update(data);
      }

      if (!mounted) return;
      widget.onSaved();
      Navigator.pop(context);
      VivumToast.show(context, 'Project Saved Successfully');
    } catch (e) {
      if (mounted) VivumToast.show(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _pickColor(bool isAccent, {int? index}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: Wrap(
          spacing: 10, runSpacing: 10,
          children: Colors.primaries.map((c) => InkWell(
            onTap: () {
              setState(() {
                if (isAccent) {
                  _accentColor = c;
                } else if (index != null) {
                  _primaryColors[index] = c;
                }
              });
              Navigator.pop(context);
            },
            child: Container(width: 40, height: 40, color: c),
          )).toList(),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final lp = AppProvider.of(context);
    final theme = Theme.of(context);
    final isEdit = widget.docId != null;

    return AlertDialog(
      title: Text(isEdit ? lp.t('proj.edit') : lp.t('proj.add'), style: const TextStyle(fontWeight: FontWeight.bold)),
      scrollable: true,
      content: SizedBox(
        width: 800,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildField(_titleCtrl, lp.t('proj.title'), Icons.title, theme, required: true)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha:0.05), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Project ID (Auto)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text(_generatedId.isEmpty ? 'Waiting for title...' : _generatedId, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: _buildInputDecoration(lp.t('proj.category'), Icons.category, theme),
                      items: ['Branding', 'Web', 'App', 'AI'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _location,
                      decoration: _buildInputDecoration(lp.t('proj.location'), Icons.location_on_outlined, theme),
                      items: _locations.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _location = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField(_yearCtrl, lp.t('proj.year'), Icons.calendar_today_rounded, theme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(_industryCtrl, lp.t('proj.industry'), Icons.business, theme)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField(_challengeCtrl, lp.t('proj.challenge'), Icons.help_outline, theme, maxLines: 3),
              const SizedBox(height: 16),
              _buildField(_solutionCtrl, lp.t('proj.solution'), Icons.lightbulb_outline, theme, maxLines: 3),
              const SizedBox(height: 16),
              _buildField(_resultCtrl, lp.t('proj.result'), Icons.check_circle_outline, theme, maxLines: 2),
              const SizedBox(height: 16),
              _buildField(_techCtrl, lp.t('proj.tech'), Icons.code, theme),
              const SizedBox(height: 24),
              
              const Text('Visual Identity', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildColorButton('Accent Color', _accentColor, () => _pickColor(true)),
                  const SizedBox(width: 24),
                  ...List.generate(_primaryColors.length, (index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildColorButton('Color ${index+1}', _primaryColors[index], () => _pickColor(false, index: index)),
                  )),
                ],
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(lp.t('proj.images'), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ..._imageUrls.map((url) => _buildImageThumb(url, onRemove: () => setState(() => _imageUrls.remove(url)))),
                  ..._newFiles.map((file) => _buildNewFileThumb(file, onRemove: () => setState(() => _newFiles.remove(file)))),
                  InkWell(
                    onTap: _pickImages,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(border: Border.all(color: theme.dividerColor), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.add_a_photo_outlined),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(lp.t('user.cancel'))),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(lp.t('user.save')),
        ),
      ],
    );
  }

  Widget _buildColorButton(String label, Color color, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            width: 50, height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
          ),
        ),
      ],
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, ThemeData theme, {int maxLines = 1, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: _buildInputDecoration(label, icon, theme),
      validator: (v) => (required && v!.isEmpty) ? 'Field Required' : null,
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: theme.colorScheme.primary, size: 20),
      filled: true,
      fillColor: theme.cardTheme.color,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.outline)),
    );
  }

  Widget _buildImageThumb(String url, {required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover)),
        Positioned(right: 0, child: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: onRemove)),
      ],
    );
  }

  Widget _buildNewFileThumb(PlatformFile file, {required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(file.bytes!, width: 80, height: 80, fit: BoxFit.cover)),
        Positioned(right: 0, child: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.orange), onPressed: onRemove)),
      ],
    );
  }
}
