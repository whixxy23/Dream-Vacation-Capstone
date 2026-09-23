import { render, screen } from '@testing-library/react';
import axios from 'axios';
import App from './App';

jest.mock('axios');

test('renders the heading and an empty state when there are no destinations', async () => {
  axios.get.mockResolvedValueOnce({ data: [] });
  render(<App />);

  expect(await screen.findByText(/Build your wishlist/i)).toBeInTheDocument();
  expect(await screen.findByText(/No destinations yet/i)).toBeInTheDocument();
});
