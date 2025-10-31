import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';

class LocationSelectionDialog extends StatefulWidget {
  const LocationSelectionDialog({super.key});

  @override
  State<LocationSelectionDialog> createState() => _LocationSelectionDialogState();
}

class _LocationSelectionDialogState extends State<LocationSelectionDialog> {
  final TextEditingController _cityController = TextEditingController();
  bool _isLoading = false;

  // Popular cities with their coordinates
  final List<Map<String, dynamic>> _popularCities = [
    {'name': 'London, UK', 'lat': 51.5074, 'lon': -0.1278},
    {'name': 'New York, USA', 'lat': 40.7128, 'lon': -74.0060},
    {'name': 'Tokyo, Japan', 'lat': 35.6762, 'lon': 139.6503},
    {'name': 'Paris, France', 'lat': 48.8566, 'lon': 2.3522},
    {'name': 'Sydney, Australia', 'lat': -33.8688, 'lon': 151.2093},
    {'name': 'Mumbai, India', 'lat': 19.0760, 'lon': 72.8777},
    {'name': 'Dubai, UAE', 'lat': 25.2048, 'lon': 55.2708},
    {'name': 'Singapore', 'lat': 1.3521, 'lon': 103.8198},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue),
          SizedBox(width: 8),
          Text('Select Location'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose your location to get accurate weather data:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Try GPS button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _tryGPS,
                icon: const Icon(Icons.gps_fixed),
                label: const Text('Try GPS Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            const Text(
              'Popular Cities:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // Popular cities list
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _popularCities.length,
                itemBuilder: (context, index) {
                  final city = _popularCities[index];
                  return ListTile(
                    leading: const Icon(Icons.location_city, size: 20),
                    title: Text(city['name']),
                    onTap: () => _selectCity(city),
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _tryGPS() async {
    setState(() => _isLoading = true);
    
    try {
      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
      final success = await weatherProvider.retryLocationServices();
      
      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Location detected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Could not detect location. Please enable GPS in device settings.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectCity(Map<String, dynamic> city) async {
    setState(() => _isLoading = true);
    
    try {
      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
      await weatherProvider.setManualLocation(
        city['lat'],
        city['lon'],
        city['name'],
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Location set to ${city['name']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error setting location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }
}