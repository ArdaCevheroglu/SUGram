import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/user_view_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _performSearch(query);
    } else {
      // Clear search results when search field is empty
      Provider.of<UserViewModel>(context, listen: false).clearSearchResults();
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      await Provider.of<UserViewModel>(context, listen: false).searchUsers(query);
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = Provider.of<UserViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for people...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      userViewModel.clearSearchResults();
                    },
                  )
                : null,
          ),
          style: const TextStyle(fontSize: 16.0),
        ),
      ),
      body: Column(
        children: [
          if (_isSearching)
            const LinearProgressIndicator()
          else if (_searchController.text.isNotEmpty && userViewModel.searchResults.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search_off,
                      size: 60.0,
                      color: AppTheme.secondaryTextColor,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'No users found for "${_searchController.text}"',
                      style: const TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_searchController.text.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search,
                      size: 60.0,
                      color: AppTheme.secondaryTextColor,
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Search for people by username or name',
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: userViewModel.searchResults.length,
                itemBuilder: (context, index) {
                  final UserModel user = userViewModel.searchResults[index];
                  return _buildUserListItem(user);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserListItem(UserModel user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[300],
        backgroundImage: user.profileImageUrl.isNotEmpty
            ? NetworkImage(user.profileImageUrl)
            : null,
        child: user.profileImageUrl.isEmpty
            ? const Icon(
                Icons.person,
                color: Colors.grey,
              )
            : null,
      ),
      title: Row(
        children: [
          Text(user.username),
          if (user.isVerified) ...[
            const SizedBox(width: 4.0),
            const Icon(
              Icons.verified,
              size: 16.0,
              color: AppTheme.primaryColor,
            ),
          ],
        ],
      ),
      subtitle: Text(user.fullName),
      onTap: () => _navigateToUserProfile(user.id),
    );
  }
}