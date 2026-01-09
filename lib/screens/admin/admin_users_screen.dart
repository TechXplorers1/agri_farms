import 'package:flutter/material.dart';
import '../../utils/user_manager.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UserManager _userManager = UserManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: _userManager,
        builder: (context, _) {
          final users = _userManager.users;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                color: Colors.white,
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: user.isBlocked ? Colors.red[50] : Colors.green[50],
                            child: Icon(
                              user.isBlocked ? Icons.block : Icons.person, 
                              color: user.isBlocked ? Colors.red : Colors.green
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name, 
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 16,
                                    decoration: user.isBlocked ? TextDecoration.lineThrough : null,
                                    color: user.isBlocked ? Colors.grey : Colors.black87
                                  )
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.phone_android, size: 12, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(user.phone, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(user.role, style: TextStyle(fontSize: 10, color: Colors.grey[800], fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Status Switch / Toggle
                          Switch(
                            value: !user.isBlocked, 
                            activeColor: Colors.green,
                            onChanged: (val) {
                               _userManager.toggleUserBlockStatus(user.id);
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: Text(user.isBlocked ? 'User Unblocked' : 'User Blocked'),
                                   duration: const Duration(seconds: 1),
                                 )
                               );
                            }
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      
                      // Mock Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat('Total Orders', '${(index + 1) * 5}'), // Deterministic Mock
                          _buildStat('Joined', 'Jan 2025'),
                          _buildStat('Status', user.isBlocked ? 'Blocked' : 'Active', color: user.isBlocked ? Colors.red : Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color ?? Colors.black87)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}
