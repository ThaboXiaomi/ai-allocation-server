import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/booking_providers.dart';
import '../models/booking.dart';

class BookingCalendarScreen extends ConsumerStatefulWidget {
  @override
  _BookingCalendarScreenState createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends ConsumerState<BookingCalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    // Connect socket on init
    final userId = ref.read(userIdProvider);
    if (userId != null) {
      ref.read(socketServiceProvider).connect(userId);
    }
  }

  @override
  void dispose() {
    ref.read(socketServiceProvider).disconnect();
    super.dispose();
  }

  List<Booking> _getBookingsForDay(DateTime day) {
    final bookingsState = ref.watch(bookingsProvider);
    return bookingsState.value?.where((booking) {
      return booking.startTime.year == day.year &&
          booking.startTime.month == day.month &&
          booking.startTime.day == day.day;
    }).toList() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final bookingsState = ref.watch(bookingsProvider);
    final socketState = ref.watch(socketConnectionStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Room Booking Calendar'),
        actions: [
          // Socket connection indicator
          socketState.when(
            data: (isConnected) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isConnected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    isConnected ? 'Live' : 'Offline',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            loading: () => SizedBox.shrink(),
            error: (_, __) => SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Booking>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getBookingsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return SizedBox.shrink();
                
                // Heatmap based on number of bookings
                final intensity = (events.length / 5).clamp(0.0, 1.0);
                return Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color.lerp(Colors.green, Colors.red, intensity),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: bookingsState.when(
              data: (bookings) {
                final dayBookings = _getBookingsForDay(_selectedDay);
                if (dayBookings.isEmpty) {
                  return Center(
                    child: Text('No bookings for this day'),
                  );
                }
                return ListView.builder(
                  itemCount: dayBookings.length,
                  itemBuilder: (context, index) {
                    final booking = dayBookings[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text('Room: ${booking.roomId}'),
                        subtitle: Text(
                          '${booking.startTime.hour}:${booking.startTime.minute.toString().padLeft(2, '0')} - '
                          '${booking.endTime.hour}:${booking.endTime.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: _buildStatusChip(booking.status),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewBookingDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    String label;

    switch (status) {
      case BookingStatus.confirmed:
        color = Colors.green;
        label = 'Confirmed';
        break;
      case BookingStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case BookingStatus.rejected:
        color = Colors.red;
        label = 'Rejected';
        break;
      case BookingStatus.waitlisted:
        color = Colors.blue;
        label = 'Waitlist';
        break;
      case BookingStatus.cancelled:
        color = Colors.grey;
        label = 'Cancelled';
        break;
    }

    return Chip(
      label: Text(label, style: TextStyle(color: Colors.white, fontSize: 10)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showNewBookingDialog(BuildContext context) {
    // Implement booking dialog with time picker
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Booking'),
        content: Text('Implement booking form here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Create booking via provider
              Navigator.pop(context);
            },
            child: Text('Book'),
          ),
        ],
      ),
    );
  }
}
