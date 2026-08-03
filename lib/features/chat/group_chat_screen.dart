import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/auth_service.dart';
import 'models/message_model.dart';
import 'models/group_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'full_screen_image_screen.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupModel group;
  final Gradient gradient;

  const GroupChatScreen({
    super.key,
    required this.group,
    required this.gradient,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final ScrollController _scrollController = ScrollController();
  late final Stream<List<MessageModel>> _messagesStream;

  // Search state
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Reply state
  MessageModel? _replyingMessage;

  @override
  void initState() {
    super.initState();
    _messagesStream = ChatService().getGroupMessages(widget.group.id);
    _joinGroupIfNeeded();
  }

  void _joinGroupIfNeeded() async {
    final currentUserId = AuthService().currentUser?.uid;
    if (currentUserId != null && !widget.group.members.contains(currentUserId)) {
      try {
        await ChatService().joinGroup(widget.group.id, currentUserId);
      } catch (e) {
        debugPrint('Error auto-joining group: $e');
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatMemberCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k'.replaceAll('.0k', 'k');
    }
    return count.toString();
  }

  void _sendMessage(String text, File? file, String? fileName, String? fileType) async {
    final currentUser = AuthService().currentUser;
    final senderId = currentUser?.uid ?? 'unknown_id';
    final senderName = currentUser?.displayName ??
        currentUser?.email?.split('@').first ??
        'Student';
    final senderPhotoUrl = currentUser?.photoURL;

    final String? repliedText = _replyingMessage?.text.isNotEmpty == true
        ? _replyingMessage?.text
        : (_replyingMessage?.fileType == 'image' ? '📸 Photo' : (_replyingMessage?.fileType != null ? '📁 File' : null));
    final String? repliedSender = _replyingMessage?.senderName;

    // Reset reply state
    setState(() {
      _replyingMessage = null;
    });

    try {
      await ChatService().sendMessage(
        widget.group.id,
        text,
        senderId,
        senderName,
        senderPhotoUrl: senderPhotoUrl,
        file: file,
        fileName: fileName,
        fileType: fileType,
        repliedToText: repliedText,
        repliedToSender: repliedSender,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_occurred'.tr())),
        );
      }
    }
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

  void _showMsgActions(MessageModel message) {
    final currentUserId = AuthService().currentUser?.uid;
    final isMe = message.senderId == currentUserId;

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
              leading: const Icon(Icons.reply_rounded, color: Colors.blue),
              title: Text('reply'.tr()),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyingMessage = message;
                });
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                title: Text('delete'.tr()),
                onTap: () async {
                  Navigator.pop(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('delete_message_title'.tr()),
                      content: Text('delete_message_confirm'.tr()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('cancel'.tr()),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'delete'.tr(),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await ChatService().deleteMessage(widget.group.id, message.messageId);
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('error_occurred'.tr())),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _cancelReply() {
    setState(() {
      _replyingMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: widget.gradient),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'search'.tr(),
                  hintStyle: const TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
              )
            : Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Text(
                      widget.group.name.tr().isNotEmpty
                          ? widget.group.name.tr()[0]
                          : widget.group.name[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.name.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_formatMemberCount(widget.group.members.length)} ${'group_members'.tr()}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                debugPrint('Open settings for group: ${widget.group.id}');
              },
            ),
          ],
        ],
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
            ..._buildFloatingIcons(),
            Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('error_occurred'.tr()));
                      }
                      final allMessages = snapshot.data ?? [];

                      // Filter messages based on search query locally
                      final messages = _searchQuery.isEmpty
                          ? allMessages
                          : allMessages
                              .where((msg) => msg.text
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()))
                              .toList();

                      // Scroll to bottom when first loaded or new messages arrive (only if not searching, to avoid scroll disruption when typing)
                      if (_searchQuery.isEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToBottom(),
                        );
                      }

                      if (messages.isEmpty) {
                        return Center(
                          child: Opacity(
                            opacity: 0.5,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isNotEmpty
                                      ? Icons.search_off
                                      : Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.deepPurple,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'no_results_found'.tr()
                                      : 'Start the conversation!',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return _buildMessageBubble(msg);
                        },
                      );
                    },
                  ),
                ),
                ChatInputArea(
                  onSend: _sendMessage,
                  replyingMessage: _replyingMessage,
                  onCancelReply: _cancelReply,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg) {
    final currentUserId = AuthService().currentUser?.uid;
    bool isMe = msg.senderId == currentUserId;
    return FadeInUp(
      key: ValueKey(msg.messageId),
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: msg.senderPhotoUrl != null && msg.senderPhotoUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(msg.senderPhotoUrl!)
                    : null,
                backgroundColor: widget.gradient.colors.first.withValues(
                  alpha: 0.2,
                ),
                child: msg.senderPhotoUrl == null || msg.senderPhotoUrl!.isEmpty
                    ? Text(
                        msg.senderName.isNotEmpty ? msg.senderName[0] : 'S',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.gradient.colors.first,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: GestureDetector(
                onLongPress: () => _showMsgActions(msg),
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
                          msg.senderName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      if (msg.repliedToText != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 6, top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: Directionality.of(context) == ui.TextDirection.ltr
                                  ? BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 3,
                                    )
                                  : BorderSide.none,
                              right: Directionality.of(context) == ui.TextDirection.rtl
                                  ? BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 3,
                                    )
                                  : BorderSide.none,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.repliedToSender ?? 'User',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                msg.repliedToText!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (msg.fileName != null || msg.fileUrl != null)
                        _buildMessageAttachment(msg),
                      if (msg.text.isNotEmpty)
                        Text(
                          msg.text,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          DateFormat('hh:mm a').format(msg.timestamp.toDate()),
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

  Widget _buildMessageAttachment(MessageModel message) {
    bool isImage = message.fileType == 'image';
    if (isImage) {
      final hasLocalFile = message.localFilePath != null && message.localFilePath!.isNotEmpty;
      
      Widget imageWidget;
      if (message.isUploading && hasLocalFile) {
        // Optimistic local image viewing
        imageWidget = Stack(
          alignment: Alignment.center,
          children: [
            Image.file(
              File(message.localFilePath!),
              width: 250,
              height: 300,
              fit: BoxFit.cover,
            ),
            Container(
              width: 250,
              height: 300,
              color: Colors.black.withValues(alpha: 0.3), // Dark overlay
            ),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ],
        );
      } else if (message.fileUrl != null) {
        // Finalized network image viewing
        imageWidget = CachedNetworkImage(
          key: ValueKey('img_${message.messageId}'),
          imageUrl: message.fileUrl!,
          width: 250,
          height: 300,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox(
            width: 250,
            height: 300,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => const SizedBox(
            width: 250,
            height: 300,
            child: Center(
              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
            ),
          ),
        );
      } else {
        // Fallback placeholder
        imageWidget = const SizedBox(
          width: 250,
          height: 300,
          child: Center(
            child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: message.fileUrl != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageScreen(
                        imageUrl: message.fileUrl!,
                        heroTag: message.messageId,
                      ),
                    ),
                  );
                }
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Hero(
              tag: message.messageId,
              child: imageWidget,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withValues(alpha: 0.05),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(
          message.fileType == 'video'
              ? Icons.videocam
              : message.fileType == 'image'
                  ? Icons.image
                  : Icons.insert_drive_file,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          message.fileName ?? 'File',
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: message.fileUrl != null
            ? () {
                debugPrint('Open attachment URL: ${message.fileUrl}');
              }
            : null,
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

class ChatInputArea extends StatefulWidget {
  final Function(String text, File? file, String? fileName, String? fileType) onSend;
  final MessageModel? replyingMessage;
  final VoidCallback onCancelReply;

  const ChatInputArea({
    super.key,
    required this.onSend,
    this.replyingMessage,
    required this.onCancelReply,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  File? _attachedFile;
  String? _attachedFileName;
  String? _attachedFileType;
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showEmoji = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachedFile == null) return;
    
    widget.onSend(text, _attachedFile, _attachedFileName, _attachedFileType);

    setState(() {
      _controller.clear();
      _attachedFile = null;
      _attachedFileName = null;
      _attachedFileType = null;
      _showEmoji = false;
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
    final primaryColor = Theme.of(context).primaryColor;
    return PopScope(
      canPop: !_showEmoji,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_showEmoji) {
          setState(() {
            _showEmoji = false;
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Replying banner
          if (widget.replyingMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                border: Border(
                  left: BorderSide(
                    color: primaryColor,
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.replyingMessage!.senderName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.replyingMessage!.text.isNotEmpty
                              ? widget.replyingMessage!.text
                              : (widget.replyingMessage!.fileType == 'image'
                                  ? '📸 Photo'
                                  : '📁 File'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: widget.onCancelReply,
                  ),
                ],
              ),
            ),
          // Input bar
          Container(
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
                                  color: primaryColor,
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
                                  _showEmoji ? Icons.keyboard : Icons.sentiment_satisfied_alt,
                                  color: primaryColor,
                                ),
                                onPressed: () {
                                  if (_showEmoji) {
                                    _focusNode.requestFocus();
                                  } else {
                                    _focusNode.unfocus();
                                    setState(() {
                                      _showEmoji = true;
                                    });
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.attach_file,
                                  color: primaryColor,
                                ),
                                onPressed: _pickAttachment,
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
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
                    onPressed: _handleSend,
                    mini: true,
                    backgroundColor: primaryColor,
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
          // Emoji picker panel
          if (_showEmoji)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                textEditingController: _controller,
              ),
            ),
        ],
      ),
    );
  }
}


