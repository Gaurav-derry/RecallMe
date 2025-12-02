import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../data/models/memory.dart';
import '../../data/models/person.dart';
import '../../providers/app_provider.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'People', 'Places', 'Special'];
  List<Memory> _memories = [];
  List<Person> _people = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    final appProvider = context.read<AppProvider>();
    final memories = await appProvider.memoryRepository.getAllMemories();
    final people = await appProvider.personRepository.getAllPersons();
    if (mounted) {
      setState(() {
        _memories = memories;
        _people = people;
        _isLoading = false;
      });
    }
  }

  List<Memory> get _filteredMemories {
    var filtered = _memories;
    
    // Filter by category
    if (_selectedFilter != 'All') {
      filtered = filtered.where((m) => m.category == _selectedFilter).toList();
    }
    
    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((m) =>
        m.name.toLowerCase().contains(query) ||
        m.personName.toLowerCase().contains(query) ||
        m.memoryWord.toLowerCase().contains(query)
      ).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildFilters(),
              _buildPeopleSection(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadMemories,
                        child: _buildMemoriesGrid(),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addMemory).then((_) => _loadMemories()),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Add Memory', style: TextStyle(fontWeight: FontWeight.w700)),
      ).animate().fadeIn().slideY(begin: 0.5),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.cardShadow,
            ),
            child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Memories',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_memories.length} memories saved',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showTimeline(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.tealGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.timeline_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Timeline', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  void _showTimeline() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MemoryTimelineSheet(memories: _memories, onRefresh: _loadMemories),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow,
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search memories...',
            hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textLight, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) => setState(() {}),
        ),
      ),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: -0.1);
  }

  Widget _buildFilters() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.softShadow,
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1);
        },
      ),
    );
  }

  Widget _buildPeopleSection() {
    if (_people.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '👥 Your People',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_people.length} saved',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _people.length,
              itemBuilder: (context, index) {
                final person = _people[index];
                return GestureDetector(
                  onTap: () => _showPersonDetail(person),
                  child: Container(
                    width: 72,
                    margin: const EdgeInsets.only(right: 10),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.purpleGradient,
                            boxShadow: AppColors.softShadow,
                            image: person.imagePaths.isNotEmpty
                                ? DecorationImage(
                                    image: FileImage(File(person.imagePaths.first)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: person.imagePaths.isEmpty
                              ? const Icon(Icons.person, color: Colors.white, size: 26)
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          person.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          person.relation,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: (index * 60).ms).fadeIn().slideX(begin: 0.2);
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showPersonDetail(Person person) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PersonDetailSheet(
        person: person,
        onSpeak: () {
          final appProvider = context.read<AppProvider>();
          final notes = person.notes.isNotEmpty ? person.notes : 'They are someone special to you.';
          appProvider.ttsService.speak('This is ${person.name}, your ${person.relation}. $notes');
        },
        onImageTap: (imagePath, index, total) =>
            _showFullScreenPersonImage(person.name, imagePath, index, total),
      ),
    );
  }

  void _showFullScreenPersonImage(
    String personName,
    String imagePath,
    int index,
    int total,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenPersonImageView(
          title: personName,
          imagePath: imagePath,
          subtitle: 'Photo $index of $total',
        ),
      ),
    );
  }

  Widget _buildMemoriesGrid() {
    final memories = _filteredMemories;
    final hasPeople = _people.isNotEmpty;
    
    if (memories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_camera_rounded, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              _memories.isEmpty
                  ? 'No memories yet'
                  : (hasPeople ? 'No photo memories match' : 'No matching memories'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            if (hasPeople)
              const Text(
                'You have saved people above. You can use them as memories too.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              )
            else
              const Text(
                'Start capturing your special moments',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        final memory = memories[index];
        return _MemoryCard(
          memory: memory,
          onTap: () => _showMemoryDetail(memory),
          onDelete: () => _deleteMemory(memory),
        ).animate(delay: (index * 80).ms).fadeIn().scale(begin: const Offset(0.95, 0.95));
      },
    );
  }

  void _showMemoryDetail(Memory memory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MemoryDetailSheet(
        memory: memory,
        onDelete: () {
          Navigator.pop(context);
          _deleteMemory(memory);
        },
        onEdit: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, AppRoutes.addMemory, arguments: memory).then((_) => _loadMemories());
        },
      ),
    );
  }

  Future<void> _deleteMemory(Memory memory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Memory?'),
        content: Text('Are you sure you want to delete "${memory.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final appProvider = context.read<AppProvider>();
      await appProvider.memoryRepository.deleteMemory(memory.id);
      _loadMemories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memory deleted'), backgroundColor: AppColors.success),
        );
      }
    }
  }
}

class _MemoryCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MemoryCard({required this.memory, required this.onTap, required this.onDelete});

  LinearGradient get _gradient {
    switch (memory.category) {
      case 'People': return AppColors.purpleGradient;
      case 'Places': return AppColors.tealGradient;
      case 'Special': return AppColors.warmGradient;
      default: return AppColors.primaryGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _gradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  image: memory.imagePath != null
                      ? DecorationImage(image: FileImage(File(memory.imagePath!)), fit: BoxFit.cover)
                      : null,
                ),
                child: Stack(
                  children: [
                    if (memory.imagePath == null)
                      Center(
                        child: Icon(Icons.photo_rounded, size: 36, color: Colors.white.withOpacity(0.5)),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          memory.category,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      memory.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${memory.personName} • ${memory.year}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryDetailSheet extends StatelessWidget {
  final Memory memory;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _MemoryDetailSheet({required this.memory, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.read<AppProvider>();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppColors.textLight, borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: AppColors.warmGradient,
                      borderRadius: BorderRadius.circular(20),
                      image: memory.imagePath != null
                          ? DecorationImage(image: FileImage(File(memory.imagePath!)), fit: BoxFit.cover)
                          : null,
                    ),
                    child: memory.imagePath == null
                        ? const Center(child: Icon(Icons.photo_rounded, size: 56, color: Colors.white54))
                        : null,
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(memory.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  
                  // Info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(icon: Icons.calendar_today, label: memory.year.toString(), gradient: AppColors.primaryGradient),
                      _Chip(icon: Icons.person, label: memory.personName, gradient: AppColors.purpleGradient),
                      _Chip(icon: Icons.category, label: memory.category, gradient: AppColors.tealGradient),
                    ],
                  ),
                  
                  if (memory.memoryWord.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundTop,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Memory Word', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('"${memory.memoryWord}"', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  // Recall count
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const Icon(Icons.replay_rounded, color: AppColors.primaryBlue, size: 20),
                        const SizedBox(width: 10),
                        Text('Recalled ${memory.recallCount} times', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_rounded, size: 18, color: AppColors.error),
                          label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        appProvider.ttsService.speak('This is ${memory.name} from ${memory.year}. It features ${memory.personName}. ${memory.memoryWord}');
                      },
                      icon: const Icon(Icons.volume_up_rounded),
                      label: const Text('Tell me about this'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryTimelineSheet extends StatelessWidget {
  final List<Memory> memories;
  final VoidCallback onRefresh;

  const _MemoryTimelineSheet({required this.memories, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    // Group memories by date
    final grouped = <String, List<Memory>>{};
    for (final memory in memories) {
      final dateKey = DateFormat('MMMM d, yyyy').format(memory.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(memory);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppColors.textLight, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.backgroundTop, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(gradient: AppColors.tealGradient, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.timeline_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Memory Timeline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Expanded(
            child: memories.isEmpty
                ? const Center(child: Text('No memories to display', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final dayMemories = grouped[date]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(date, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryBlue)),
                          ),
                          ...dayMemories.map((memory) => _TimelineMemoryCard(memory: memory)),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TimelineMemoryCard extends StatelessWidget {
  final Memory memory;

  const _TimelineMemoryCard({required this.memory});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundTop,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.warmGradient,
              borderRadius: BorderRadius.circular(12),
              image: memory.imagePath != null
                  ? DecorationImage(image: FileImage(File(memory.imagePath!)), fit: BoxFit.cover)
                  : null,
            ),
            child: memory.imagePath == null
                ? const Icon(Icons.photo, color: Colors.white54, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(memory.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('${memory.personName} • ${memory.year}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(memory.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;

  const _Chip({required this.icon, required this.label, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }
}

class _PersonDetailSheet extends StatelessWidget {
  final Person person;
  final VoidCallback onSpeak;
  final void Function(String imagePath, int index, int total)? onImageTap;

  const _PersonDetailSheet({
    required this.person,
    required this.onSpeak,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.textLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.purpleGradient,
                          image: person.imagePaths.isNotEmpty
                              ? DecorationImage(
                                  image: FileImage(File(person.imagePaths.first)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: person.imagePaths.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 35)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: AppColors.purpleGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                person.relation,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (person.imagePaths.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.photo_library_rounded, size: 20, color: AppColors.primaryBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Photos (${person.imagePaths.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: person.imagePaths.length,
                        itemBuilder: (context, index) {
                          final imagePath = person.imagePaths[index];
                          return GestureDetector(
                            onTap: onImageTap == null
                                ? null
                                : () => onImageTap!(imagePath, index + 1, person.imagePaths.length),
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppColors.softShadow,
                                image: DecorationImage(
                                  image: FileImage(File(imagePath)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${index + 1}/${person.imagePaths.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (person.notes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Icon(Icons.notes_rounded, size: 20, color: AppColors.primaryOrange),
                        SizedBox(width: 8),
                        Text(
                          'About',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundTop,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        person.notes,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onSpeak,
                          icon: const Icon(Icons.volume_up_rounded),
                          label: const Text('Tell Me'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppColors.primaryOrange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.editPerson, arguments: person),
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenPersonImageView extends StatelessWidget {
  final String title;
  final String imagePath;
  final String subtitle;

  const _FullScreenPersonImageView({
    required this.title,
    required this.imagePath,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pinch to zoom',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

