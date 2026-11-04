import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_app/constants.dart';
import 'package:task_app/database_services.dart';
import 'package:task_app/modles/event_modle.dart';
import 'package:task_app/widgets/event_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final DatabaseService _databaseService = DatabaseService();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Controllers & Variables for filtering
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  final List _categories = [
    {
      'name': 'Entertainment',
      'icon': Icons.movie_rounded,
      'color': Colors.purple,
      'gradient': [Colors.purple.shade400, Colors.deepPurple.shade700],
    },
    {
      'name': 'Technology',
      'icon': Icons.devices_rounded,
      'color': Colors.blue,
      'gradient': [Colors.blue.shade400, Colors.indigo.shade600],
    },
    {
      'name': 'Business',
      'icon': Icons.business_center_rounded,
      'color': Colors.green,
      'gradient': [Colors.green.shade400, Colors.teal.shade700],
    },
    {
      'name': 'Education',
      'icon': Icons.school_rounded,
      'color': Colors.orange,
      'gradient': [Colors.orange.shade400, Colors.deepOrange.shade700],
    },
    {
      'name': 'Sports',
      'icon': Icons.sports_soccer_rounded,
      'color': Colors.red,
      'gradient': [Colors.red.shade400, Colors.pink.shade700],
    },
    {
      'name': 'Other',
      'icon': Icons.category_rounded,
      'color': Colors.teal,
      'gradient': [Colors.teal.shade400, Colors.blueGrey.shade700],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Explore Events',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedCategory != null || _searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset Filters',
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inline Search Bar (No full-screen view popup)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search events by title or category...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.lightBlue,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20.0),

            // Header for Categories
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory == null
                      ? 'Categories'
                      : 'Category: $_selectedCategory',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedCategory != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                      });
                    },
                    child: const Text('Clear Filter'),
                  ),
              ],
            ),

            const SizedBox(height: 10.0),

            // Creative Gradient Categories Horizontal ListView
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final bool isSelected = _selectedCategory == category['name'];

                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (_selectedCategory == category['name']) {
                            _selectedCategory = null; // Toggle off
                          } else {
                            _selectedCategory = category['name'];
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(16.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: category['gradient'],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? category['color'].withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.03),
                              blurRadius: isSelected ? 8 : 4,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : category['color'].withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                category['icon'],
                                size: 22.0,
                                color: isSelected
                                    ? Colors.white
                                    : category['color'],
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              category['name'],
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11.0,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10.0),
            const Text(
              'Events',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),

            // Events List with Category and Text Search Filter Support
            Expanded(
              child: StreamBuilder<List<EventModel>>(
                stream: _databaseService.streamEvents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading events: ${snapshot.error}'),
                    );
                  }

                  final allEvents = snapshot.data ?? [];

                  // Combined Filtering (Category + Search Query)
                  final filteredEvents = allEvents.where((event) {
                    bool matchesCategory =
                        _selectedCategory == null ||
                        event.category.toLowerCase() ==
                            _selectedCategory!.toLowerCase();

                    bool matchesSearch =
                        _searchQuery.isEmpty ||
                        event.title.toLowerCase().contains(_searchQuery) ||
                        event.category.toLowerCase().contains(_searchQuery);

                    return matchesCategory && matchesSearch;
                  }).toList();

                  if (filteredEvents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No events found matching your filter.',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = filteredEvents[index];

                      return StreamBuilder<int>(
                        stream: _databaseService.streamEventParticipantsCount(
                          event.id,
                        ),
                        builder: (context, countSnapshot) {
                          int joinedCount = countSnapshot.data ?? 0;
                          bool isEventFull = joinedCount >= event.maxAttendees;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: EventCard(
                              event: event,
                              databaseService: _databaseService,
                              actionButton: ElevatedButton.icon(
                                onPressed: isEventFull
                                    ? null
                                    : () async {
                                        String message = await _databaseService
                                            .joinEventWithModel(
                                              eventId: event.id,
                                              userId: currentUserId,
                                            );

                                        if (!context.mounted) return;

                                        bool isSuccess = message.contains(
                                          'Successfully',
                                        );

                                        AppConstants.showCustomSnackBar(
                                          context,
                                          message,
                                          isError: !isSuccess,
                                        );
                                      },
                                icon: Icon(
                                  isEventFull ? Icons.block : Icons.person_add,
                                  size: 16,
                                ),
                                label: Text(
                                  isEventFull ? 'Event Full' : 'Join Event',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isEventFull
                                      ? Colors.grey.shade400
                                      : Colors.lightBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
