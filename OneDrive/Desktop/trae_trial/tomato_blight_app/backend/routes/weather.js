const express = require('express');
const axios = require('axios');
const { body, validationResult } = require('express-validator');
const router = express.Router();

// OpenWeather API configuration
const OPENWEATHER_API_KEY = process.env.OPENWEATHER_API_KEY;
const OPENWEATHER_BASE_URL = 'https://api.openweathermap.org/data/2.5';

// Disease risk assessment logic (Python model integration with heuristic fallback)
const calculateDiseaseRisk = async (temperature, humidity, extras = {}) => {
  try {
    const { spawn } = require('child_process');
    const path = require('path');
    const scriptPath = path.join(__dirname, '..', 'utils', 'weather_risk_model.py');
    const python = spawn('python', [scriptPath]);
    const payload = JSON.stringify({
      temperature,
      humidity,
      rain: extras.rain || 0,
      wind_speed: extras.windSpeed || 0,
      cloudiness: extras.cloudiness || 0,
    });
    python.stdin.write(payload);
    python.stdin.end();
    let out = '';
    let err = '';
    python.stdout.on('data', d => (out += d.toString()));
    python.stderr.on('data', d => (err += d.toString()));
    const result = await new Promise((resolve) => {
      let resolved = false;
      python.on('error', () => {
        if (!resolved) {
          resolved = true;
          resolve({ success: false, error: 'spawn_error' });
        }
      });
      python.on('close', () => {
        try {
          resolve(JSON.parse(out.trim()));
        } catch (e) {
          resolve({ success: false, error: 'parse_error' });
        }
      });
    });
    if (result && result.success) {
      const level = result.risk_level || 'Low';
      const description = level === 'High'
        ? 'Weather conditions are highly favorable for disease development.'
        : level === 'Medium'
          ? 'Moderate conditions may support some disease development. Monitor plants closely.'
          : 'Conditions are not favorable for disease development.';
      return {
        risk_level: level,
        temperature,
        humidity,
        description,
        source: result.source || 'model'
      };
    }
  } catch (e) {
    // fall through to heuristic below
  }
  let riskLevel = 'Low';
  let description = 'Conditions are not favorable for disease development.';
  if (humidity > 70 && temperature >= 15 && temperature <= 30) {
    riskLevel = 'High';
    description = 'High humidity and moderate temperatures create ideal conditions for fungal diseases like blight.';
  } else if ((humidity >= 50 && humidity <= 70) || (temperature >= 10 && temperature < 15) || (temperature > 30 && temperature <= 35)) {
    riskLevel = 'Medium';
    description = 'Moderate conditions may support some disease development. Monitor plants closely.';
  }
  return {
    risk_level: riskLevel,
    temperature,
    humidity,
    description,
    source: 'heuristic'
  };
};

// Validation rules
const locationValidation = [
  body('latitude')
    .isFloat({ min: -90, max: 90 })
    .withMessage('Latitude must be between -90 and 90'),
  body('longitude')
    .isFloat({ min: -180, max: 180 })
    .withMessage('Longitude must be between -180 and 180')
];

// @route   POST /api/weather/current
// @desc    Get current weather data by coordinates
// @access  Public
router.post('/current', locationValidation, async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Invalid coordinates',
        errors: errors.array()
      });
    }

    const { latitude, longitude } = req.body;

    if (!OPENWEATHER_API_KEY) {
      return res.status(500).json({
        success: false,
        message: 'Weather service not configured. Please contact administrator.'
      });
    }

    // Fetch current weather data
    const weatherResponse = await axios.get(
      `${OPENWEATHER_BASE_URL}/weather`,
      {
        params: {
          lat: latitude,
          lon: longitude,
          appid: OPENWEATHER_API_KEY,
          units: 'metric'
        }
      }
    );

    const weatherData = weatherResponse.data;

    // Extract relevant weather information
    const currentWeather = {
      temperature: Math.round(weatherData.main.temp),
      feelsLike: Math.round(weatherData.main.feels_like),
      humidity: weatherData.main.humidity,
      pressure: weatherData.main.pressure,
      visibility: weatherData.visibility ? Math.round(weatherData.visibility / 1000) : null,
      description: weatherData.weather[0].description,
      icon: weatherData.weather[0].icon,
      windSpeed: weatherData.wind?.speed || null,
      cloudiness: weatherData.clouds?.all || null,
      location: {
        name: weatherData.name,
        country: weatherData.sys.country,
        coordinates: {
          latitude: weatherData.coord.lat,
          longitude: weatherData.coord.lon
        }
      },
      timestamp: new Date().toISOString()
    };

    // Calculate disease risk assessment
    const riskAssessment = await calculateDiseaseRisk(
      currentWeather.temperature,
      currentWeather.humidity,
      {
        windSpeed: currentWeather.windSpeed || 0,
        cloudiness: currentWeather.cloudiness || 0,
        rain: (weatherData.rain && weatherData.rain['1h']) ? weatherData.rain['1h'] : 0,
      }
    );

    res.json({
      success: true,
      weather: currentWeather,
      riskAssessment
    });
  } catch (error) {
    console.error('Weather API error:', error.response?.data || error.message);
    
    if (error.response?.status === 401) {
      return res.status(500).json({
        success: false,
        message: 'Weather service authentication failed'
      });
    }
    
    if (error.response?.status === 404) {
      return res.status(404).json({
        success: false,
        message: 'Location not found'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Failed to fetch weather data'
    });
  }
});

// @route   POST /api/weather/forecast
// @desc    Get 5-day weather forecast
// @access  Public
router.post('/forecast', locationValidation, async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Invalid coordinates',
        errors: errors.array()
      });
    }

    const { latitude, longitude } = req.body;

    if (!OPENWEATHER_API_KEY) {
      return res.status(500).json({
        success: false,
        message: 'Weather service not configured'
      });
    }

    // Fetch 5-day forecast
    const forecastResponse = await axios.get(
      `${OPENWEATHER_BASE_URL}/forecast`,
      {
        params: {
          lat: latitude,
          lon: longitude,
          appid: OPENWEATHER_API_KEY,
          units: 'metric'
        }
      }
    );

    const forecastData = forecastResponse.data;

    // Process forecast data (group by day) with async risk calculation
    const dailyForecasts = [];
    const processedDates = new Set();
    for (const item of forecastData.list) {
      const date = new Date(item.dt * 1000).toDateString();
      if (!processedDates.has(date) && dailyForecasts.length < 5) {
        processedDates.add(date);
        const riskAssessment = await calculateDiseaseRisk(
          Math.round(item.main.temp),
          item.main.humidity,
          {
            windSpeed: item.wind?.speed || 0,
            cloudiness: item.clouds?.all || 0,
            rain: (item.rain && item.rain['3h']) ? item.rain['3h'] : 0,
          }
        );
        dailyForecasts.push({
          date: date,
          temperature: {
            min: Math.round(item.main.temp_min),
            max: Math.round(item.main.temp_max),
            avg: Math.round(item.main.temp)
          },
          humidity: item.main.humidity,
          description: item.weather[0].description,
          icon: item.weather[0].icon,
          riskAssessment
        });
      }
    }

    res.json({
      success: true,
      location: {
        name: forecastData.city.name,
        country: forecastData.city.country
      },
      forecast: dailyForecasts
    });
  } catch (error) {
    console.error('Forecast API error:', error.response?.data || error.message);
    
    res.status(500).json({
      success: false,
      message: 'Failed to fetch weather forecast'
    });
  }
});

// @route   POST /api/weather/risk-assessment
// @desc    Calculate disease risk based on weather conditions
// @access  Public
router.post('/risk-assessment', [
  body('temperature')
    .isFloat({ min: -50, max: 60 })
    .withMessage('Temperature must be between -50 and 60 degrees Celsius'),
  body('humidity')
    .isFloat({ min: 0, max: 100 })
    .withMessage('Humidity must be between 0 and 100 percent')
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Invalid weather parameters',
        errors: errors.array()
      });
    }

    const { temperature, humidity, windSpeed = 0, cloudiness = 0, rain = 0 } = req.body;
    const riskAssessment = await calculateDiseaseRisk(temperature, humidity, { windSpeed, cloudiness, rain });

    res.json({
      success: true,
      riskAssessment
    });
  } catch (error) {
    console.error('Risk assessment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to calculate risk assessment'
    });
  }
});

module.exports = router;