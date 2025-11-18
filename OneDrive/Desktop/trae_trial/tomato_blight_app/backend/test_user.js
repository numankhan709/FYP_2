const axios = require('axios');

async function testLogin() {
  try {
    // Test login with existing user
    console.log('Testing login...');
    const loginResponse = await axios.post('http://localhost:3000/api/auth/login', {
      email: 'test@example.com',
      password: 'Password123'
    }, {
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Login test successful!');
    console.log('Login Response:', loginResponse.data);
    
    // Test token validation
    if (loginResponse.data.token) {
      console.log('\nTesting token validation...');
      const validateResponse = await axios.get('http://localhost:3000/api/auth/profile', {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${loginResponse.data.token}`
        }
      });
      
      console.log('✅ Token validation successful!');
      console.log('Profile Response:', validateResponse.data);
    }
    
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

testLogin();