import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/project.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_provider.dart';

class ProjectsManagerScreen extends StatelessWidget {
  const ProjectsManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = AppProvider.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(lp.t('dash.projects'), style: Theme.of(context).textTheme.displaySmall),
            ElevatedButton.icon(
              onPressed: () => _showProjectDialog(context, lp),
              icon: const Icon(Icons.add),
              label: Text(lp.t('proj.add')),
              style: ElevatedButton.styleFrom(backgroundColor: VivumColors.teal, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('projects').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final projects = snapshot.data!.docs.map((d) => Project.fromFirestore(d.data() as Map<String, dynamic>, d.id)).toList();
              
              return ListView.separated(
                itemCount: projects.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final p = projects[index];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: p.imageUrl.isNotEmpty 
                        ? Image.network(p.imageUrl, width: 80, height: 80, fit: BoxFit.cover)
                        : const Icon(Icons.image, size: 80),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: VivumColors.teal), onPressed: () => _showProjectDialog(context, lp, project: p)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteProject(p)),
                        ],
                      ),
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

  void _showProjectDialog(BuildContext context, AppProvider lp, {Project? project}) {
    showDialog(
      context: context,
      builder: (context) => ProjectDialog(lp: lp, project: project),
    );
  }

  void _deleteProject(Project project) {
    FirebaseFirestore.instance.collection('projects').doc(project.id).delete();
  }
}

class ProjectDialog extends StatefulWidget {
  final AppProvider lp;
  final Project? project;
  const ProjectDialog({super.key, required this.lp, this.project});

  @override
  State<ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<ProjectDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  String? _imageUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name);
    _descController = TextEditingController(text: widget.project?.description);
    _imageUrl = widget.project?.imageUrl;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;

    setState(() => _uploading = true);
    try {
      final file = result.files.first;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      
      await Supabase.instance.client.storage.from('projects').uploadBinary(fileName, file.bytes!);
      final url = Supabase.instance.client.storage.from('projects').getPublicUrl(fileName);
      
      setState(() => _imageUrl = url);
    } catch (e) {
      debugPrint('Upload error: $e');
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final data = {
      'title': _nameController.text,
      'description': _descController.text,
      'imageUrl': _imageUrl ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (widget.project == null) {
      await FirebaseFirestore.instance.collection('projects').add(data);
    } else {
      await FirebaseFirestore.instance.collection('projects').doc(widget.project!.id).update(data);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.project == null ? widget.lp.t('proj.add') : widget.lp.t('proj.edit')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: widget.lp.t('proj.name'))),
            const SizedBox(height: 16),
            TextField(controller: _descController, maxLines: 3, decoration: InputDecoration(labelText: widget.lp.t('proj.desc'))),
            const SizedBox(height: 24),
            if (_imageUrl != null) Image.network(_imageUrl!, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _uploading ? null : _pickImage,
              icon: _uploading ? const CircularProgressIndicator(value: 20) : const Icon(Icons.upload),
              label: Text(widget.lp.t('proj.image')),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: VivumColors.teal, foregroundColor: Colors.white), child: const Text('Save')),
      ],
    );
  }
}
