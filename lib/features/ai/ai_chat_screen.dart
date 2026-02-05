import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/ai_service.dart';
import 'package:animate_do/animate_do.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();

  AIModel _selectedModel = AIModel.deepseek;
  bool _isTyping = false;

  // New attachment state
  File? _attachedFile;
  String? _attachedFileName;
  String? _attachedFileType; // 'image', 'video', 'document'

  late AnimationController _fabController;

  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachedFile == null || _isTyping) return;

    String? base64Image;
    if (_attachedFile != null && (_attachedFileType == 'image')) {
      final bytes = await _attachedFile!.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    final String attachmentInfo = _attachedFileName != null
        ? "\n[Attachment: $_attachedFileName (${_attachedFileType})]"
        : "";

    setState(() {
      _messages.add({
        'role': 'user',
        'content': text + attachmentInfo,
        'filePath': _attachedFile?.path,
        'fileName': _attachedFileName,
        'fileType': _attachedFileType,
      });
      _controller.clear();
      _attachedFile = null;
      _attachedFileName = null;
      _attachedFileType = null;
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await _aiService.getChatResponse(
        text.isEmpty ? "ماذا يوجد في هذا الملف؟" : (text + attachmentInfo),
        _selectedModel,
        base64Image: base64Image,
      );
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({'role': 'assistant', 'content': response});
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'role': 'assistant',
            'content': 'خطأ في الاتصال. يرجى المحاولة مرة أخرى.',
          });
        });
        _scrollToBottom();
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message['role'] == 'user';
                  return FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: SlideInUp(
                      from: 30,
                      duration: const Duration(milliseconds: 400),
                      child: Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            gradient: isUser
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6200EE),
                                      Color(0xFF9C27B0),
                                    ],
                                  )
                                : null,
                            color: isUser ? null : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isUser ? 20 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isUser
                                    ? const Color(
                                        0xFF6200EE,
                                      ).withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: isUser
                                ? null
                                : Border.all(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isUser && message['filePath'] != null)
                                _buildMessageAttachment(message),
                              Text(
                                message['content'],
                                style: TextStyle(
                                  color: isUser ? Colors.white : null,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Pulse(
                      infinite: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'typing'.tr(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInputTextField(),
                    const SizedBox(height: 8),
                    if (_attachedFile != null) _buildImagePreview(),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.add_rounded,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: _pickAttachment,
                        ),
                        _buildModelChip(_selectedModel),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.mic_none_rounded,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {},
                        ),
                        _buildSendButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputTextField() {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'أسال الذكاء الاصطناعي أي شيء '.tr(),
        hintStyle: TextStyle(
          color: Theme.of(context).hintColor.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onSubmitted: (_) => _sendMessage(),
      maxLines: null,
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _sendMessage,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _isTyping ? Colors.red : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _isTyping ? Icons.stop_rounded : Icons.arrow_upward_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildModelChip(AIModel model) {
    final label = model.name.toUpperCase();
    return GestureDetector(
      onTap: () {
        // Show model selection dialog/menu
        _showModelPicker();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey[600],
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label == 'GEMINI' ? 'Gemini 3 Flash' : label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModelPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).scaffoldBackgroundColor.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'select_model'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AIModel.values.map((model) {
                      final isSelected = _selectedModel == model;
                      final width = (constraints.maxWidth - 12) / 2;
                      return FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        delay: Duration(milliseconds: model.index * 100),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedModel = model);
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: width,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1)
                                  : Theme.of(
                                      context,
                                    ).cardColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _getModelIcon(model),
                                const SizedBox(height: 12),
                                Text(
                                  model.name.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getModelDescription(model),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getModelIcon(AIModel model) {
    String assetPath;
    switch (model) {
      case AIModel.deepseek:
        assetPath = 'assets/images/deepseek_logo.png';
        break;
      case AIModel.gemini:
        assetPath = 'assets/images/gemini_logo.png';
        break;
      case AIModel.claude:
        assetPath = 'assets/images/claude_logo.jpg';
        break;
      case AIModel.gpt:
        assetPath = 'assets/images/gpt_logo.png';
        break;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        assetPath,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.smart_toy, size: 32, color: Colors.grey),
      ),
    );
  }

  String _getModelDescription(AIModel model) {
    switch (model) {
      case AIModel.deepseek:
        return 'DeepSeek R1';
      case AIModel.gemini:
        return 'Multi-modal';
      case AIModel.claude:
        return 'Creative & Fast';
      case AIModel.gpt:
        return 'GPT-4o Mini';
    }
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      height: 100,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
            child: _attachedFileType == 'image'
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(_attachedFile!, fit: BoxFit.cover),
                  )
                : Icon(
                    _attachedFileType == 'video'
                        ? Icons.play_circle_filled
                        : Icons.insert_drive_file,
                    color: Theme.of(context).primaryColor,
                    size: 40,
                  ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () => setState(() {
                _attachedFile = null;
                _attachedFileName = null;
                _attachedFileType = null;
              }),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          if (_attachedFileName != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(15),
                  ),
                ),
                child: Text(
                  _attachedFileName!,
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageAttachment(Map<String, dynamic> message) {
    final type = message['fileType'];
    final path = message['filePath'];
    final name = message['fileName'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.black.withValues(alpha: 0.05),
          child: type == 'image'
              ? Image.file(
                  File(path),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                )
              : ListTile(
                  leading: Icon(
                    type == 'video'
                        ? Icons.play_circle_fill
                        : Icons.insert_drive_file,
                    color: Colors.white,
                  ),
                  title: Text(
                    name ?? "ملف",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
        ),
      ),
    );
  }
}
