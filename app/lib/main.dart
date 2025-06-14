import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'services/api_service.dart';
import 'services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await ApiService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeMyGuide',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = false;
  List<PlaceSuggestion> _suggestions = [];
  Position? _currentPosition;
  bool _hasRequestedLocation = false;

  void _handleSearch() async {
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _suggestions = [];
      });

      // Get location if we haven't already
      if (_currentPosition == null) {
        try {
          final position = await LocationService.getCurrentLocation();
          if (mounted) {
            setState(() {
              _currentPosition = position;
              _hasRequestedLocation = true;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _hasRequestedLocation = true;
              // Set default location to Interlaken, Switzerland as fallback
              _currentPosition = Position(
                latitude: 46.6863,
                longitude: 7.8632,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                altitudeAccuracy: 0,
                heading: 0,
                headingAccuracy: 0,
                speed: 0,
                speedAccuracy: 0,
              );
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location error: $e'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        }
      }

      // Now proceed with the search
      if (_currentPosition != null) {
        try {
          final suggestions = await ApiService.getRecommendations(
            query,
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
          setState(() {
            _suggestions = suggestions;
            _isLoading = false;
          });
        } catch (e) {
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshLocation() async {
    try {
      setState(() {
        _currentPosition = null;
      });

      final position = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _hasRequestedLocation = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasRequestedLocation = true;
          // Set default location to Interlaken, Switzerland as fallback
          _currentPosition = Position(
            latitude: 46.6863,
            longitude: 7.8632,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location error: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        toolbarHeight: 56,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/icon.png', width: 24, height: 24),
        ),
        title: const Text(
          'BeMyGuide',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          if (_hasRequestedLocation && _currentPosition != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Your Location',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.my_location, size: 20),
            onPressed: _refreshLocation,
            tooltip: 'Get location',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Welcome message
            const Text(
              'Welcome to BeMyGuide!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your AI-powered local guide. Ask me anything about nearby attractions, restaurants, or activities.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),

            // Search input section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onSubmitted: (_) => _handleSearch(),
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'What would you like to explore?',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.teal[300],
                        size: 22,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    maxLines: null,
                    textInputAction: TextInputAction.search,
                  ),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    'Search',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Place Suggestions section
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Found ${_suggestions.length} suggestions near you:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              ...(_suggestions
                  .map((suggestion) => _buildSuggestionCard(suggestion))
                  .toList()),
            ],

            const SizedBox(height: 24),

            // Example queries
            Text(
              'Try asking:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            _buildExampleChip('Find nearby restaurants that serve vegan food'),
            const SizedBox(height: 10),
            _buildExampleChip(
              'What attractions are close to Eiffel Tower that I can reach by foot?',
            ),
            const SizedBox(height: 10),
            _buildExampleChip(
              'Show me fun activities for a family with 10 year old kids',
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.code, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Open Source •',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openGitHubLink,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.code_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'github.com/kmjayadeep',
                      style: TextStyle(
                        color: Colors.teal[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(PlaceSuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(suggestion.category),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  suggestion.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              if (suggestion.distanceKm != null) ...[
                Icon(Icons.directions_walk, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${suggestion.distanceKm!.toStringAsFixed(1)} km away',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            suggestion.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            suggestion.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Google Maps button
              GestureDetector(
                onTap: () => _openGoogleMaps(suggestion.googleMapsUrl),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map, size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      const Text(
                        'Open in Maps',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
        return Colors.orange;
      case 'park':
        return Colors.green;
      case 'museum':
        return Colors.purple;
      case 'activity':
        return Colors.blue;
      case 'landmark':
        return Colors.red;
      case 'shopping':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openGoogleMaps(String googleMapsUrl) async {
    try {
      final uri = Uri.parse(googleMapsUrl);
      final canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot open Google Maps: $googleMapsUrl'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Google Maps: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Widget _buildExampleChip(String text) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _searchFocusNode.requestFocus();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.teal[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.teal[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 16, color: Colors.teal[600]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.teal[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGitHubLink() async {
    const url = 'https://github.com/kmjayadeep/bemyguide';

    try {
      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open GitHub link'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening GitHub: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
