import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_mobile/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:fe_mobile/features/community/presentation/viewmodels/feed_viewmodel.dart';
import 'package:fe_mobile/features/community/presentation/views/other_profile_screen.dart'; 
import 'package:fe_mobile/features/onboarding/presentation/views/subject_onboarding_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fe_mobile/features/community/presentation/widgets/post_card_widget.dart';
import 'package:fe_mobile/features/profile/presentation/widgets/study_heatmap_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Tải thống kê học tập khi màn hình Profile được mở
    Future.microtask(() {
      if (mounted) {
        context.read<ProfileViewModel>().fetchStudyStats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<ProfileViewModel>();
    final feedVM = context.watch<FeedViewModel>();
    const primaryColor = Color(0xFF52B794);
    
    final user = profileVM.user;
    final userName = user?['name'] ?? 'User';
    final userRole = user?['role'] ?? 'Student';
    final avatarUrl = user?['avatarUrl'];

    final points = user?['points'] ?? 0;
    final level = user?['level'] ?? 1;
    final xpInCurrentLevel = points % 100;
    final xpProgress = xpInCurrentLevel / 100.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: profileVM.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFFF3F4F6),
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _pickAndUploadImage(context, profileVM),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(userRole, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 16),
                
                // Gamification Points and Level Progress Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.stars_rounded, color: primaryColor, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  'Level $level',
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$points XP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: xpProgress,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Level Progress',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            '$xpInCurrentLevel / 100 XP',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Biểu đồ đóng góp tự học kiểu GitHub
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: profileVM.isStatsLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(color: primaryColor),
                          ),
                        )
                      : StudyHeatmapWidget(
                          dailyStats: profileVM.studyStats,
                          totalSessions: profileVM.totalSessions,
                          totalDurationMinutes: profileVM.totalDurationMinutes,
                        ),
                ),
                const SizedBox(height: 24),

                _buildMenuTile(
                  icon: Icons.article_outlined,
                  label: 'My Posts',
                  onTap: () => _navigateToPosts(context, 'My Posts', feedVM.myPosts),
                  iconColor: primaryColor,
                ),
                _buildMenuTile(
                  icon: Icons.favorite_border_rounded,
                  label: 'Favorites',
                  onTap: () => _navigateToPosts(context, 'Liked Posts', feedVM.likedPosts),
                  iconColor: primaryColor,
                ),
                _buildMenuTile(
                  icon: Icons.book_outlined,
                  label: 'Subject Onboarding',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubjectOnboardingView()),
                  ),
                  iconColor: primaryColor,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(height: 32, color: Color(0xFFEEEEEE)),
                ),
                _buildMenuTile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  onTap: () => profileVM.logout(), 
                  iconColor: Colors.red,
                  textColor: Colors.red,
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context, ProfileViewModel profileVM) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
        
        final bytes = await image.readAsBytes();
        await profileVM.updateAvatar(bytes, image.name);
        
        if (context.mounted) Navigator.pop(context); // Close loading dialog
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) Navigator.pop(context); // Close loading dialog
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color textColor = Colors.black87,
    Color iconColor = const Color(0xFF52B794),
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _navigateToPosts(BuildContext context, String title, List<PostModel> posts) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(title, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: const BackButton(color: Colors.black),
          ),
          body: posts.isEmpty 
            ? const Center(child: Text('No posts yet', style: TextStyle(color: Colors.grey, fontSize: 16)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, index) => PostCardWidget(post: posts[index]),
              ),
        ),
      ),
    );
  }
}
