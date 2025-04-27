import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;


class ChatScreen extends StatefulWidget {
  final int chatId;
  final String name;
  final String lastName;
  const ChatScreen({Key? key, required this.chatId, required this.name, required this.lastName}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  late List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  late int my_id;
  String? token = '';

  final int _pollingIntervalSeconds = 3;
  Timer? _pollingTimer;


  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    token = await getAccessToken();
    await _getMyInfo();
    await _fetchMessages();
    _startPolling();
  }

  void _startPolling() {
    // Cancel any existing timer
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(
        Duration(seconds: _pollingIntervalSeconds),
            (timer) => _fetchMessages()
    );
  }

  @override
  void dispose() {
    // Cancel the timer when the screen is disposed
    _pollingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }




  void _handleSubmitted(String text) {
    _textController.clear();

    // Add the user's message
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isMe: true,
        ),
      );
    });

    _sendMessage(widget.chatId, text);

    // Simulate a response from another user
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Aqui respon X",
            isMe: false,
          ),
        );
      });
      _scrollToBottom();
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  Future<void> _sendMessage(int chat, String text) async {
    final url = Uri.parse('http://10.0.2.2:8000/social/messages/');

    final Map<String, dynamic> data = {
      'chat': chat,
      'content': text,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${token}',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        print('Message sent');
      } else {
        print('Failed to send message: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
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


  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/social/chat/${widget.chatId}/messages/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final messagesJson = json.decode(utf8.decode(response.bodyBytes));
        print('els missatges sonnnnnnnnnnnn ${messagesJson}');

        if (messagesJson.containsKey('results') && messagesJson['results'] is List) {
          setState(() {
            _messages.clear(); // Clear previous messages

            // Convert each message in the results list to a ChatMessage
            for (var message in messagesJson['results']) {
              _messages.add(
                ChatMessage(
                  text: message['content'],
                  isMe: message['sender'] == my_id,
                ),
              );
            }
            final reversedNewMessages = _messages.reversed.toList();

            if (_messages.length != reversedNewMessages.length) {
              setState(() {
                _messages = reversedNewMessages;
              });

              _scrollToBottom();
            }


          });

          // Scroll to bottom after loading messages
          _scrollToBottom();
        }
      } else {
        print('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error en la petición: $e');
    }
  }

//TO DO que s'actualitzi tot el rato !!!!! (polling)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat ${widget.name} ${widget.lastName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (_, int index) => _messages[index],
            ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Envía un mensaje',
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isMe;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                child: Text('X'),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isMe ? Colors.lightGreen[100]: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(text),
            ),
          ),
          if (isMe)
            Container(
              margin: const EdgeInsets.only(left: 16.0),
              child: const CircleAvatar(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                child: Text('Me'),
              ),
            ),
        ],
      ),
    );
  }
}