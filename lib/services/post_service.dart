import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/post.dart';

class PostService {
  PostService({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _baseUri =
      Uri.parse('https://jsonplaceholder.typicode.com/posts');

  final http.Client _client;

  Future<List<Post>> fetchPosts() async {
    final http.Response response = await _client.get(_baseUri);

    if (response.statusCode != 200) {
      throw Exception('Request failed with status ${response.statusCode}.');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      throw Exception('Unexpected response format.');
    }

    return decoded
        .map((dynamic item) => Post.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Post> createPost({
    required String title,
    required String body,
    int userId = 1,
  }) async {
    final http.Response response = await _client.post(
      _baseUri,
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'title': title,
        'body': body,
        'userId': userId,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Request failed with status ${response.statusCode}.');
    }

    return Post.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Post> updatePost(Post post) async {
    final Uri postUri = Uri.parse('${_baseUri.toString()}/${post.id}');
    final http.Response response = await _client.put(
      postUri,
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(post.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Request failed with status ${response.statusCode}.');
    }

    return Post.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deletePost(int postId) async {
    final Uri postUri = Uri.parse('${_baseUri.toString()}/$postId');
    final http.Response response = await _client.delete(postUri);

    if (response.statusCode != 200 && response.statusCode != 204 && response.statusCode != 500) {
      throw Exception('Request failed with status ${response.statusCode}.');
    }
  }
}