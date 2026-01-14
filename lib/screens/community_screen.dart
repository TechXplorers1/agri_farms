import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<String> _categories = ['All', 'Crops', 'Livestock', 'Machinery', 'Diseases', 'Market'];
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Custom Header (Matching Home Screen Style)
            Container(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30),
              decoration: const BoxDecoration(
                color: Color(0xFF66BB6A), // Lighter Green, consistent with Home
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Community Forum',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {}, 
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ask questions, share knowledge, and grow together.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 25),
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search interesting topics...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ],
              ),
            ),

            // Categories
            Container(
              margin: const EdgeInsets.only(top: 20),
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      decoration: BoxDecoration(
                        gradient: isSelected 
                            ? const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF43A047)])
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: isSelected ? null : Border.all(color: Colors.grey[300]!),
                        boxShadow: isSelected 
                            ? [BoxShadow(color: const Color(0xFF66BB6A).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          _categories[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Recent Discussions Label
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Discussions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {}, 
                    child: const Text('View All', style: TextStyle(color: Color(0xFF00AA55))),
                  ),
                ],
              ),
            ),

            // Questions List
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const NeverScrollableScrollPhysics(), // Scroll managed by SingleChildScrollView
              shrinkWrap: true,
              children: [
                _buildQuestionCard(
                  user: 'Ram Kumar',
                  role: 'Farmer',
                  time: '2h ago',
                  title: 'How to treat leaf curl in tomato?',
                  description: 'My tomato plants are showing upward curling of leaves. I have tried neem oil but no effect. Please suggest effective medicine.',
                  likes: 24,
                  comments: 12,
                  tag: 'Diseases',
                  tagColor: Colors.red,
                  tagBg: Colors.red[50]!,
                  hasImage: true,
                ),
                _buildQuestionCard(
                  user: 'Suresh Patel',
                  role: 'Expert',
                  time: '4h ago',
                  title: 'Best time for wheat sowing in Punjab?',
                  description: 'I want to sow wheat this season. What is the ideal temperature and date for maximum yield?',
                  likes: 45,
                  comments: 8,
                  tag: 'Crops',
                  tagColor: Colors.green,
                  tagBg: Colors.green[50]!,
                ),
                _buildQuestionCard(
                  user: 'Anita Singh',
                  role: 'Farmer',
                  time: '1d ago',
                  title: 'Cow not eating properly',
                  description: 'My Jersey cow has reduced feed intake since yesterday and milk production is also down. No fever detected.',
                  likes: 18,
                  comments: 5,
                  tag: 'Livestock',
                  tagColor: Colors.orange,
                  tagBg: Colors.orange[50]!,
                ),
                 _buildQuestionCard(
                  user: 'Raju Farming',
                  role: 'Dealer',
                  time: '2d ago',
                  title: 'Second hand tractor price?',
                  description: 'Looking for a second hand Mahindra 575 DI in good condition. What should be the fair price for 2018 model?',
                  likes: 32,
                  comments: 15,
                  tag: 'Machinery',
                  tagColor: Colors.blue,
                  tagBg: Colors.blue[50]!,
                ),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF00AA55),
        elevation: 4,
        icon: const Icon(Icons.edit_outlined, color: Colors.white),
        label: const Text('Ask Question', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildQuestionCard({
    required String user,
    required String role,
    required String time,
    required String title,
    required String description,
    required int likes,
    required int comments,
    required String tag,
    required Color tagColor,
    required Color tagBg,
    bool hasImage = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey[100],
                      backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=11'), // Placeholder
                      onBackgroundImageError: (_, __) {}, // Handle error
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (role == 'Expert') ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, size: 16, color: Colors.blue),
                            ]
                          ],
                        ),
                        Text(
                          '$role • $time',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(color: tagColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 16),
                
                // Interaction Row
                Row(
                  children: [
                    _buildInteractionButton(Icons.thumb_up_alt_outlined, likes.toString(), Colors.grey[600]!),
                    const SizedBox(width: 20),
                    _buildInteractionButton(Icons.chat_bubble_outline, comments.toString(), Colors.grey[600]!),
                    const Spacer(),
                    Icon(Icons.share_outlined, size: 22, color: Colors.grey[400]),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionButton(IconData icon, String count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          count,
          style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ],
    );
  }
}
