import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String category;
  final List<String> members;
  final String lastMessage;
  final Timestamp lastMessageTime;
  final String? description;

  GroupModel({
    required this.id,
    required this.name,
    required this.category,
    required this.members,
    required this.lastMessage,
    required this.lastMessageTime,
    this.description,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'] is Timestamp
          ? data['lastMessageTime'] as Timestamp
          : Timestamp.now(),
      description: data['description'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'members': members,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      if (description != null) 'description': description,
    };
  }
}
