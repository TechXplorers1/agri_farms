import 'package:flutter/material.dart';

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedPriority = 'Normal';

  // Mock History
  final List<Map<String, String>> _history = [
    {'title': 'Monsoon Warning', 'date': 'Jan 15', 'status': 'Sent'},
    {'title': 'New Subsidy Scheme', 'date': 'Jan 10', 'status': 'Sent'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Broadcast Alert'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Announcement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Heavy Rain Alert'
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                      hintText: 'Type your message here...'
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                    items: ['Normal', 'High', 'Critical'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => _selectedPriority = val!),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendBroadcast,
                      icon: const Icon(Icons.send),
                      label: const Text('Send to All Users'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedPriority == 'Critical' ? Colors.red : const Color(0xFF00AA55),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Recent Broadcasts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._history.map((item) => Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.campaign, color: Colors.white, size: 20)),
                title: Text(item['title']!),
                subtitle: Text(item['date']!),
                trailing: Chip(
                  label: Text(item['status']!, style: const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _sendBroadcast() {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() {
      _history.insert(0, {
        'title': _titleController.text,
        'date': 'Just Now',
        'status': 'Sent'
      });
      _titleController.clear();
      _messageController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Broadcast Sent Successfully!'),
      backgroundColor: Colors.green,
    ));
  }
}
