import 'dart:async';
import 'dart:convert';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'chat.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ChatListScreen(),
    );
  }
}

class ChatListScreen extends StatefulWidget {
  ChatListScreen({Key? key}) : super(key: key);

  @override
  ChatListScreenState createState() => ChatListScreenState();
}

class ChatListScreenState extends State<ChatListScreen> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  String? token = '';
  List<dynamic> chatsList = [];
  Map<int, Map<String, String>> lastMessages = {};
  Map<String, String?> profilePhotos = {}; // Cache for profile photos using username as key
  late int my_id;
  bool _isRefreshing = true;
  Timer? _pollingTimer;
  bool _isPollingActive = false;

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    token = await getAccessToken();
    await _getMyInfo();
    await _fetchChats();
    await _fetchAllLastMessages();
    await _fetchAllProfilePhotos();

    // Start polling after initial load
    _startPolling();
  }

  void _startPolling() {
    // Don't start if already active
    if (_isPollingActive) return;

    _isPollingActive = true;
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // Only poll if the widget is still mounted and not manually refreshing
      if (mounted && !_isRefreshing) {
        await _silentRefresh();
      }
    });
  }

  void _stopPolling() {
    _isPollingActive = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Silent refresh without showing loading indicators
  Future<void> _silentRefresh() async {
    try {
      await _fetchChats();
      await _fetchAllLastMessages();
      await _fetchAllProfilePhotos();
    } catch (e) {
      print('Error during silent refresh: $e');
      // Don't show snackbar for silent refresh errors to avoid spam
    }
  }

  // Method to refresh chats and messages (manual refresh)
  Future<void> _refreshChats() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _fetchChats();
      await _fetchAllLastMessages();
      await _fetchAllProfilePhotos();
    } catch (e) {
      print('Error refreshing chats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing chats: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _fetchAllLastMessages() async {
    for (var chat in chatsList) {
      if (chat['id'] != null) {
        final lastMessage = await _fetchLastMessage(chat['id']);
        if (lastMessage != null && mounted) {
          setState(() {
            lastMessages[chat['id']] = lastMessage;
          });
        }
      }
    }
  }

  Future<void> _fetchAllProfilePhotos() async {
    for (var chat in chatsList) {
      String username;

      if (my_id == chat['receptor']) {
        username = chat['creador_username'] ?? '';
      } else {
        username = chat['receptor_username'] ?? '';
      }

      if (username.isNotEmpty && !profilePhotos.containsKey(username)) {
        await _fetchProfilePhoto(username);
      }
    }
  }

  Future<String?> getEmail() async {
    String? inputText;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Escribe el mail'),
        content: TextField(
          onChanged: (value) {
            inputText = value;
          },
          decoration: const InputDecoration(
            hintText: "Email",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              if (inputText != null && inputText!.isNotEmpty) {
                newChat(inputText!);
              }
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );

    return inputText;
  }

  Future<void> _fetchChats() async {
    try {
      final response = await http.get(
        Uri.parse(FrontendRoutes.build(FrontendRoutes.myChats)),
        headers: {
          'Authorization': 'Bearer ${token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final newChatsList = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            chatsList = newChatsList;
          });
        }
      } else {
        print('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error en la petición: $e');
    }
  }

  Future<void> newChat(String email) async {
    try {
      final response = await http.post(
          Uri.parse(FrontendRoutes.build(FrontendRoutes.createChat)),
          headers: {
            'Authorization': 'Bearer ${token}',
          },
          body: {
            'receptor_email': email,
          }
      );

      if (response.statusCode == 201) {
        // After creating a new chat, refresh immediately
        await _fetchChats();
        await _fetchAllLastMessages();
        await _fetchAllProfilePhotos();
      } else {
        print('Error ${response.statusCode}: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating chat: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error en la petición: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getMyInfo() async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.me));

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final bodyJson = json.decode(response.body);
        my_id = bodyJson['id'];
        print(my_id);
      } else {
        print('Failed to send message: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _fetchProfilePhoto(String username) async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.profilePhotoUsername(username)));

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final bodyJson = json.decode(response.body);
        final foto = bodyJson['foto'];

        if (mounted) {
          setState(() {
            profilePhotos[username] = foto;
          });
        }
      } else {
        print('Failed to fetch photo for $username: ${response.statusCode} - ${response.body}');
        if (mounted) {
          setState(() {
            profilePhotos[username] = null;
          });
        }
      }
    } catch (e) {
      print('Error fetching photo for $username: $e');
      if (mounted) {
        setState(() {
          profilePhotos[username] = null;
        });
      }
    }
  }

  Future<Map<String, String>> _fetchLastMessage(int chatId) async {
    try {
      final response = await http.get(
        Uri.parse(FrontendRoutes.build(FrontendRoutes.chatMessages(chatId))),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final messagesJson = json.decode(utf8.decode(response.bodyBytes));

        if (messagesJson.containsKey('results') && messagesJson['results'] is List) {
          final messagesList = messagesJson['results'] as List;

          if (messagesList.isNotEmpty) {
            final lastMessage = messagesList.first;

            String content = lastMessage['content'] ?? 'No content';
            String timestamp = lastMessage['timestamp'] ?? 'No timestamp';

            return {'content': content, 'timestamp': timestamp};
          }
        }
      } else {
        print('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error en la petición: $e');
    }

    return {'content': 'No messages', 'timestamp': 'No timestamp'};
  }

  DateTime _parseDateTime(String? timestamp) {
    if (timestamp == null || timestamp == 'No timestamp') {
      return DateTime.now();
    }
    try {
      return DateTime.parse(timestamp);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/', // Ruta de la página principal
                  (route) => false,
            );
          },
        ),
        title: Row(
          children: [
            const Text('Chats'),
            const SizedBox(width: 8),
            // Show polling indicator
            if (_isPollingActive)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.lightGreen[100],
        actions: [
          // Refresh button in app bar
          _isRefreshing
              ? Container(
            margin: EdgeInsets.all(14),
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.green[800],
              strokeWidth: 2,
            ),
          )
              : IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshChats,
            tooltip: 'Refresh chats',
          ),
          // Toggle polling button
          IconButton(
            icon: Icon(_isPollingActive ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              if (_isPollingActive) {
                _stopPolling();
              } else {
                _startPolling();
              }
              setState(() {});
            },
            tooltip: _isPollingActive ? 'Stop auto-refresh' : 'Start auto-refresh',
          ),
        ],
      ),
      body: chatsList.isEmpty
          ?  Center(child: Text(context.loc.no_chats))
          : RefreshIndicator(
        onRefresh: _refreshChats,
        child: ListView.builder(
          itemCount: chatsList.length,
          itemBuilder: (context, index) {
            final chat = chatsList[index];

            // Determine which user's username to use for profile photo
            String username;
            if (my_id == chat['receptor']) {
              username = chat['creador_username'] ?? '';
            } else {
              username = chat['receptor_username'] ?? '';
            }

            return ChatListItem(
              userName: my_id == chat['receptor']
                  ? '${chat['creador_first_name']} ${chat['creador_last_name']}'
                  : '${chat['receptor_first_name']} ${chat['receptor_last_name']}',
              lastMessage: lastMessages[chat['id']]?['content'] ?? 'No content',
              lastMessageTime: _parseDateTime(lastMessages[chat['id']]?['timestamp']),
              profilePhotoUrl: profilePhotos[username],
              onTap: () {
                // Pause polling while in chat
                _stopPolling();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatId: chat['id'],
                      name: my_id == chat['receptor']
                          ? chat['creador_first_name']
                          : chat['receptor_first_name'],
                      lastName: my_id == chat['receptor']
                          ? chat['creador_last_name']
                          : chat['receptor_last_name'],
                    ),
                  ),
                ).then((_) {
                  // Resume polling when returning from chat
                  _startPolling();
                  // Also refresh immediately when returning
                  _refreshChats();
                });
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          getEmail();
        },
        foregroundColor: Colors.green[100],
        backgroundColor: Colors.grey[500],
        child: const Icon(Icons.chat),
      ),
    );
  }
}

// Chat list item widget
class ChatListItem extends StatelessWidget {
  final String userName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String? profilePhotoUrl;
  final Function() onTap;

  const ChatListItem({
    Key? key,
    required this.userName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.profilePhotoUrl,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar section
            _buildAvatar(),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(lastMessageTime),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    // If profile photo URL is null or empty, show default avatar
    if (profilePhotoUrl == null || profilePhotoUrl!.isEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey,
        child: const Icon(
          Icons.person,
          color: Colors.white,
          size: 30,
        ),
      );
    }

    // Show profile photo with fallback to default avatar on error
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey,
      child: ClipOval(
        child: Image.network(
          profilePhotoUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            );
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == yesterday) {
      return 'Ayer';
    } else if (now.difference(time).inDays < 7) {
      return DateFormat('EEEE').format(time);
    } else {
      return DateFormat('MM/dd/yy').format(time);
    }
  }
}