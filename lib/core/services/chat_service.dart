import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/chat/models/group_model.dart';
import '../../features/chat/models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton instance
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  /// Listen to groups in real-time filtered by category.
  /// Sorts by lastMessageTime descending in-memory to prevent requiring composite indexes.
  static final List<GroupModel> defaultGroups = [
    GroupModel(
      id: 'engineering_group',
      name: 'مناقشة الهندسة ⚙️',
      category: 'Engineering',
      description: 'تجمع النخبة الهندسية والمشاريع التقنية',
      members: [],
      lastMessage: '',
      lastMessageTime: Timestamp.now(),
    ),
    GroupModel(
      id: 'medical_group',
      name: 'مناقشة الطبية 🩺',
      category: 'Medicine',
      description: 'ملتقى أطباء المستقبل والعلوم الصحية',
      members: [],
      lastMessage: '',
      lastMessageTime: Timestamp.now(),
    ),
  ];

  /// Listen to all groups in Firestore.
  Stream<List<GroupModel>> getGroups() {
    return _firestore
        .collection('groups')
        .snapshots()
        .map((snapshot) {
      final groups = snapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc))
          .toList();
      if (groups.isEmpty) {
        return defaultGroups;
      }
      // Sort descending by lastMessageTime
      groups.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return groups;
    }).handleError((e) {
      debugPrint('Error fetching groups from Firestore: $e');
      return defaultGroups;
    });
  }

  /// Listen to messages inside a specific group.
  /// Ordered by timestamp ascending.
  Stream<List<MessageModel>> getGroupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Upload file to Cloudinary and get download URL
  Future<String> uploadFile(File file) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/dwms0orf1/auto/upload');
    final request = http.MultipartRequest('POST', uri);
    
    request.fields['upload_preset'] = 'h44lwdga';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final secureUrl = responseData['secure_url'] as String?;
      if (secureUrl != null) {
        return secureUrl;
      }
      throw Exception('Cloudinary upload succeeded but secure_url was null');
    } else {
      throw Exception('Failed to upload file to Cloudinary: ${response.statusCode} - ${response.body}');
    }
  }

  /// Send a message inside a group and atomically update parent group info.
  Future<void> sendMessage(
    String groupId,
    String text,
    String senderId,
    String senderName, {
    String? senderPhotoUrl,
    File? file,
    String? fileName,
    String? fileType,
    String? repliedToText,
    String? repliedToSender,
  }) async {
    final messageRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc();

    final groupRef = _firestore.collection('groups').doc(groupId);
    final timestamp = Timestamp.now();

    if (file != null) {
      // Optimistic update: Write the message immediately with local path and uploading flag
      final messageData = {
        'senderId': senderId,
        'senderName': senderName,
        if (senderPhotoUrl != null) 'senderPhotoUrl': senderPhotoUrl,
        'text': text,
        'timestamp': timestamp,
        'localFilePath': file.path,
        'isUploading': true,
        if (fileName != null) 'fileName': fileName,
        if (fileType != null) 'fileType': fileType,
        if (repliedToText != null) 'repliedToText': repliedToText,
        if (repliedToSender != null) 'repliedToSender': repliedToSender,
      };

      final batch = _firestore.batch();
      batch.set(messageRef, messageData);
      batch.update(groupRef, {
        'lastMessage': fileType == 'image' ? '📸 Photo' : '📁 File',
        'lastMessageTime': timestamp,
      });

      await batch.commit();

      // Launch upload in the background (fire-and-forget/non-awaited)
      _uploadAndUpdateMessage(
        messageRef: messageRef,
        file: file,
      );
    } else {
      // Normal text message flow
      final messageData = {
        'senderId': senderId,
        'senderName': senderName,
        if (senderPhotoUrl != null) 'senderPhotoUrl': senderPhotoUrl,
        'text': text,
        'timestamp': timestamp,
        'isUploading': false,
        if (repliedToText != null) 'repliedToText': repliedToText,
        if (repliedToSender != null) 'repliedToSender': repliedToSender,
      };

      final batch = _firestore.batch();
      batch.set(messageRef, messageData);
      batch.update(groupRef, {
        'lastMessage': text,
        'lastMessageTime': timestamp,
      });

      await batch.commit();
    }
  }

  /// Helper to upload file in the background and update Firestore document when done.
  void _uploadAndUpdateMessage({
    required DocumentReference messageRef,
    required File file,
  }) async {
    try {
      final secureUrl = await uploadFile(file);
      await messageRef.update({
        'fileUrl': secureUrl,
        'localFilePath': FieldValue.delete(),
        'isUploading': false,
      });
    } catch (e) {
      debugPrint('Error uploading file in background: $e');
      // On failure, stop showing loading indicator
      await messageRef.update({
        'isUploading': false,
      });
    }
  }

  /// Delete a message permanently from Firestore.
  Future<void> deleteMessage(String groupId, String messageId) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }


  /// Add a user to the members array of a group in Firestore.
  Future<void> joinGroup(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  /// Initialize the two default academic groups if the collection is empty.
  Future<void> initializeDefaultGroups() async {
    try {
      final snapshot = await _firestore.collection('groups').limit(1).get();
      if (snapshot.docs.isEmpty) {
        final batch = _firestore.batch();

        final engDoc = _firestore.collection('groups').doc('engineering_group');
        batch.set(engDoc, {
          'name': 'مناقشة الهندسة ⚙️',
          'description': 'تجمع النخبة الهندسية والمشاريع التقنية',
          'category': 'Engineering',
          'members': <String>[],
          'lastMessage': '',
          'lastMessageTime': Timestamp.now(),
        });

        final medDoc = _firestore.collection('groups').doc('medical_group');
        batch.set(medDoc, {
          'name': 'مناقشة الطبية 🩺',
          'description': 'ملتقى أطباء المستقبل والعلوم الصحية',
          'category': 'Medicine',
          'members': <String>[],
          'lastMessage': '',
          'lastMessageTime': Timestamp.now(),
        });

        await batch.commit();
        debugPrint('Successfully initialized default academic groups.');
      }
    } catch (e) {
      debugPrint('Error initializing default groups: $e');
    }
  }
}
