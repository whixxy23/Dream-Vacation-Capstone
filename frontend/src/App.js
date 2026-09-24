import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

const API_URL = process.env.REACT_APP_API_URL || '/api';

function App() {
  const [destinations, setDestinations] = useState([]);
  const [country, setCountry] = useState('');
  const [status, setStatus] = useState('loading'); // loading | ready | error
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState('');

  useEffect(() => {
    fetchDestinations();
  }, []);

  const fetchDestinations = async () => {
    try {
      const response = await axios.get(`${API_URL}/destinations`);
      setDestinations(response.data);
      setStatus('ready');
    } catch (error) {
      console.error('Error fetching destinations:', error);
      setStatus('error');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!country.trim()) return;

    setSubmitting(true);
    setFormError('');
    try {
      await axios.post(`${API_URL}/destinations`, { country });
      setCountry('');
      await fetchDestinations();
    } catch (error) {
      console.error('Error adding destination:', error);
      const message = error.response?.data?.error || 'Could not add that country. Please try again.';
      setFormError(message);
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (id) => {
    try {
      await axios.delete(`${API_URL}/destinations/${id}`);
      fetchDestinations();
    } catch (error) {
      console.error('Error deleting destination:', error);
    }
  };

  return (
    <div className="page">
      <header className="hero">
        <p className="eyebrow">Dream Vacations</p>
        <h1>Build your wishlist, one country at a time.</h1>
        <p className="subhead">
          Add any country and we&apos;ll pull its capital, population, and region for you.
        </p>
      </header>

      <main className="content">
        <form className="add-form" onSubmit={handleSubmit}>
          <input
            type="text"
            value={country}
            onChange={(e) => setCountry(e.target.value)}
            placeholder="e.g. Japan, Kenya, Brazil"
            aria-label="Country name"
            required
          />
          <button type="submit" disabled={submitting}>
            {submitting ? 'Adding…' : 'Add Destination'}
          </button>
        </form>
        {formError && <p className="form-error">{formError}</p>}

        {status === 'loading' && <p className="status">Loading your destinations…</p>}
        {status === 'error' && (
          <p className="status status--error">
            Couldn&apos;t reach the API. Is the backend running?
          </p>
        )}
        {status === 'ready' && destinations.length === 0 && (
          <p className="status">No destinations yet — add your first country above.</p>
        )}
        {status === 'ready' && destinations.length > 0 && (
          <ul className="grid">
            {destinations.map((dest) => (
              <li key={dest.id} className="card">
                <h2>{dest.country}</h2>
                <dl>
                  <div>
                    <dt>Capital</dt>
                    <dd>{dest.capital || '—'}</dd>
                  </div>
                  <div>
                    <dt>Population</dt>
                    <dd>{dest.population ? Number(dest.population).toLocaleString() : '—'}</dd>
                  </div>
                  <div>
                    <dt>Region</dt>
                    <dd>{dest.region || '—'}</dd>
                  </div>
                </dl>
                <button type="button" className="remove" onClick={() => handleDelete(dest.id)}>
                  Remove
                </button>
              </li>
            ))}
          </ul>
        )}
      </main>
    </div>
  );
}

export default App;
