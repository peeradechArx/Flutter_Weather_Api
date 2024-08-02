import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final String apiKey = dotenv.env['API_KEY'] ?? "";
  final TextEditingController _cityController = TextEditingController();
  List<String> _cities = [];
  Map<String, dynamic>? _weatherData;
  String? _errorMessage;

  Future<void> fetchWeather(String city) async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=th'));

      if (response.statusCode == 200) {
        setState(() {
          _weatherData = jsonDecode(response.body);
          _errorMessage = null;
        });
        // Navigate to the details screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeatherDetailsScreen(data: _weatherData!),
          ),
        );
      } else {
        setState(() {
          _weatherData = null;
          _errorMessage = 'Failed to load weather data for $city';
        });
      }
    } catch (e) {
      setState(() {
        _weatherData = null;
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _addCity() {
    final city = _cityController.text.trim();
    if (city.isNotEmpty && !_cities.contains(city)) {
      setState(() {
        _cities.add(city);
        _cityController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Enter city name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addCity,
                child: const Text('Add City'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    return ListTile(
                      title: Text(city),
                      onTap: () {
                        fetchWeather(city);
                      },
                    );
                  },
                ),
              ),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 18),
                )
              else
                const Text('643450082-4 พีระเดช โพธิ์หล้า'),
            ],
          ),
        ),
      ),
    );
  }
}

class WeatherDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const WeatherDetailsScreen({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final weather = data['weather'][0];
    final main = data['main'];
    final wind = data['wind'];
    final clouds = data['clouds'];
    final rain = data['rain'];
    final sys = data['sys'];

    final sunset = DateTime.fromMillisecondsSinceEpoch(sys['sunset'] * 1000);
    final sunsetTime =
        '${sunset.hour.toString().padLeft(2, '0')}:${sunset.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Weather Details - ${data['name']}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 20.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    'เมือง: ${data['name']}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Image.network(
                    'https://openweathermap.org/img/wn/${weather['icon']}@2x.png',
                    width: 100,
                    height: 100,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 10),
                WeatherDetailRow(
                  label: 'อากาศ',
                  value: '${weather['main']} (${weather['description']})',
                ),
                WeatherDetailRow(
                  label: 'อุณหภูมิ',
                  value: '${main['temp']}°C',
                ),
                WeatherDetailRow(
                  label: 'อุณหภูมิต่ำสุด',
                  value: '${main['temp_min']}°C',
                ),
                WeatherDetailRow(
                  label: 'อุณหภูมิสูงสุด',
                  value: '${main['temp_max']}°C',
                ),
                WeatherDetailRow(
                  label: 'ความชื้น',
                  value: '${main['humidity']}%',
                ),
                WeatherDetailRow(
                  label: 'ความกดอากาศ',
                  value: '${main['pressure']} hPa',
                ),
                WeatherDetailRow(
                  label: 'ระดับน้ำทะเล',
                  value: main.containsKey('sea_level')
                      ? '${main['sea_level']} hPa'
                      : 'N/A',
                ),
                WeatherDetailRow(
                  label: 'เเรงลม',
                  value: '${wind['speed']} m/s',
                ),
                WeatherDetailRow(
                  label: 'เมฆ',
                  value: '${clouds['all']}%',
                ),
                WeatherDetailRow(
                  label: 'ฝนใน 1 ชั่วโมงล่าสุด',
                  value: rain != null ? '${rain['1h']} mm' : 'ไม่มีฝน',
                ),
                WeatherDetailRow(
                  label: 'พระอาทิตย์ตก',
                  value: sunsetTime,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WeatherDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const WeatherDetailRow({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }
}
