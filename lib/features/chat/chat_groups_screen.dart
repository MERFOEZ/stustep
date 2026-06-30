import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'group_chat_screen.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/auth_service.dart';
import 'models/group_model.dart';

class ChatGroupsScreen extends StatefulWidget {
  const ChatGroupsScreen({super.key});

  @override
  State<ChatGroupsScreen> createState() => _ChatGroupsScreenState();
}

class _ChatGroupsScreenState extends State<ChatGroupsScreen> {
  final Map<String, LinearGradient> _gradients = {
    'Engineering': const LinearGradient(
      colors: [Color(0xFF3F51B5), Color(0xFF2196F3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Medicine': const LinearGradient(
      colors: [Color(0xFFE91E63), Color(0xFFFF5252)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Default': const LinearGradient(
      colors: [Color(0xFF6200EE), Color(0xFF9C27B0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  };

  @override
  void initState() {
    super.initState();
    _initializeGroups();
  }

  void _initializeGroups() async {
    await ChatService().initializeDefaultGroups();
  }

  LinearGradient _getGradient(GroupModel group) {
    if (group.category == 'Engineering') return _gradients['Engineering']!;
    if (group.category == 'Medicine') return _gradients['Medicine']!;
    return _gradients['Default']!;
  }

  String _formatMemberCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k'.replaceAll('.0k', 'k');
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService().currentUser?.uid;
    final isArabic = EasyLocalization.of(context)?.currentLocale?.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'groups'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6200EE), Color(0xFF9C27B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFF6200EE).withValues(alpha: 0.03),
            ],
          ),
        ),
        child: StreamBuilder<List<GroupModel>>(
          stream: ChatService().getGroups(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('error_occurred'.tr()));
            }
            final groups = snapshot.data ?? [];
            if (groups.isEmpty) {
              return Center(
                child: Text(
                  'no_groups_found'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final gradient = _getGradient(group);
                final isJoined = currentUserId != null && group.members.contains(currentUserId);

                return BounceInLeft(
                  delay: Duration(milliseconds: index * 100),
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.colors.first.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        PositionedDirectional(
                          end: -24,
                          top: -24,
                          child: Opacity(
                            opacity: 0.08,
                            child: Icon(
                              group.category == 'Engineering'
                                  ? Icons.engineering_rounded
                                  : Icons.medical_services_rounded,
                              size: 140,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        group.category == 'Engineering'
                                            ? Icons.architecture_rounded
                                            : Icons.health_and_safety_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          group.name,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black26,
                                                offset: Offset(0, 2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          group.description ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withValues(alpha: 0.85),
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_alt_rounded,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_formatMemberCount(group.members.length)} ${'group_members'.tr()}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: gradient.colors.first,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    elevation: 2,
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (isJoined) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => GroupChatScreen(
                                            group: group,
                                            gradient: gradient,
                                          ),
                                        ),
                                      );
                                    } else {
                                      if (currentUserId != null) {
                                        try {
                                          await ChatService().joinGroup(group.id, currentUserId);
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('error_occurred'.tr())),
                                            );
                                          }
                                        }
                                      }
                                    }
                                  },
                                  child: Text(
                                    isJoined
                                        ? (isArabic ? 'دخول المحادثة' : 'Enter Chat')
                                        : (isArabic ? 'انضمام' : 'Join'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

