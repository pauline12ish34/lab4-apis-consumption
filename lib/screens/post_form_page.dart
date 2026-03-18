import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/post_service.dart';

class PostFormPage extends StatefulWidget {
  const PostFormPage({super.key, this.initialPost});

  final Post? initialPost;

  @override
  State<PostFormPage> createState() => _PostFormPageState();
}

class _PostFormPageState extends State<PostFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final PostService _postService = PostService();

  bool _isSaving = false;

  bool get _isEditMode => widget.initialPost != null;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialPost?.title ?? '';
    _bodyController.text = widget.initialPost?.body ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final String title = _titleController.text.trim();
      final String body = _bodyController.text.trim();

      late final Post result;
      if (_isEditMode) {
        result = await _postService.updatePost(
          widget.initialPost!.copyWith(title: title, body: body),
        );
      } else {
        result = await _postService.createPost(title: title, body: body);
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save post: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Post' : 'Create Post'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Body is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Post'),
            ),
          ],
        ),
      ),
    );
  }
}