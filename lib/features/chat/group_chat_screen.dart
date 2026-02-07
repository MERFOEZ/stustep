import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupName;
  final Gradient gradient;

  const GroupChatScreen({
    super.key,
    required this.groupName,
    required this.gradient,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Media attachment state
  File? _attachedFile;
  String? _attachedFileName;
  String? _attachedFileType; // 'image', 'video', 'document'

  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'Ahmed',
      'message': 'السلام عليكم يا شباب، متى موعد التسليم؟',
      'isMe': false,
      'time': '10:30 AM',
    },
    {
      'sender': 'Sara',
      'message': 'وعليكم السلام، غداً الساعة 10 صباحاً.',
      'isMe': false,
      'time': '10:32 AM',
    },
    {
      'sender': 'system',
      'message': 'You joined the group',
      'isMe': false,
      'time': '10:35 AM',
      'isSystem': true,
    },
  ];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachedFile == null) return;

    setState(() {
      _messages.add({
        'sender': 'You',
        'message': text,
        'isMe': true,
        'time': DateFormat('hh:mm a').format(DateTime.now()),
        'filePath': _attachedFile?.path,
        'fileName': _attachedFileName,
        'fileType': _attachedFileType,
      });
      _controller.clear();
      _attachedFile = null;
      _attachedFileName = null;
      _attachedFileType = null;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAttachment() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.purple),
              title: Text('choose_image'.tr()),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
                if (result != null) {
                  setState(() {
                    _attachedFile = File(result.files.single.path!);
                    _attachedFileName = result.files.single.name;
                    _attachedFileType = 'image';
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.red),
              title: Text('choose_video'.tr()),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.video,
                );
                if (result != null) {
                  setState(() {
                    _attachedFile = File(result.files.single.path!);
                    _attachedFileName = result.files.single.name;
                    _attachedFileType = 'video';
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
              title: Text('choose_docs'.tr()),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles();
                if (result != null) {
                  setState(() {
                    _attachedFile = File(result.files.single.path!);
                    _attachedFileName = result.files.single.name;
                    _attachedFileType = 'document';
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: widget.gradient),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(
                widget.groupName[0],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '25 members online',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0C3FC), // Pastel Purple
              Color(0xFF8EC5FC), // Light Blue
              Color(0xFFC2FFD8), // Mint Green
              Color(0xFFFFD194), // Soft Orange/Peach
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Recreating the 3D floating icons look from the image
            ..._buildFloatingIcons(),
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      if (msg['isSystem'] == true) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Text(
                              msg['message'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }
                      return _buildMessageBubble(msg);
                    },
                  ),
                ),
                _buildInputArea(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    bool isMe = msg['isMe'];
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: widget.gradient.colors.first.withValues(
                  alpha: 0.2,
                ),
                child: Text(
                  msg['sender'][0],
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.gradient.colors.first,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xFFDCF8C6) // WhatsApp light green
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(15),
                    topRight: const Radius.circular(15),
                    bottomLeft: Radius.circular(isMe ? 15 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Text(
                        msg['sender'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    if (msg['filePath'] != null) _buildMessageAttachment(msg),
                    Text(
                      msg['message'],
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        msg['time'],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 14, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageAttachment(Map<String, dynamic> message) {
    bool isImage = message['fileType'] == 'image';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withValues(alpha: 0.05),
      ),
      clipBehavior: Clip.antiAlias,
      child: isImage
          ? Image.file(
              File(message['filePath']),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
            )
          : ListTile(
              leading: Icon(
                message['fileType'] == 'video'
                    ? Icons.videocam
                    : Icons.insert_drive_file,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(
                message['fileName'] ?? 'File',
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_attachedFile != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _attachedFileType == 'image'
                                ? Icons.image
                                : _attachedFileType == 'video'
                                ? Icons.videocam
                                : Icons.insert_drive_file,
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _attachedFileName!,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() {
                              _attachedFile = null;
                              _attachedFileName = null;
                              _attachedFileType = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.attach_file,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: _pickAttachment,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: _sendMessage,
              mini: true,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingIcons() {
    final List<Map<String, dynamic>> iconConfig = [
      {
        'icon': Icons.menu_book_rounded,
        'top': 100.0,
        'left': 40.0,
        'color': Colors.deepPurpleAccent,
        'size': 50.0,
      },
      {
        'icon': Icons.star_rounded,
        'top': 150.0,
        'right': 80.0,
        'color': Colors.orangeAccent,
        'size': 35.0,
      },
      {
        'icon': Icons.school_rounded,
        'top': 250.0,
        'right': 40.0,
        'color': Colors.blueGrey,
        'size': 60.0,
      },
      {
        'icon': Icons.edit_note_rounded,
        'bottom': 350.0,
        'left': 60.0,
        'color': Colors.teal,
        'size': 55.0,
      },
      {
        'icon': Icons.auto_awesome_rounded,
        'bottom': 450.0,
        'right': 60.0,
        'color': Colors.amberAccent,
        'size': 40.0,
      },
      {
        'icon': Icons.menu_book_rounded,
        'bottom': 200.0,
        'left': 20.0,
        'color': Colors.purpleAccent,
        'size': 45.0,
      },
      {
        'icon': Icons.school_rounded,
        'bottom': 120.0,
        'right': 110.0,
        'color': Colors.deepPurple,
        'size': 50.0,
      },
      {
        'icon': Icons.star_rounded,
        'bottom': 80.0,
        'left': 90.0,
        'color': Colors.orange,
        'size': 30.0,
      },
    ];

    return iconConfig.map((config) {
      return Positioned(
        top: config['top'],
        bottom: config['bottom'],
        left: config['left'],
        right: config['right'],
        child: Opacity(
          opacity: 0.2,
          child: Icon(
            config['icon'],
            size: config['size'],
            color: config['color'],
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: const Offset(4, 4),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
