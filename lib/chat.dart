import 'dart:convert';
import 'dart:async';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'package:intl/intl.dart';



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
  String? myProfilePhoto;
  String? otherUserProfilePhoto;
  String? otherUserUsername;

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
    token = await getAccessToken();
    await _getMyInfo();
    await _getChatInfo();
    await _fetchMyProfilePhoto();
    if (otherUserUsername != null) {
      await _fetchOtherUserProfilePhoto(otherUserUsername!);
    }
    await _fetchMessages();

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
            _fetchMessages();
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
          myProfilePhoto: myProfilePhoto,
          otherUserProfilePhoto: otherUserProfilePhoto,
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

  Future<void> _reportChat(int id, String comment) async {

    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.reportChat));

    final Map<String, dynamic> data = {
      'chat_id': id,
      'descripcio': comment,
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
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(context.loc.report_chat_ok),
              content: Text(context.loc.report_chat_ok_text),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        print('Failed to send message: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _showReportDialog() {
    final TextEditingController reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.loc.report_chat),
          content: TextField(
            controller: reportController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: context.loc.report_chat_motive,
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (reportController.text.trim().isNotEmpty) {
                  _reportChat(widget.chatId, reportController.text.trim());
                  Navigator.of(context).pop();
                }
              },
              child: Text('Report'),
            ),
          ],
        );
      },
    );
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
      } else {
        print('Failed to get user info: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting user info: $e');
    }
  }

  Future<void> _getChatInfo() async {
    try {
      final response = await http.get(
        Uri.parse(FrontendRoutes.build(FrontendRoutes.myChats)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final chatsList = json.decode(utf8.decode(response.bodyBytes));

        // Find the current chat
        for (var chat in chatsList) {
          if (chat['id'] == widget.chatId) {
            // Determine the other user's username
            if (my_id == chat['receptor']) {
              otherUserUsername = chat['creador_username'];
            } else {
              otherUserUsername = chat['receptor_username'];
            }
            break;
          }
        }
      } else {
        print('Failed to get chat info: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting chat info: $e');
    }
  }

  Future<void> _fetchMyProfilePhoto() async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.profilePhoto));

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
        final foto = bodyJson['foto'];

        if (mounted) {
          setState(() {
            myProfilePhoto = foto;
          });
        }
      } else {
        print('Failed to fetch my profile photo: ${response.statusCode} - ${response.body}');
        if (mounted) {
          setState(() {
            myProfilePhoto = null;
          });
        }
      }
    } catch (e) {
      print('Error fetching my profile photo: $e');
      if (mounted) {
        setState(() {
          myProfilePhoto = null;
        });
      }
    }
  }

  Future<void> _fetchOtherUserProfilePhoto(String username) async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.profilePhotoUsername(username)));

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
        final foto = bodyJson['foto'];

        if (mounted) {
          setState(() {
            otherUserProfilePhoto = foto;
          });
        }
      } else {
        print('Failed to fetch other user profile photo: ${response.statusCode} - ${response.body}');
        if (mounted) {
          setState(() {
            otherUserProfilePhoto = null;
          });
        }
      }
    } catch (e) {
      print('Error fetching other user profile photo: $e');
      if (mounted) {
        setState(() {
          otherUserProfilePhoto = null;
        });
      }
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
                myProfilePhoto: myProfilePhoto,
                otherUserProfilePhoto: otherUserProfilePhoto,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            _buildAppBarAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.name} ${widget.lastName}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: _showReportDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: _messages.length,
              itemBuilder: (_, int index) => _messages[index],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarAvatar() {
    if (otherUserProfilePhoto == null || otherUserProfilePhoto!.isEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey[300],
        child: const Icon(
          Icons.person,
          color: Colors.grey,
          size: 20,
        ),
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: Image.network(
          otherUserProfilePhoto!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              color: Colors.grey,
              size: 20,
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: '${context.loc.send_message}',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.green[600],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isSendingMessage ? Icons.hourglass_empty : Icons.send,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _isSendingMessage ? null : () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isMe;
  final String? myProfilePhoto;
  final String? otherUserProfilePhoto;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isMe,
    this.myProfilePhoto,
    this.otherUserProfilePhoto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(otherUserProfilePhoto),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: isMe ? Colors.green[500] : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(myProfilePhoto),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String? profilePhotoUrl) {
    if (profilePhotoUrl == null || profilePhotoUrl.isEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[300],
        child: const Icon(
          Icons.person,
          color: Colors.grey,
          size: 18,
        ),
      );
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: Image.network(
          profilePhotoUrl,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              color: Colors.grey,
              size: 18,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Icon(
              Icons.person,
              color: Colors.grey,
              size: 18,
            );
          },
        ),
      ),
    );
  }
}