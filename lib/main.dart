import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(CalendarApp());

class CalendarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final baseColor = Color(0xFF1565C0);

    return MaterialApp(
      title: 'Calendar Booking',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: baseColor,
          brightness: Brightness.light,
          primary: baseColor,
          onPrimary: Colors.white,
          secondary: Color(0xFF64B5F6),
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black87,
          background: Colors.grey[50]!,
          onBackground: Colors.black87,
          error: Colors.red.shade700,
          onError: Colors.white,
        ),
        useMaterial3: true,
        textTheme: TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
          bodySmall: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: baseColor,
            foregroundColor: Colors.white,
            minimumSize: Size(130, 38),
            padding: EdgeInsets.symmetric(horizontal: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: BookingPage(),
    );
  }
}

class BookingPage extends StatefulWidget {
  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  final String baseUrl = 'http://localhost:3000/bookings';
  List bookings = [];
  bool isLoading = false;
  bool isSubmitting = false;
  String? editingBookingId;

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  void fetchBookings() async {
    setState(() => isLoading = true);
    final res = await http.get(Uri.parse(baseUrl));
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List;
      data.sort((a, b) =>
          DateTime.parse(a['startTime']).compareTo(DateTime.parse(b['startTime'])));
      setState(() {
        bookings = data;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickDateTime(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    final localDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      controller.text = localDateTime.toIso8601String();
    });
  }

  void _editBooking(Map booking) {
    setState(() {
      editingBookingId = booking['id'];
      _userIdController.text = booking['userId'];
      _startTimeController.text = booking['startTime'];
      _endTimeController.text = booking['endTime'];
    });
  }

  void _deleteBooking(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete Booking"),
        content: Text("Are you sure you want to delete this booking?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete")),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await http.delete(Uri.parse('$baseUrl/$id'));

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🗑️ Booking deleted')));
      fetchBookings();
    } else {
      final error = json.decode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${error['error']}')));
    }
  }

  void submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final newStart = DateTime.tryParse(_startTimeController.text);
    final newEnd = DateTime.tryParse(_endTimeController.text);

    if (newStart == null || newEnd == null || newStart.isAfter(newEnd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⛔ Invalid or misordered date/time')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(editingBookingId != null ? "Confirm Update" : "Confirm Booking"),
        content: Text(editingBookingId != null
            ? "Update this booking?"
            : "Create this booking?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("Confirm")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isSubmitting = true);

    final url = editingBookingId != null
        ? '$baseUrl/$editingBookingId'
        : baseUrl;

    final method = editingBookingId != null ? 'PUT' : 'POST';

    final res = await http.Request(method, Uri.parse(url))
      ..headers['Content-Type'] = 'application/json'
      ..body = json.encode({
        'userId': _userIdController.text,
        'startTime': _startTimeController.text,
        'endTime': _endTimeController.text,
      });

    final streamed = await res.send();
    final response = await http.Response.fromStream(streamed);
    final data = json.decode(response.body);

    setState(() => isSubmitting = false);

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(editingBookingId != null ? '✅ Booking updated' : '✅ Booking created'),
      ));
      _userIdController.clear();
      _startTimeController.clear();
      _endTimeController.clear();
      editingBookingId = null;
      fetchBookings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${data['error']}')));
    }
  }

  String formatLocalTime(String iso) {
    final dt = DateTime.parse(iso);
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Widget bookingCard(Map booking) {
    final start = formatLocalTime(booking['startTime']);
    final end = formatLocalTime(booking['endTime']);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(Icons.event_note, color: Colors.white, size: 18),
        ),
        title: Text('User: ${booking['userId']}',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text('$start → $end',
            style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editBooking(booking),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteBooking(booking['id']),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  Widget bookingForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(editingBookingId != null ? "Edit Booking" : "Create a Booking",
              style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 20),
          TextFormField(
            controller: _userIdController,
            decoration: InputDecoration(labelText: 'User ID'),
            validator: (value) => value == null || value.isEmpty ? 'Please enter User ID' : null,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _startTimeController,
            decoration: InputDecoration(
              labelText: 'Start Time',
              helperText: 'Tap calendar icon to select date & time',
              suffixIcon: IconButton(
                icon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                onPressed: () => _pickDateTime(_startTimeController),
                tooltip: 'Pick Start Date & Time',
              ),
            ),
            readOnly: true,
            validator: (value) => value == null || value.isEmpty ? 'Please enter start time' : null,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _endTimeController,
            decoration: InputDecoration(
              labelText: 'End Time',
              helperText: 'Tap calendar icon to select date & time',
              suffixIcon: IconButton(
                icon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                onPressed: () => _pickDateTime(_endTimeController),
                tooltip: 'Pick End Date & Time',
              ),
            ),
            readOnly: true,
            validator: (value) => value == null || value.isEmpty ? 'Please enter end time' : null,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: isSubmitting ? null : submitBooking,
            icon: isSubmitting
                ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
                : Icon(Icons.send, size: 18),
            label: Text(editingBookingId != null ? 'Update Booking' : 'Create Booking'),
          ),
          SizedBox(height: 28),
          Divider(thickness: 1.2),
        ],
      ),
    );
  }

  Widget bookingList() {
    if (isLoading) {
      return Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 32),
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          ));
    }

    if (bookings.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 32),
        child: Center(
          child: Text(
            "📜 No bookings yet. Add one above ⬆️",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: bookings.length,
      itemBuilder: (_, i) => bookingCard(bookings[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📅 Calendar Booking System'),
        centerTitle: true,
        elevation: 6,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                bookingForm(),
                Text("All Bookings", style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 14),
                bookingList(),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
