
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posts Explorer',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF5C6BC0),
          brightness: Brightness.light,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16, height: 1.5),
          bodyMedium: TextStyle(fontSize: 14, height: 1.4),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF5C6BC0),
          brightness: Brightness.dark,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system,
      home: PostsScreen(),
    );
  }
}

class Post {
  final int id;
  final int userId;
  final String title;
  final String body;
  final Color userColor; // Added for visual interest

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.userColor,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // Generate a consistent color based on userId
    final random = math.Random(json['userId']);
    final hue = random.nextDouble() * 360;
    
    return Post(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      body: json['body'],
      userColor: HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor(),
    );
  }
}

class PostsScreen extends StatefulWidget {
  @override
  _PostsScreenState createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> with SingleTickerProviderStateMixin {
  late Future<List<Post>> futurePost;
  bool isRefreshing = false;
  late TabController _tabController;
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    futurePost = fetchPosts();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Post>> fetchPosts() async {
    setState(() {
      isRefreshing = true;
    });
    
    try {
      final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));

      // Add a slight delay to show loading state (for demo purposes)
      await Future.delayed(Duration(milliseconds: 600));

      if (response.statusCode == 200) {
        List<dynamic> postsJson = jsonDecode(response.body);
        List<Post> posts = postsJson.map((json) => Post.fromJson(json)).toList();
        
        // Sort posts for different tabs
        if (_selectedIndex == 1) {
          // Sort by user ID
          posts.sort((a, b) => a.userId.compareTo(b.userId));
        } else if (_selectedIndex == 2) {
          // Sort by title length
          posts.sort((a, b) => a.title.length.compareTo(b.title.length));
        }
        
        return posts;
      } else {
        throw Exception('Failed to load posts. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load posts: $e');
    } finally {
      if (mounted) {
        setState(() {
          isRefreshing = false;
        });
      }
    }
  }

  String getPostExcerpt(String body) {
    if (body.length > 100) {
      return body.substring(0, 100) + '...';
    }
    return body;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'DISMISS',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: true,
              title: Text(
                'Posts Explorer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () {
                    setState(() {
                      futurePost = fetchPosts();
                    });
                    _showSnackBar('Refreshing posts...');
                  },
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  tooltip: 'Search',
                  onPressed: () {
                    _showSnackBar('Search feature coming soon!');
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Recent', icon: Icon(Icons.access_time)),
                  Tab(text: 'Users', icon: Icon(Icons.people)),
                  Tab(text: 'Length', icon: Icon(Icons.sort)),
                ],
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 3,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostList(context),
            _buildPostList(context),
            _buildPostList(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showSnackBar('Create new post feature coming soon!');
        },
        child: Icon(Icons.add),
        tooltip: 'Create New Post',
      ),
    );
  }

  Widget _buildPostList(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: futurePost,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !isRefreshing) {
          return _buildLoadingState(context);
        } else if (snapshot.hasError) {
          return _buildErrorState(context, snapshot.error);
        } else if (snapshot.hasData) {
          List<Post> posts = snapshot.data!;
          return _buildPostListView(context, posts);
        } else {
          return _buildEmptyState(context);
        }
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading posts...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object? error) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        margin: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/error.png', // You'll need to add this asset
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.error_outline,
                  color: Colors.red[400],
                  size: 80,
                );
              },
            ),
            SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '${error}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  futurePost = fetchPosts();
                });
              },
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No posts found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try refreshing or check back later',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostListView(BuildContext context, List<Post> posts) {
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.secondary,
      onRefresh: () async {
        setState(() {
          futurePost = fetchPosts();
        });
      },
      child: posts.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                bool isFirst = index == 0;
                bool isLast = index == posts.length - 1;
                
                return PostCard(
                  post: posts[index],
                  isFirst: isFirst,
                  isLast: isLast,
                  onTap: () {
                    _showPostDetails(context, posts[index]);
                  },
                  onLike: () {
                    _showSnackBar('Liked post #${posts[index].id}');
                  },
                  onComment: () {
                    _showSnackBar('Comment feature coming soon!');
                  },
                  onShare: () {
                    _showSnackBar('Share feature coming soon!');
                  },
                );
              },
            ),
    );
  }

  void _showPostDetails(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                children: [
                  ListView(
                    controller: scrollController,
                    padding: EdgeInsets.only(top: 48, left: 20, right: 20, bottom: 20),
                    children: [
                      // User info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: post.userColor,
                            child: Text(
                              'U${post.userId}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User ${post.userId}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Author • ${DateTime.now().subtract(Duration(days: post.id % 30)).toString().substring(0, 10)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.more_vert),
                            onPressed: () {
                              _showSnackBar('Options coming soon!');
                            },
                          ),
                        ],
                      ),
                      
                      Divider(height: 32),
                      
                      // Post title
                      Text(
                        post.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Post body
                      Text(
                        post.body,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.6,
                          letterSpacing: 0.1,
                        ),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Engagement stats
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatItem(context, Icons.favorite, '${post.id * 5 + 3}', 'Likes'),
                                _buildStatItem(context, Icons.comment, '${post.id * 2 + 1}', 'Comments'),
                                _buildStatItem(context, Icons.share, '${post.id % 5 + 1}', 'Shares'),
                              ],
                            ),
                            SizedBox(height: 16),
                            Divider(),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(context, Icons.favorite_outline, 'Like', () {
                                  _showSnackBar('Liked post #${post.id}');
                                }),
                                _buildActionButton(context, Icons.chat_bubble_outline, 'Comment', () {
                                  _showSnackBar('Comment feature coming soon!');
                                }),
                                _buildActionButton(context, Icons.share_outlined, 'Share', () {
                                  _showSnackBar('Share feature coming soon!');
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Tags section
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTag(context, 'Post #${post.id}'),
                          _buildTag(context, 'User ${post.userId}'),
                          _buildTag(context, '${post.title.split(' ')[0]}'),
                          _buildTag(context, '${post.title.split(' ').last}'),
                        ],
                      ),
                      
                      SizedBox(height: 80), // Bottom padding for FAB
                    ],
                  ),
                  
                  // Handle and close button
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String count, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String tag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final bool isFirst;
  final bool isLast;

  const PostCard({
    Key? key,
    required this.post,
    required this.onTap,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    this.isFirst = false,
    this.isLast = false,
  }) : super(key: key);

  String getPostExcerpt(String body) {
    if (body.length > 120) {
      return body.substring(0, 120) + '...';
    }
    return body;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(
        top: isFirst ? 8 : 0,
        bottom: 16,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: post.userColor,
                    child: Text(
                      'U${post.userId}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User ${post.userId}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${DateTime.now().subtract(Duration(days: post.id % 30)).toString().substring(0, 10)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '#${post.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Title
              Text(
                post.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              
              SizedBox(height: 10),
              
              // Content preview
              Text(
                getPostExcerpt(post.body),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[300] 
                      : Colors.grey[800],
                  height: 1.4,
                ),
              ),
              
              if (post.body.length > 120)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Read more',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              
              SizedBox(height: 16),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconButton(
                    context: context,
                    icon: Icons.favorite_border,
                    label: '${post.id * 5 + 3}',
                    onTap: onLike,
                  ),
                  _buildIconButton(
                    context: context,
                    icon: Icons.chat_bubble_outline,
                    label: '${post.id * 2 + 1}',
                    onTap: onComment,
                  ),
                  _buildIconButton(
                    context: context,
                    icon: Icons.share_outlined,
                    label: '${post.id % 5 + 1}',
                    onTap: onShare,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.bookmark_border,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.grey[600],
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}