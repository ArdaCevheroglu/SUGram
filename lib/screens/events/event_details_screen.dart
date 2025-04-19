import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../view_models/event_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../profile/profile_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
      await eventViewModel.getEventById(widget.eventId);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToOrganizerProfile() {
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    if (eventViewModel.selectedEvent != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            userId: eventViewModel.selectedEvent!.organizerId,
          ),
        ),
      );
    }
  }

  Future<void> _attendEvent() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    
    if (authViewModel.currentUser != null && eventViewModel.selectedEvent != null) {
      await eventViewModel.attendEvent(
        eventViewModel.selectedEvent!.id,
        authViewModel.currentUser!.id,
      );
    }
  }

  Future<void> _cancelAttendance() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    
    if (authViewModel.currentUser != null && eventViewModel.selectedEvent != null) {
      await eventViewModel.cancelAttendance(
        eventViewModel.selectedEvent!.id,
        authViewModel.currentUser!.id,
      );
    }
  }

  Future<void> _markInterested() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    
    if (authViewModel.currentUser != null && eventViewModel.selectedEvent != null) {
      await eventViewModel.markInterested(
        eventViewModel.selectedEvent!.id,
        authViewModel.currentUser!.id,
      );
    }
  }

  Future<void> _removeInterest() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    
    if (authViewModel.currentUser != null && eventViewModel.selectedEvent != null) {
      await eventViewModel.removeInterest(
        eventViewModel.selectedEvent!.id,
        authViewModel.currentUser!.id,
      );
    }
  }

  void _shareEvent() {
    // TODO: Implement share event
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventViewModel = Provider.of<EventViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final event = eventViewModel.selectedEvent;
    
    if (event == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Event Details'),
        ),
        body: const Center(
          child: Text('Event not found'),
        ),
      );
    }

    final isOrganizer = authViewModel.currentUser?.id == event.organizerId;
    final isAttending = event.attendees.contains(authViewModel.currentUser?.id);
    final isInterested = event.interestedUsers.contains(authViewModel.currentUser?.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with event image
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: event.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.event,
                          size: 80.0,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareEvent,
              ),
            ],
          ),
          
          // Event details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event title and category
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Event time
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 20.0,
                        color: AppTheme.secondaryTextColor,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          DateFormatter.formatEventDateRange(
                            event.startTime,
                            event.endTime,
                          ),
                          style: const TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  
                  // Event location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 20.0,
                        color: AppTheme.secondaryTextColor,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  
                  // Event organizer
                  InkWell(
                    onTap: _navigateToOrganizerProfile,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 20.0,
                          color: AppTheme.secondaryTextColor,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            'Organized by ${event.organizer}',
                            style: const TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  
                  // Event description
                  const Text(
                    'About',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  
                  // Attendees
                  Row(
                    children: [
                      const Text(
                        'Attendees',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        '(${event.attendees.length})',
                        style: const TextStyle(
                          color: AppTheme.secondaryTextColor,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  
                  // Attendee list (to be implemented with actual user profiles)
                  Container(
                    height: 60.0,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: event.attendees.isEmpty
                        ? const Center(
                            child: Text(
                              'No attendees yet',
                              style: TextStyle(
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                          )
                        : const Center(
                            child: Text(
                              'Attendee list will be displayed here',
                              style: TextStyle(
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 32.0),
                  
                  // Action buttons
                  if (!isOrganizer) ...[
                    Row(
                      children: [
                        Expanded(
                          child: isAttending
                              ? ElevatedButton.icon(
                                  onPressed: _cancelAttendance,
                                  icon: const Icon(Icons.check),
                                  label: const Text('Attending'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _attendEvent,
                                  child: const Text('Attend'),
                                ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: isInterested
                              ? OutlinedButton.icon(
                                  onPressed: _removeInterest,
                                  icon: const Icon(Icons.star),
                                  label: const Text('Interested'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: _markInterested,
                                  icon: const Icon(Icons.star_border),
                                  label: const Text('Interested'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.textColor,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}