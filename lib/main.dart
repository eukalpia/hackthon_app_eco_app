import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await openDatabase(
    join(await getDatabasesPath(), 'eco_app.db'),
    onCreate: (db, version) {
      db.execute(
        'CREATE TABLE user(id INTEGER PRIMARY KEY, name TEXT, email TEXT, avatar TEXT, saplings INTEGER, points INTEGER)',
      );
      return db.execute(
        'CREATE TABLE trees(id INTEGER PRIMARY KEY, name TEXT, species TEXT, image TEXT, latitude REAL, longitude REAL, plantedDate TEXT)',
      );
    },
    version: 1,
  );
  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final Database database;

  const MyApp({Key? key, required this.database}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eco App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.green[50],
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.green[800]),
          bodyMedium: TextStyle(color: Colors.green[700]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: LoginScreen(database: database),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final Database database;

  const LoginScreen({Key? key, required this.database}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isRegistering = false;

  void _register() async {
    setState(() {
      _isRegistering = true;
    });

    final name = _nameController.text;
    final email = _emailController.text;

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      setState(() {
        _isRegistering = false;
      });
      return;
    }

    await widget.database.insert(
      'user',
      {
        'name': name,
        'email': email,
        'avatar': '',
        'saplings': 0,
        'points': 0
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    setState(() {
      _isRegistering = false;
    });

    if (mounted) {
      Navigator.of(this.context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainScreen(database: widget.database),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green[300]!, Colors.green[700]!],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco, size: 100, color: Colors.white)
                    .animate()
                    .fade(duration: 500.ms)
                    .scale(delay: 300.ms),
                  SizedBox(height: 30),
                  Text(
                    'Welcome to Eco App',
                    style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ).animate().fade(duration: 500.ms).slideY(begin: 0.3, end: 0),
                  SizedBox(height: 50),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ).animate().fade(delay: 300.ms).slideX(),
                  SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ).animate().fade(delay: 400.ms).slideX(),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isRegistering ? null : _register,
                    child: _isRegistering
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Register'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ).animate().fade(delay: 500.ms).scale(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Database database;

  const MainScreen({Key? key, required this.database}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      MapScreen(database: widget.database),
      CameraScreen(database: widget.database),
      ProfileScreen(database: widget.database),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            topLeft: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black38, spreadRadius: 0, blurRadius: 10),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
          child: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt),
                label: 'Add Tree',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.green[800],
            unselectedItemColor: Colors.green[400],
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  final Database database;

  const MapScreen({Key? key, required this.database}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Marker> _markers = [];

  // Turin Polytechnic University in Tashkent coordinates
  final LatLng _universityCenter = LatLng(41.338674, 69.334876);

  @override
  void initState() {
    super.initState();
    _loadTreeMarkers();
  }

  Future<void> _loadTreeMarkers() async {
    final List<Map<String, dynamic>> trees = await widget.database.query('trees');
    setState(() {
      _markers = trees.map((tree) {
        return Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(tree['latitude'], tree['longitude']),
          child: GestureDetector(
            onTap: () => _showTreeDetails(tree),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: FileImage(File(tree['image'])),
                ),
              ),
            ),
          ),
        );
      }).toList();
    });
  }

  void _showTreeDetails(Map<String, dynamic> tree) {
    showDialog(
      context: this.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tree['name']),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Image.file(File(tree['image']), height: 200, fit: BoxFit.cover),
                SizedBox(height: 10),
                Text('Species: ${tree['species']}'),
                Text('Planted: ${tree['plantedDate']}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tree Map'),
        elevation: 0,
        backgroundColor: Colors.green[600],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _universityCenter,
          initialZoom: 17.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final Database database;

  const CameraScreen({Key? key, required this.database}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _speciesController = TextEditingController();
  bool _isUploading = false;
  double? _latitude;
  double? _longitude;

  final double _centerLatitude = 41.338674;
  final double _centerLongitude = 69.334876;

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _image = photo;
      });
      _generateRandomLocation();
    }
  }

  void _generateRandomLocation() {
    final random = Random();
    
    final double metersToDegreesLat = 1 / 110574.0;
    final double metersToDegreesLon = 1 / (111320.0 * cos(_centerLatitude * pi / 180));

    final double distance = 20 + random.nextDouble() * 30;

    final double angle = random.nextDouble() * 2 * pi;

    final double latOffset = distance * metersToDegreesLat * cos(angle);
    final double lonOffset = distance * metersToDegreesLon * sin(angle);

    setState(() {
      _latitude = _centerLatitude + latOffset;
      _longitude = _centerLongitude + lonOffset;
    });
  }

  Future<void> _uploadTree() async {
    if (_image == null) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Please take a photo')),
      );
      return;
    }

    if (_nameController.text.isEmpty || _speciesController.text.isEmpty) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Location not available. Please try again.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final String name = _nameController.text;
      final String species = _speciesController.text;

      await widget.database.insert(
        'trees',
        {
          'name': name,
          'species': species,
          'image': _image!.path,
          'latitude': _latitude,
          'longitude': _longitude,
          'plantedDate': DateTime.now().toIso8601String(),
        },
      );

      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Tree added successfully!')),
      );

      setState(() {
        _image = null;
        _nameController.clear();
        _speciesController.clear();
        _latitude = null;
        _longitude = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Error adding tree: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Tree'),
        elevation: 0,
        backgroundColor: Colors.green[600],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _image == null
                  ? Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Icon(Icons.camera_alt, size: 50, color: Colors.grey[400]),
                    )
                  : Image.file(File(_image!.path), height: 200, fit: BoxFit.cover),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _takePicture,
                child: Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tree Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _speciesController,
                decoration: InputDecoration(
                  labelText: 'Tree Species',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Location:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                _latitude != null && _longitude != null
                    ? 'Latitude: ${_latitude!.toStringAsFixed(6)}, Longitude: ${_longitude!.toStringAsFixed(6)}'
                    : 'Location not available',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadTree,
                child: _isUploading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Add Tree'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final Database database;

  const ProfileScreen({Key? key, required this.database}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';
  String _avatar = '';
  int _saplings = 0;
  int _points = 0;
  List<Map<String, dynamic>> _trees = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTrees();
  }

  Future<void> _loadUserData() async {
    final List<Map<String, dynamic>> users = await widget.database.query('user');
    if (users.isNotEmpty) {
      setState(() {
        _name = users[0]['name'];
        _email = users[0]['email'];
        _avatar = users[0]['avatar'];
        _saplings = users[0]['saplings'];
        _points = users[0]['points'];
      });
    }
  }

  Future<void> _loadTrees() async {
    final List<Map<String, dynamic>> trees = await widget.database.query('trees');
    setState(() {
      _trees = trees;
      _saplings = trees.length;
      _points = trees.length * 10; // For example, 10 points per tree
    });
    await widget.database.update(
      'user',
      {'saplings': _saplings, 'points': _points},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatar = pickedFile.path;
      });
      await widget.database.update(
        'user',
        {'avatar': _avatar},
        where: 'id = ?',
        whereArgs: [1],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        elevation: 0,
        backgroundColor: Colors.green[600],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.green[100],
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _changeAvatar,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _avatar.isNotEmpty ? FileImage(File(_avatar)) : null,
                      child: _avatar.isEmpty ? Icon(Icons.person, size: 50) : null,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    _name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(_email, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('Trees', _saplings.toString(), Icons.nature),
                      _buildStatCard('Points', _points.toString(), Icons.star),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Trees',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _trees.length,
                    itemBuilder: (context, index) {
                      final tree = _trees[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.file(
                              File(tree['image']),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tree['name'],
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text('Species: ${tree['species']}'),
                                  Text('Planted: ${tree['plantedDate']}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slide();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.green[600]),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}