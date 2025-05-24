import 'dart:convert';
import 'dart:async';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
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
  List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  int? my_id;
  String? token = '';
  bool _isLoading = true;
  bool _isSendingMessage = false;

  final int _pollingIntervalSeconds = 5;
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
    setState(() {
      _isLoading = true;
    });

    print('entra');
    token = await getAccessToken();
    print('agafa el token');
    await _getMyInfo();
    print('agafa la meva info');
    await _fetchMessages();
    print('afaga els missatges');

    setState(() {
      _isLoading = false;
    });

    _startPolling();
  }

  void _startPolling() {

    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(
        Duration(seconds: _pollingIntervalSeconds),
            (timer) {
          if (!_isSendingMessage) {
            print('polling');
            _fetchMessages();
            print('surt del polling');
          }
        }
    );

  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isMe: true,
        ),
      );
    });

    _sendMessage(widget.chatId, text);
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
    setState(() {
      _isSendingMessage = true;
    });

    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.messages));

    final Map<String, dynamic> data = {
      'chat': chat,
      'content': text,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        print('Message sent');

        await Future.delayed(Duration(milliseconds: 300));

        await _fetchMessages();
      } else {
        print('Failed to send message: ${response.statusCode} - ${response.body}');

        setState(() {
          _messages.removeWhere((msg) => msg.text == text && msg.isMe);
        });
      }
    } catch (e) {
      print('Error: $e');

      setState(() {
        _messages.removeWhere((msg) => msg.text == text && msg.isMe);
      });
    } finally {
      setState(() {
        _isSendingMessage = false;
      });
    }
  }

  Future<void> _getMyInfo() async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.me));

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final bodyJson = json.decode(response.body);
        setState(() {
          my_id = bodyJson['id'];
        });
        print('My ID: $my_id');
      } else {
        print('Failed to get user info: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting user info: $e');
    }
  }

  Future<void> _fetchMessages() async {
    if (my_id == null) {
      await _getMyInfo();
      if (my_id == null) {
        print('Cannot fetch messages: user ID is not available');
        return;
      }
    }

    try {
      final response = await http.get(
        Uri.parse(FrontendRoutes.build(FrontendRoutes.chatMessages(widget.chatId))),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final messagesJson = json.decode(utf8.decode(response.bodyBytes));

        if (messagesJson.containsKey('results') && messagesJson['results'] is List) {
          List<ChatMessage> newMessages = [];

          for (var message in messagesJson['results']) {
            newMessages.add(
              ChatMessage(
                text: message['content'],
                isMe: message['sender'] == my_id,
              ),
            );
          }

          newMessages = newMessages.reversed.toList();

          if (_messagesAreDifferent(newMessages, _messages)) {
            setState(() {
              _messages = newMessages;
            });

            if (!_isLoading && newMessages.length > _messages.length) {
              _scrollToBottom();
            }
          }
        }
      } else {
        print('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  bool _messagesAreDifferent(List<ChatMessage> list1, List<ChatMessage> list2) {
    if (list1.length != list2.length) return true;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i].text != list2[i].text || list1[i].isMe != list2[i].isMe) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.name} ${widget.lastName}'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
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