const axios = require('axios');

async function createTestUser() {
  try {
    console.log('Creating test user...');
    const signupResponse = await axios.post('http://localhost:3000/api/auth/signup', {
      name: 'Test User',
      email: 'test@example.com',
      password: 'Password123'
    }, {
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Test user created successfully!');
    console.log('Signup Response:', signupResponse.data);
    
  } catch (error) {
    if (error.response?.status === 400 && error.response?.data?.message?.includes('already exists')) {
      console.log('✅ Test user already exists!');
    } else {
      console.error('❌ Error creating test user:', error.response?.data || error.message);
    }
  }
}

createTestUser();