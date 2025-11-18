const axios = require('axios');

async function testFrontendLogin() {
  try {
    console.log('Testing frontend login flow...');
    
    // Test the exact same endpoint the Flutter app uses
    const loginResponse = await axios.post('http://localhost:3000/api/auth/login', {
      email: 'test@example.com',
      password: 'Password123'
    }, {
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Login successful!');
    console.log('Response:', loginResponse.data);
    
    // Test the /auth/me endpoint that Flutter app calls
    if (loginResponse.data.token) {
      console.log('\nTesting /auth/me endpoint...');
      const meResponse = await axios.get('http://localhost:3000/api/auth/me', {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${loginResponse.data.token}`
        }
      });
      
      console.log('✅ /auth/me endpoint working!');
      console.log('User data:', meResponse.data);
    }
    
    console.log('\n🎉 All frontend API endpoints are working correctly!');
    
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Headers:', error.response.headers);
    }
  }
}

testFrontendLogin();