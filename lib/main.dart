import 'package:flutter/material.dart';

import 'models/post.dart';
import 'screens/post_detail_page.dart';
import 'screens/post_form_page.dart';
import 'services/post_service.dart';

void main() {
  runApp(const PostsManagerApp());
}

class PostsManagerApp extends StatelessWidget {
  const PostsManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posts Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _iconScale;
  late final Animation<double> _buttonFade;
  late final Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _contentFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.75, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _iconScale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _buttonFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 1, curve: Curves.easeIn),
    );
    _buttonScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 1, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SlideTransition(
                position: _contentSlide,
                child: FadeTransition(
                  opacity: _contentFade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ScaleTransition(
                        scale: _iconScale,
                        child: const Icon(
                          Icons.article_outlined,
                          size: 80,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Welcome to Posts',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Manage and explore posts from around the world',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              FadeTransition(
                opacity: _buttonFade,
                child: ScaleTransition(
                  scale: _buttonScale,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Get Started'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const PostsPage(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final PostService _postService = PostService();

  late Future<List<Post>> _postsFuture;
  List<Post> _posts = <Post>[];

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchPostsFuture();
  }

  Future<List<Post>> _fetchPostsFuture() async {
    final List<Post> posts = await _postService.fetchPosts();
    _posts = posts;
    return posts;
  }

  Future<void> _refreshPosts() async {
    final List<Post> posts = await _postService.fetchPosts();
    if (!mounted) {
      return;
    }

    setState(() {
      _posts = posts;
      _postsFuture = Future<List<Post>>.value(posts);
    });
  }

  void _retryLoadPosts() {
    setState(() {
      _postsFuture = _fetchPostsFuture();
    });
  }

  Future<void> _openCreatePost() async {
    final Post? createdPost = await Navigator.of(context).push<Post>(
      MaterialPageRoute<Post>(
        builder: (BuildContext context) => const PostFormPage(),
      ),
    );

    if (!mounted || createdPost == null) {
      return;
    }

    setState(() {
      _posts.insert(0, createdPost);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post created successfully.')),
    );
  }

  Future<void> _openPostDetails(Post post) async {
    final PostDetailResult? result =
        await Navigator.of(context).push<PostDetailResult>(
      MaterialPageRoute<PostDetailResult>(
        builder: (BuildContext context) => PostDetailPage(post: post),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result.updatedPost != null) {
      final Post updatedPost = result.updatedPost!;
      setState(() {
        _posts = _posts
            .map(
              (Post currentPost) =>
                  currentPost.id == updatedPost.id ? updatedPost : currentPost,
            )
            .toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully.')),
      );
      return;
    }

    if (result.deletedPostId != null) {
      final int deletedPostId = result.deletedPostId!;
      setState(() {
        _posts.removeWhere((Post item) => item.id == deletedPostId);
        _postsFuture = Future<List<Post>>.value(_posts);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully.')),
      );
    }
  }

  Widget _buildBody() {
    return FutureBuilder<List<Post>>(
      future: _postsFuture,
      builder: (BuildContext context, AsyncSnapshot<List<Post>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _posts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError && _posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.error_outline, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load posts.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _retryLoadPosts,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }

        final List<Post> posts =
            _posts.isNotEmpty ? _posts : (snapshot.data ?? <Post>[]);

        if (posts.isEmpty) {
          return const Center(
            child: Text('No posts found.'),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshPosts,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final Post post = posts[index];
              return ListTile(
                title: Text(
                  post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  post.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openPostDetails(post),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts Manager'),
        actions: <Widget>[
          IconButton(
            onPressed: _retryLoadPosts,
            tooltip: 'Refresh posts',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePost,
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
      ),
    );
  }
}
