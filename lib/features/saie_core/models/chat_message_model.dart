/// StuStep — ChatMessageModel
library;

/// Sender of a chat message.
enum MessageSender { user, assistant }

/// A single message in a conversation — stored locally.
///
/// Includes a `qualityFlag` field (null by default) reserved for
/// future fine-tuning dataset curation. A human reviewer sets it to
/// `true` (good sample) or `false` (exclude) before export.
class ChatMessageModel {
  const ChatMessageModel({
    required this.messageId,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.qualityFlag,
  });

  final String messageId;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;

  /// null = unreviewed | true = keep for fine-tuning | false = exclude.
  final bool? qualityFlag;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        messageId: json['message_id'] as String,
        sender: json['sender'] == 'user'
            ? MessageSender.user
            : MessageSender.assistant,
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        qualityFlag: json['quality_flag'] as bool?,
      );

  Map<String, dynamic> toJson() => {
        'message_id': messageId,
        'sender': sender == MessageSender.user ? 'user' : 'assistant',
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'quality_flag': qualityFlag,
      };

  ChatMessageModel copyWith({bool? qualityFlag}) => ChatMessageModel(
        messageId: messageId,
        sender: sender,
        text: text,
        timestamp: timestamp,
        qualityFlag: qualityFlag ?? this.qualityFlag,
      );
}
