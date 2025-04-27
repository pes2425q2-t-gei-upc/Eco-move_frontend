import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'chat.dart';

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
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  String? token = '';
  List<dynamic> chatsList = [];
  Map<int, Map<String, String>> lastMessages = {}; // Add this to store last messages
  late int my_id;

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

  Future<void> deleteAccessToken() async {
    return await _secureStorage.deleteAll();
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    token = await getAccessToken();
    await _fetchChats();
    print('chat lists vallll ${chatsList}');
    await _getMyInfo();
    // Fetch last messages for all chats after getting the chat list
    _fetchAllLastMessages();

  }

  // Add this method to fetch last messages for all chats
  Future<void> _fetchAllLastMessages() async {
    for (var chat in chatsList) {
      if (chat['id'] != null) {
        final lastMessage = await _fetchLastMessage(chat['id']);
        if (lastMessage != null) {
          setState(() {
            lastMessages[chat['id']] = lastMessage;

          });
        }
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
              _newChat(inputText!);
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
        Uri.parse('http://10.0.2.2:8000/social/chat/my_chats/'),
        headers: {
          'Authorization': 'Bearer ${token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final newChatsList = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          chatsList = newChatsList;
        });
      } else {
        print('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error en la petición: $e');
    }
  }

  Future<void> _newChat(String email) async {
    try {
      final response = await http.post(
          Uri.parse('http://10.0.2.2:8000/social/chat/create_chat/'),
          headers: {
            'Authorization': 'Bearer ${token}',
          },
          body: {
            'receptor_email': email,
          }
      );
      await _fetchChats();
      if (response.statusCode == 201) {
        print(response.bodyBytes);
        // After creating a new chat, fetch messages again
        _fetchAllLastMessages();
      } else {
        print('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error en la petición: $e');
    }
  }

  Future<void> _getMyInfo() async {
    final url = Uri.parse('http://10.0.2.2:8000/me/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('el body es ${response.body}');
        final bodyJson = json.decode(response.body); // Convert String to Map
        my_id = bodyJson['id'];
        print(my_id);
      } else {
        print('Failed to send message: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }


  Future<Map<String, String>> _fetchLastMessage(int chatId) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/social/chat/$chatId/messages/'),
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
            final lastMessage = messagesList.first; // assuming first is the newest
            print('last message es ${lastMessage}');

            // Extract content and timestamp
            String content = lastMessage['content'] ?? 'No content';
            String timestamp = lastMessage['timestamp'] ?? 'No timestamp';

            return {'content': content, 'timestamp': timestamp}; // Return a map with both
          }
        }
      } else {
        print('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error en la petición: $e');
    }

    return {'content': 'No messages', 'timestamp': 'No timestamp'}; // Default if no message
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
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              deleteAccessToken();
              print('Search button pressed');
            },
          ),
        ],
      ),
      body: chatsList.isEmpty
          ? const Center(child: Text('No hay chats'))
          : Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: chatsList.length,
              itemBuilder: (context, index) {
                final chat = chatsList[index];
                final lastMessage = lastMessages[chat['id']] ?? 'Loading...';


                return ChatListItem(
                  userName: my_id == chat['receptor'] ? '${chat['creador_first_name']} ${chat['creador_last_name']}' : '${chat['receptor_first_name']} ${chat['receptor_last_name']}',
                  lastMessage: lastMessages[chat['id']]?['content'] ?? 'No content',
                  lastMessageTime: _parseDateTime(lastMessages[chat['id']]?['timestamp']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: chat['id'],
                          name: my_id == chat['receptor'] ? chat['creador_first_name'] : chat['receptor_first_name'] ,
                          lastName: my_id == chat['receptor'] ? chat['creador_last_name'] : chat['receptor_last_name'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          getEmail();
        },
        foregroundColor: Colors.lightGreen,
        backgroundColor: Colors.grey[200],
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
  final Function() onTap;

  const ChatListItem({
    Key? key,
    required this.userName,
    required this.lastMessage,
    required this.lastMessageTime,
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

            // Chat details section (name, message)
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
      return DateFormat('EEEE').format(time); // Day name
    } else {
      return DateFormat('MM/dd/yy').format(time);
    }
  }
}

// Placeholder for chat detail screen
class ChatDetailScreen extends StatelessWidget {
  final int chatId;

  const ChatDetailScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Detail'),
      ),
      body: Center(
        child: Text('Chat detail for chat ID: $chatId'),
      ),
    );
  }
}