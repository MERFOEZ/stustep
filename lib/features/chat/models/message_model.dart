import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final Timestamp timestamp;
  final String? fileName;
  final String? fileType;
  final String? fileUrl;
  final String? localFilePath;
  final bool isUploading;
  final String? repliedToText;
  final String? repliedToSender;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.text,
    required this.timestamp,
    this.fileName,
    this.fileType,
    this.fileUrl,
    this.localFilePath,
    this.isUploading = false,
    this.repliedToText,
    this.repliedToSender,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel(
      messageId: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'],
      text: data['text'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? data['timestamp'] as Timestamp
          : Timestamp.now(),
      fileName: data['fileName'],
      fileType: data['fileType'],
      fileUrl: data['fileUrl'],
      localFilePath: data['localFilePath'],
      isUploading: data['isUploading'] ?? false,
      repliedToText: data['repliedToText'],
      repliedToSender: data['repliedToSender'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      if (senderPhotoUrl != null) 'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'timestamp': timestamp,
      if (fileName != null) 'fileName': fileName,
      if (fileType != null) 'fileType': fileType,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (localFilePath != null) 'localFilePath': localFilePath,
      'isUploading': isUploading,
      if (repliedToText != null) 'repliedToText': repliedToText,
      if (repliedToSender != null) 'repliedToSender': repliedToSender,
    };
  }
}

