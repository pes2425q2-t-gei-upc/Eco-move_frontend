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


  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

  @override
  Future<void> initState() async {
    super.initState();
    token = await getAccessToken();
    _fetchChats();
    print(chatsList);
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
        chatsList = json.decode(utf8.decode(response.bodyBytes));
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
      _fetchChats();
      print(chatsList);
      if (response.statusCode == 201) {
        print(response.bodyBytes);
      } else {
        print('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error en la petición: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    // Hardcoded test data
    /*final List<ChatPreview> chatsList = [
    ChatPreview(
      id: 1,
      otherUserName: 'Dani',
      otherUserAvatarUrl: '',
      lastMessage: 'Holaa no se que posar',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 2,
    ),
    ChatPreview(
      id: 2,
      otherUserName: 'Alexander',
      otherUserAvatarUrl: '',
      lastMessage: 'Aqui tampoc se que posar',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 0,
    ),
    ChatPreview(
      id: 3,
      otherUserName: 'Berrios',
      otherUserAvatarUrl: '',  // Empty to test initial letter avatar
      lastMessage: 'I aqui menys',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
    ),
    ];*/

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
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
                print(chat);
                return Text(chat.toString());
                /*return ChatListItem(
                  avatarUrl: chat.otherUserAvatarUrl,
                  userName: chat.otherUserName,
                  lastMessage: chat.lastMessage,
                  lastMessageTime: chat.lastMessageTime,
                  unreadCount: chat.unreadCount,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(),
                      ),
                    )
                  },
                );*/
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

// Chat preview model class
class ChatPreview {
  final int id;
  final String otherUserName;
  final String otherUserAvatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ChatPreview({
    required this.id,
    required this.otherUserName,
    required this.otherUserAvatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });
}

// Chat list item widget
class ChatListItem extends StatelessWidget {
  final String avatarUrl;
  final String userName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final Function() onTap;

  const ChatListItem({
    Key? key,
    required this.avatarUrl,
    required this.userName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
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
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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
    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(avatarUrl),
      );
    } else {
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