import React from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useAuthState } from 'react-firebase-hooks/auth';
import { auth } from './lib/firebase';

function App() {
  const { t } = useTranslation();
  const [user, loading] = useAuthState(auth);

  if (loading) {
    return (
      <div className="min-h-screen bg-primary-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-4 border-primary-500 border-t-transparent"></div>
      </div>
    );
  }

  return (
    <Router>
      <div className="min-h-screen bg-primary-50 text-neutral-800" dir="rtl">
        <header className="bg-white shadow-sm">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
            <h1 className="text-3xl font-heading text-primary-500">
              {t('app.title')}
            </h1>
          </div>
        </header>
        <main>
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            {/* Authentication UI will be added here */}
          </div>
        </main>
      </div>
    </Router>
  );
}

export default App