
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const DormEaseApp());
}

class DormEaseApp extends StatelessWidget {
  const DormEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DormEase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5BCE),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      home: const DormEaseHome(),
    );
  }
}

class Dorm {
  final int id;
  String name;
  String location;
  double price;
  String description;
  String imageUrl;
  bool favorite;

  Dorm({
    required this.id,
    required this.name,
    required this.location,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.favorite = false,
  });
}

class DormEaseHome extends StatefulWidget {
  const DormEaseHome({super.key});

  @override
  State<DormEaseHome> createState() => _DormEaseHomeState();
}

class _DormEaseHomeState extends State<DormEaseHome> {
  int selectedIndex = 0;
  bool loading = false;
  String searchText = '';
  int nextId = 100;

  final List<Dorm> dorms = [
    Dorm(
      id: 1,
      name: 'Sunrise Student Dormitory',
      location: 'University Area',
      price: 3550,
      description:
          'Affordable student accommodation near schools, shops, and public transportation.',
      imageUrl:
          'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=1200',
    ),
    Dorm(
      id: 2,
      name: 'Mountain View Boarding House',
      location: 'Near Campus',
      price: 1800,
      description: 'A quiet and budget-friendly place for students.',
      imageUrl:
          'https://images.unsplash.com/photo-1510798831971-661eb04b3739?w=1200',
    ),
    Dorm(
      id: 3,
      name: 'Blue Haven Dormitory',
      location: 'Town Center',
      price: 2500,
      description:
          'Comfortable rooms close to restaurants and local transport.',
      imageUrl:
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200',
    ),
  ];

  final List<int> bookingIds = [];

  List<Dorm> get filteredDorms {
    final query = searchText.trim().toLowerCase();

    return dorms.where((dorm) {
      final matches =
          dorm.name.toLowerCase().contains(query) ||
          dorm.location.toLowerCase().contains(query);

      if (selectedIndex == 3) {
        return dorm.favorite && matches;
      }

      return matches;
    }).toList();
  }

  Future<void> refreshDemoData() async {
    setState(() => loading = true);

    try {
      final response = await http
          .get(
            Uri.parse(
              'https://jsonplaceholder.typicode.com/posts?_limit=3',
            ),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> posts = jsonDecode(response.body);

        if (mounted && posts.isNotEmpty) {
          setState(() {
            for (final post in posts) {
              final id = nextId++;

              dorms.add(
                Dorm(
                  id: id,
                  name:
                      '${post['title'].toString().split(' ').take(3).join(' ')} Dormitory',
                  location: 'Near Campus',
                  price: 1800 + (id % 5) * 350,
                  description: post['body'].toString(),
                  imageUrl:
                      'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=1200',
                ),
              );
            }
          });
        }
      }
    } catch (_) {
      // Existing sample listings remain available offline.
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> openDormForm({Dorm? dorm}) async {
    final formKey = GlobalKey<FormState>();
    final nameController =
        TextEditingController(text: dorm?.name ?? '');
    final locationController =
        TextEditingController(text: dorm?.location ?? '');
    final priceController = TextEditingController(
      text: dorm == null ? '' : dorm.price.toStringAsFixed(0),
    );
    final descriptionController =
        TextEditingController(text: dorm?.description ?? '');
    final imageController =
        TextEditingController(text: dorm?.imageUrl ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dorm == null ? 'Add Listing' : 'Edit Listing'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Dorm name'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter a dorm name'
                            : null,
                  ),
                  TextFormField(
                    controller: locationController,
                    decoration:
                        const InputDecoration(labelText: 'Location'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter a location'
                            : null,
                  ),
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monthly price (₱)',
                    ),
                    validator: (value) {
                      final price = double.tryParse(value ?? '');

                      return price == null || price <= 0
                          ? 'Enter a valid price'
                          : null;
                    },
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration:
                        const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  TextFormField(
                    controller: imageController,
                    decoration: const InputDecoration(
                      labelText: 'Image URL (optional)',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      setState(() {
        if (dorm == null) {
          dorms.insert(
            0,
            Dorm(
              id: nextId++,
              name: nameController.text.trim(),
              location: locationController.text.trim(),
              price: double.parse(priceController.text),
              description: descriptionController.text.trim(),
              imageUrl: imageController.text.trim().isEmpty
                  ? 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=1200'
                  : imageController.text.trim(),
            ),
          );
        } else {
          dorm!
            ..name = nameController.text.trim()
            ..location = locationController.text.trim()
            ..price = double.parse(priceController.text)
            ..description = descriptionController.text.trim()
            ..imageUrl = imageController.text.trim().isEmpty
                ? dorm.imageUrl
                : imageController.text.trim();
        }
      });
    }

    nameController.dispose();
    locationController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    imageController.dispose();
  }

  Future<void> deleteDorm(Dorm dorm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text('Remove "${dorm.name}" from DormEase?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        dorms.removeWhere((item) => item.id == dorm.id);
        bookingIds.remove(dorm.id);
      });
    }
  }

  void toggleFavorite(Dorm dorm) {
    setState(() {
      dorm.favorite = !dorm.favorite;
    });
  }

  void toggleBooking(Dorm dorm) {
    setState(() {
      if (bookingIds.contains(dorm.id)) {
        bookingIds.remove(dorm.id);
      } else {
        bookingIds.add(dorm.id);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          bookingIds.contains(dorm.id)
              ? 'Added to your bookings'
              : 'Removed from your bookings',
        ),
      ),
    );
  }

  void showDetails(Dorm dorm) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, sheetSetState) => Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    dorm.imageUrl,
                    height: 210,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 210,
                      color: Colors.blue.shade100,
                      child: const Center(
                        child: Icon(Icons.home, size: 60),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  dorm.name,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text('📍 ${dorm.location}'),
                const SizedBox(height: 6),
                Text(
                  '₱${dorm.price.toStringAsFixed(0)} / month',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  dorm.description.isEmpty
                      ? 'No description provided.'
                      : dorm.description,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      toggleBooking(dorm);
                      sheetSetState(() {});
                    },
                    icon: Icon(
                      bookingIds.contains(dorm.id)
                          ? Icons.event_busy
                          : Icons.calendar_month,
                    ),
                    label: Text(
                      bookingIds.contains(dorm.id)
                          ? 'Cancel Booking'
                          : 'Book This Dorm',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDormCard(Dorm dorm) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              InkWell(
                onTap: () => showDetails(dorm),
                child: Image.network(
                  dorm.imageUrl,
                  height: 175,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 175,
                    color: Colors.blue.shade100,
                    child: const Center(
                      child: Icon(Icons.home_work, size: 55),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    tooltip: 'Favorite',
                    onPressed: () => toggleFavorite(dorm),
                    icon: Icon(
                      dorm.favorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: dorm.favorite ? Colors.red : Colors.blue,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      openDormForm(dorm: dorm);
                    }
                    if (value == 'delete') {
                      deleteDorm(dorm);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit listing'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete listing'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => showDetails(dorm),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dorm.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '📍 ${dorm.location}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${dorm.price.toStringAsFixed(0)} / month',
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHomePage() {
    final items = filteredDorms;

    return RefreshIndicator(
      onRefresh: refreshDemoData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2456C8),
                  Color(0xFF6490F6),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR NEXT PLACE AWAITS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Find a place\nto feel at home.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Affordable stays for students',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) {
              setState(() => searchText = value);
            },
            decoration: InputDecoration(
              hintText: 'Search name or location...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recommended places',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: refreshDemoData,
                tooltip: 'Refresh sample listings',
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: Text(
                  'No dormitories found. Try another search.',
                ),
              ),
            ),
          ...items.map(buildDormCard),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget buildExplorePage() {
    final query = searchText.trim().toLowerCase();
    final results = dorms.where((dorm) {
      return dorm.name.toLowerCase().contains(query) ||
          dorm.location.toLowerCase().contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Explore Dormitories',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: (value) {
            setState(() => searchText = value);
          },
          decoration: InputDecoration(
            hintText: 'Search dorm or location',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (results.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No matching dormitories found.')),
          ),
        ...results.map(buildDormCard),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget buildBookingsPage() {
    final booked = dorms
        .where((dorm) => bookingIds.contains(dorm.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'My Bookings',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text('View and manage your dorm reservations.'),
        const SizedBox(height: 18),
        if (booked.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 60,
                    color: Colors.blue.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No bookings yet',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Explore dormitories and tap Book This Dorm '
                    'to add a reservation.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () {
                      setState(() => selectedIndex = 1);
                    },
                    child: const Text('Explore Dorms'),
                  ),
                ],
              ),
            ),
          ),
        ...booked.map(
          (dorm) => Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.bed),
              ),
              title: Text(dorm.name),
              subtitle: Text(
                '${dorm.location}\n'
                '₱${dorm.price.toStringAsFixed(0)} / month',
              ),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'Cancel booking',
                icon: const Icon(Icons.close),
                onPressed: () => toggleBooking(dorm),
              ),
              onTap: () => showDetails(dorm),
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget buildFavoritesPage() {
    final favorites = dorms.where((dorm) => dorm.favorite).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'My Favorites',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (favorites.isEmpty)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 60,
                  color: Colors.blue,
                ),
                SizedBox(height: 12),
                Text(
                  'No favorites yet. Tap the heart on a dorm you like.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ...favorites.map(buildDormCard),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget buildProfilePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 24),
        const CircleAvatar(
          radius: 48,
          backgroundColor: Color(0xFFDCE5FF),
          child: Icon(
            Icons.person,
            size: 55,
            color: Color(0xFF2D5BCE),
          ),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text(
            'DormEase User',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Center(
          child: Text('Find your next place to call home'),
        ),
        const SizedBox(height: 26),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.home_work_outlined),
                title: const Text('Available listings'),
                trailing: Text('${dorms.length}'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Favorite places'),
                trailing: Text(
                  '${dorms.where((dorm) => dorm.favorite).length}',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('My bookings'),
                trailing: Text('${bookingIds.length}'),
                onTap: () {
                  setState(() => selectedIndex = 2);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About DormEase'),
            subtitle: Text(
              'A student-focused dormitory finder demo app.',
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildHomePage(),
      buildExplorePage(),
      buildBookingsPage(),
      buildFavoritesPage(),
      buildProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(
              Icons.home_work,
              color: Color(0xFF2D5BCE),
            ),
            SizedBox(width: 8),
            Text(
              'DormEase',
              style: TextStyle(
                color: Color(0xFF2D5BCE),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF0F1F6),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: refreshDemoData,
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF2D5BCE),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      floatingActionButton:
          selectedIndex == 0 || selectedIndex == 1
              ? FloatingActionButton.extended(
                  onPressed: () => openDormForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Listing'),
                )
              : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
