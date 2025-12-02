import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../data/models/person.dart';
import '../../providers/app_provider.dart';
import '../../providers/person_provider.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  late PersonProvider _personProvider;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initProvider();
  }

  void _initProvider() {
    final appProvider = context.read<AppProvider>();
    _personProvider = PersonProvider(
      repository: appProvider.personRepository,
      faceRecognitionService: appProvider.faceRecognitionService,
    );
    _personProvider.loadPersons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _personProvider,
      child: Scaffold(
        backgroundColor: AppColors.backgroundBottom,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.mainGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                Expanded(
                  child: Consumer<PersonProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final filteredPersons = provider.searchByName(_searchQuery);

                      if (filteredPersons.isEmpty) {
                        if (_searchQuery.isNotEmpty) {
                          return _buildNoResultsState();
                        }
                        return _buildEmptyState();
                      }

                      return _buildPeopleList(filteredPersons);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Identify Person (Face Recognition)
            FloatingActionButton(
              heroTag: 'identify',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.whoIsThis),
              backgroundColor: AppColors.success,
              child: const Icon(Icons.face_retouching_natural, color: Colors.white),
            ).animate().scale(delay: 300.ms),
            const SizedBox(height: 12),
            // Add Person
            FloatingActionButton.extended(
              heroTag: 'add',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.addPerson).then((_) => setState(() {})),
              backgroundColor: AppColors.primaryBlue,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('Add Person', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ).animate().scale(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppColors.softShadow,
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'People',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Your family & friends',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow,
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search people...',
            hintStyle: const TextStyle(color: AppColors.textLight),
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textLight),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildPeopleList(List<Person> persons) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: persons.length,
      itemBuilder: (context, index) {
        final person = persons[index];
        return _PersonCard(
          person: person,
          onTap: () => _showPersonDetail(person),
        ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.1);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 60,
                color: AppColors.primaryBlue.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No People Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add family members and friends\nso I can help you remember them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No results for "$_searchQuery"',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showPersonDetail(Person person) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PersonDetailSheet(person: person),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Person person;
  final VoidCallback onTap;

  const _PersonCard({required this.person, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.backgroundTop,
                shape: BoxShape.circle,
                image: person.imagePaths.isNotEmpty
                    ? DecorationImage(
                        image: FileImage(File(person.imagePaths.first)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: person.imagePaths.isEmpty
                  ? const Icon(Icons.person, size: 32, color: AppColors.primaryBlue)
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      person.relation,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 28),
          ],
        ),
      ),
    );
  }
}

class _PersonDetailSheet extends StatelessWidget {
  final Person person;

  const _PersonDetailSheet({required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.textLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Profile Photo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.backgroundTop,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryBlue, width: 3),
              image: person.imagePaths.isNotEmpty
                  ? DecorationImage(
                      image: FileImage(File(person.imagePaths.first)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: person.imagePaths.isEmpty
                ? const Icon(Icons.person, size: 60, color: AppColors.primaryBlue)
                : null,
          ),
          
          const SizedBox(height: 20),
          
          // Name
          Text(
            person.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Relation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.bluePillGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              person.relation,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Notes
          if (person.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
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
            ),
          
          const Spacer(),
          
          // AI Explain Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Show AI explanation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'This is ${person.name}, your ${person.relation}. '
                        '${person.notes.isNotEmpty ? person.notes : "They are important to you."}',
                      ),
                      backgroundColor: AppColors.primaryBlue,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                },
                icon: const Icon(Icons.psychology_rounded),
                label: const Text('Explain who they are'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
