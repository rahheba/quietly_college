import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  final VoidCallback? onnavstd;
  
  const AdminHomeScreen({super.key, this.onnavstd});
  
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildStatsGrid(context, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Overview',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Monitor your school statistics in real-time',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, bool isMobile) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Total Classes Card
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('Classes').snapshots(),
          builder: (context, asyncSnapshot) {
            return _buildStatCard(
              ontap: () {
                if (onnavstd != null) onnavstd!();
              },
              title: 'Total Classes',
              value: (asyncSnapshot.data == null || asyncSnapshot.data!.docs.isEmpty)
                  ? '0'
                  : asyncSnapshot.data!.docs.length.toString(),
              icon: Icons.class_outlined,
              gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
              iconBgColor: Color(0xFF667eea).withOpacity(0.1),
            );
          },
        ),
        SizedBox(height: 8),
        
        // Total Students Card
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .where('role', isEqualTo: 'student')
              .where('status', isEqualTo: 1)
              .snapshots(),
          builder: (context, asyncSnapshot) {
            return _buildStatCard(
              ontap: () {
                if (onnavstd != null) onnavstd!();
              },
              title: 'Total Students',
              value: (asyncSnapshot.data == null || asyncSnapshot.data!.docs.isEmpty)
                  ? '0'
                  : asyncSnapshot.data!.docs.length.toString(),
              icon: Icons.school_outlined,
              gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
              iconBgColor: Color(0xFF4facfe).withOpacity(0.1),
            );
          },
        ),
        SizedBox(height: 8),
        
        // Total Teachers Card
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .where('role', isEqualTo: 'teacher')
              .where('status', isEqualTo: 1)
              .snapshots(),
          builder: (context, asyncSnapshot) {
            return _buildStatCard(
              ontap: () {},
              title: 'Total Teachers',
              value: (asyncSnapshot.data == null || asyncSnapshot.data!.docs.isEmpty)
                  ? '0'
                  : asyncSnapshot.data!.docs.length.toString(),
              icon: Icons.person_outline,
              gradientColors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
              iconBgColor: Color(0xFF43e97b).withOpacity(0.1),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
    required Color iconBgColor,
    required Function() ontap,
  }) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: gradientColors[0], size: 28),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                value,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: gradientColors,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Active',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}