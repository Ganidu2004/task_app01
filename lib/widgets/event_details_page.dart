import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_app/constants.dart';
import 'package:task_app/database_services.dart';
import 'package:task_app/modles/comment_modle.dart';
import 'package:task_app/modles/event_modle.dart';
import 'package:task_app/modles/user_modle.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;
  final DatabaseService databaseService;
  final EventModel? initialEvent;

  const EventDetailPage({
    super.key,
    required this.eventId,
    required this.databaseService,
    this.initialEvent,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add a comment'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await widget.databaseService.addComment(
        uid: currentUserId,
        eventId: widget.eventId,
        commentText: text,
      );

      if (!mounted) return;

      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: FutureBuilder<EventModel?>(
        future: widget.databaseService.getEventById(widget.eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            if (widget.initialEvent != null) {
              return _buildEventUI(context, widget.initialEvent!);
            }
            return const Center(
              child: CircularProgressIndicator(color: Colors.lightBlueAccent),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading event: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final event = snapshot.data ?? widget.initialEvent;
          if (event == null) {
            return const Center(child: Text('Event details not found.'));
          }
          return _buildEventUI(context, event);
        },
      ),
    );
  }

  Widget _buildEventUI(BuildContext context, EventModel event) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Creative Hero Image Header with Parallax & Back Button
              SliverAppBar(
                expandedHeight: 280.0,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.white,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                        Image.network(
                          event.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: Colors.blueGrey.shade100,
                            child: const Icon(
                              Icons.broken_image,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.lightBlue.shade300,
                                Colors.blueAccent.shade700,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.event_note,
                            size: 90,
                            color: Colors.white,
                          ),
                        ),
                      // Gradient Overlay for readability
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Main Content Details Body
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0.0, -20.0, 0.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F6F9),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge & Attendees Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                event.category.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            StreamBuilder<int>(
                              stream: widget.databaseService
                                  .streamEventParticipantsCount(event.id),
                              builder: (context, countSnapshot) {
                                int joinedCount = countSnapshot.data ?? 0;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.people_alt_rounded,
                                        size: 16,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$joinedCount / ${event.maxAttendees} Joined',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Title
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Info Cards Grid Container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildInfoTile(
                                icon: Icons.calendar_month_rounded,
                                iconBg: Colors.green.shade50,
                                iconColor: Colors.green,
                                title: 'Date',
                                value: DateFormat(
                                  'EEEE, dd MMMM yyyy',
                                ).format(event.date),
                              ),
                              const Divider(height: 20, thickness: 0.8),
                              _buildInfoTile(
                                icon: Icons.schedule_rounded,
                                iconBg: Colors.blue.shade50,
                                iconColor: Colors.blueAccent,
                                title: 'Time',
                                value: event.time,
                              ),
                              const Divider(height: 20, thickness: 0.8),
                              _buildInfoTile(
                                icon: Icons.location_on_rounded,
                                iconBg: Colors.red.shade50,
                                iconColor: Colors.redAccent,
                                title: 'Location',
                                value: event.place,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Organizer Card
                        FutureBuilder<UserModel?>(
                          future: widget.databaseService.getUserData(
                            event.organizerId,
                          ),
                          builder: (context, userSnapshot) {
                            final user = userSnapshot.data;
                            final userName = user?.fullName ?? 'Organizer';
                            final userImage = user?.profileImageUrl;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.blueAccent
                                        .withValues(alpha: 0.1),
                                    backgroundImage:
                                        userImage != null &&
                                            userImage.isNotEmpty
                                        ? NetworkImage(userImage)
                                        : null,
                                    child:
                                        userImage == null || userImage.isEmpty
                                        ? const Icon(
                                            Icons.person_rounded,
                                            color: Colors.blueAccent,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Organized by',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Description Section
                        const Text(
                          'About Event',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.description,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Comments Title Header
                        Row(
                          children: const [
                            Icon(
                              Icons.forum_rounded,
                              color: Colors.blueAccent,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Discussion & Comments',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 3. Creative Comments Stream List
                        StreamBuilder<List<CommentModel>>(
                          stream: widget.databaseService.streamEventComments(
                            event.id,
                          ),
                          builder: (context, commentSnapshot) {
                            if (commentSnapshot.hasError) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Error loading comments: ${commentSnapshot.error}',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }

                            if (commentSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              );
                            }

                            final comments = commentSnapshot.data ?? [];
                            if (comments.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: const [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'No comments yet.',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Be the first to share your thoughts!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: comments.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final comment = comments[index];
                                final currentUserId =
                                    FirebaseAuth.instance.currentUser?.uid;
                                final bool isMyComment =
                                    currentUserId != null &&
                                    comment.uid == currentUserId;

                                return FutureBuilder<UserModel?>(
                                  future: widget.databaseService.getUserData(
                                    comment.uid,
                                  ),
                                  builder: (context, userSnap) {
                                    final user = userSnap.data;
                                    final userName = user?.fullName ?? 'User';
                                    final userImage = user?.profileImageUrl;

                                    return Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.015,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: Colors.blueAccent
                                                .withValues(alpha: 0.1),
                                            backgroundImage:
                                                userImage != null &&
                                                    userImage.isNotEmpty
                                                ? NetworkImage(userImage)
                                                : null,
                                            child:
                                                userImage == null ||
                                                    userImage.isEmpty
                                                ? const Icon(
                                                    Icons.person,
                                                    size: 18,
                                                    color: Colors.blueAccent,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      userName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                        color: Color(
                                                          0xFF1E293B,
                                                        ),
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          DateFormat(
                                                            'MMM d, h:mm a',
                                                          ).format(
                                                            comment.timestamp,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors
                                                                .grey
                                                                .shade500,
                                                          ),
                                                        ),

                                                        // User ge comment ekak nam witharak delete button eka pennanawa
                                                        if (isMyComment) ...[
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          PopupMenuButton<
                                                            String
                                                          >(
                                                            padding:
                                                                EdgeInsets.zero,
                                                            elevation: 4,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  30,
                                                                ),
                                                            icon: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    4,
                                                                  ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade100,
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                              child: const Icon(
                                                                Icons
                                                                    .more_vert_rounded,
                                                                size: 14,
                                                                color: Color(
                                                                  0xFF64748B,
                                                                ),
                                                              ),
                                                            ),
                                                            onSelected: (value) async {
                                                              if (value ==
                                                                  'delete') {
                                                                try {
                                                                  await widget
                                                                      .databaseService
                                                                      .deleteComment(
                                                                        event
                                                                            .id,
                                                                        comment
                                                                            .commentId,
                                                                      );

                                                                  if (context
                                                                      .mounted) {
                                                                    AppConstants.showCustomSnackBar(
                                                                      context,
                                                                      'Comment deleted successfully',
                                                                    );
                                                                  }
                                                                } catch (e) {
                                                                  if (context
                                                                      .mounted) {
                                                                    AppConstants.showCustomSnackBar(
                                                                      context,
                                                                      'Failed to delete: $e',
                                                                      isError:
                                                                          true,
                                                                    );
                                                                  }
                                                                }
                                                              }
                                                            },
                                                            itemBuilder:
                                                                (
                                                                  BuildContext
                                                                  context,
                                                                ) => [
                                                                  PopupMenuItem<
                                                                    String
                                                                  >(
                                                                    value:
                                                                        'delete',
                                                                    height: 36,
                                                                    child: Row(
                                                                      children: const [
                                                                        Icon(
                                                                          Icons
                                                                              .delete_outline_rounded,
                                                                          color:
                                                                              Colors.redAccent,
                                                                          size:
                                                                              16,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              8,
                                                                        ),
                                                                        Text(
                                                                          'Delete',
                                                                          style: TextStyle(
                                                                            color:
                                                                                Colors.redAccent,
                                                                            fontSize:
                                                                                12.5,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  comment.commentText,
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    height: 1.4,
                                                    color: Color(0xFF334155),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 4. Creative Sticky Bottom Comment Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a public comment...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(25),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: _isSending ? null : _sendComment,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Structured Info Row Helper
  Widget _buildInfoTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
