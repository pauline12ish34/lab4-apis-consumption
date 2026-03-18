import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/post_service.dart';
import 'post_form_page.dart';

class PostDetailResult {
  const PostDetailResult({this.updatedPost, this.deletedPostId});

  final Post? updatedPost;
  final int? deletedPostId;
}

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.post});

  final Post post;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PostService _postService = PostService();

  bool _isDeleting = false;

  Future<void> _editPost() async {
    final Post? updatedPost = await Navigator.of(context).push<Post>(
      MaterialPageRoute<Post>(
        builder: (BuildContext context) => PostFormPage(initialPost: widget.post),
      ),
    );

    if (!mounted || updatedPost == null) {
      return;
    }

    Navigator.of(context).pop(
      PostDetailResult(updatedPost: updatedPost),
    );
  }

  Future<void> _deletePost() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete post?'),
          content: const Text('This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _postService.deletePost(widget.post.id);
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        PostDetailResult(deletedPostId: widget.post.id),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete post: $error'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        actions: <Widget>[
          IconButton(
            onPressed: _isDeleting ? null : _editPost,
            tooltip: 'Edit post',
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: _isDeleting ? null : _deletePost,
            tooltip: 'Delete post',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            widget.post.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            widget.post.body,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Chip(label: Text('Post ID: ${widget.post.id}')),
          const SizedBox(height: 8),
          Chip(label: Text('User ID: ${widget.post.userId}')),
          if (_isDeleting) ...<Widget>[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}