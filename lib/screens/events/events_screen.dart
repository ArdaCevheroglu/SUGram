import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/event_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../theme/app_theme.dart';
import '../../models/event_model.dart';
import '../../utils/date_formatter.dart';
import 'event_details_screen.dart';
import 'create_event_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = [
    'All',
    'Academic',
    'Social',
    'Club',
    'Sports',
    'Other',
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    await eventViewModel.getUpcomingEvents();
  }

  Future<void> _refreshEvents() async {
    await _loadEvents();
  }

  void _navigateToEventDetails(String eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(eventId: eventId),
      ),
    ).then((_) => _refreshEvents());
  }

  void _navigateToCreateEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEventScreen(),
      ),
    ).then((_) => _refreshEvents());
  }

  Future<void> _attendEvent(String eventId) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    
    if (authViewModel.currentUser != null) {
      await eventViewModel.attendEvent(eventId, authViewModel.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventViewModel = Provider.of<EventViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToCreateEvent,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.secondaryTextColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
          onTap: (index) {
            // Filter events by category when tab is tapped
            if (index == 0) {
              // "All" category
              _loadEvents();
            } else {
              // Other categories
              eventViewModel.getEventsByCategory(_categories[index]);
            }
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        child: eventViewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : eventViewModel.upcomingEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_busy,
                          size: 80.0,
                          color: AppTheme.secondaryTextColor,
                        ),
                        const SizedBox(height: 16.0),
                        const Text(
                          'No upcoming events',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        const Text(
                          'Check back later or create a new event',
                          style: TextStyle(
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        ElevatedButton(
                          onPressed: _navigateToCreateEvent,
                          child: const Text('Create Event'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: eventViewModel.upcomingEvents.length,
                    itemBuilder: (context, index) {
                      final event = eventViewModel.upcomingEvents[index];
                      return _buildEventCard(
                        event, 
                        authViewModel.currentUser?.id ?? '',
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateEvent,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventCard(EventModel event, String currentUserId) {
    final bool isAttending = event.attendees.contains(currentUserId);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () => _navigateToEventDetails(event.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image if available
            if (event.imageUrl.isNotEmpty)
              Container(
                height: 150.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(event.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          event.category,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormatter.formatDate(event.startTime),
                        style: const TextStyle(
                          color: AppTheme.secondaryTextColor,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  
                  // Event title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  
                  // Event time
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16.0,
                        color: AppTheme.secondaryTextColor,
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          DateFormatter.formatEventDateRange(
                            event.startTime,
                            event.endTime,
                          ),
                          style: const TextStyle(
                            color: AppTheme.secondaryTextColor,
                            fontSize: 14.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  
                  // Event location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16.0,
                        color: AppTheme.secondaryTextColor,
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(
                            color: AppTheme.secondaryTextColor,
                            fontSize: 14.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  
                  // Event organizer
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 16.0,
                        color: AppTheme.secondaryTextColor,
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          'Organized by ${event.organizer}',
                          style: const TextStyle(
                            color: AppTheme.secondaryTextColor,
                            fontSize: 14.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Attendees count and action button
                  Row(
                    children: [
                      Text(
                        '${event.attendees.length} attending',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      isAttending
                          ? OutlinedButton.icon(
                              onPressed: () => _navigateToEventDetails(event.id),
                              icon: const Icon(Icons.check),
                              label: const Text('Attending'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () => _attendEvent(event.id),
                              child: const Text('Attend'),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}